# -*- coding: utf-8 -*-

import click
import cPickle as pickle
import numpy as np
import sys
import time
from cStringIO import StringIO

from entity_vector import Dictionary, EntityVector

from entity_disambi.alias_db import AliasDB
from entity_disambi.corpus_reader import get_corpus_reader
from entity_disambi.disambiguator import get_disambiguator

from entity_disambi.utils import test_alias_correctness

from . import cli

_alias_db = None
_dictionary = None
_documents = None
_show_errors = None


@cli.group(chain=True)
@click.argument('corpus_dir', type=click.Path(exists=True))
@click.argument('dictionary_file', type=click.File())
@click.argument('alias_db_file', type=click.File())
@click.option('--corpus-type', default='aida')
@click.option('--corpus-tag', default='testb')
@click.option('--show-errors', is_flag=True)
def evaluation(corpus_dir, dictionary_file, alias_db_file, corpus_type,
               corpus_tag, show_errors):
    global _alias_db, _dictionary, _documents, _show_errors

    click.echo('Loading alias db...')
    _alias_db = AliasDB.load(alias_db_file)

    click.echo('Loading dictionary...')
    _dictionary = Dictionary.load(dictionary_file)

    click.echo('Loading corpus...')
    corpus_reader_cls = get_corpus_reader(corpus_type)
    corpus_reader = corpus_reader_cls(corpus_dir, _dictionary, _alias_db)
    _documents = corpus_reader.get_documents(tags=[corpus_tag])

    _show_errors = show_errors


@evaluation.command()
def show_candidate_recall():
    total_mentions = 0
    resolvable_mentions = 0

    for document in _documents:
        for mention in document.mentions:
            total_mentions += 1

            if any(
                test_alias_correctness(alias, mention, _dictionary)
                for alias in mention.candidates
            ):
                resolvable_mentions += 1
            else:
                click.echo('Entity not found: surface: %s, title: %s' %
                           (mention.text, mention.entity_title))

    click.echo('Candidate recall: %.3f' %
               (float(resolvable_mentions) / total_mentions))


@evaluation.command()
def prior_prob(**kwargs):
    disambiguator = get_disambiguator('PriorProbDisambiguator')(_dictionary, _alias_db, **kwargs)
    show_evaluation_results(disambiguator)


@evaluation.command()
def entity_prior(**kwargs):
    disambiguator = get_disambiguator('EntityPriorDisambiguator')(_dictionary, _alias_db, **kwargs)
    show_evaluation_results(disambiguator)


@evaluation.command()
@click.argument('model_file', type=click.File())
@click.argument('entity_vector_file', type=click.Path())
def ml(model_file, entity_vector_file):
    entity_vector = EntityVector.load(entity_vector_file)
    model = pickle.load(model_file)
    disambiguator = get_disambiguator(model['name'])(
        model, _dictionary, _alias_db, entity_vector
    )
    show_evaluation_results(disambiguator)


def show_evaluation_results(disambiguator):
    total_mentions = 0
    correct_mentions = 0
    doc_precisions = []

    if _show_errors:
        progress_file = StringIO()
    else:
        progress_file = sys.stdout

    start_time = time.time()
    with click.progressbar(_documents, file=progress_file,
                           show_pos=True) as bar:
        for document in bar:
            total_doc_mentions = 0
            correct_doc_mentions = 0
            if _show_errors:
                click.echo('Document: %s' % ' '.join(document.words))

            for mention in document.mentions:
                total_mentions += 1
                total_doc_mentions += 1

                alias_score_pairs = disambiguator.get_aliases_with_scores(
                    mention, document
                )
                if not alias_score_pairs:
                    continue

                predicted = alias_score_pairs[0][0]

                if test_alias_correctness(predicted, mention, _dictionary):
                    if _show_errors:
                        click.secho('Correct: ', fg='green', nl=False)
                        click.echo('Text: %s Predicted: %s' % (mention.text, predicted.title))

                    correct_mentions += 1
                    correct_doc_mentions += 1

                elif _show_errors:
                    click.secho('Wrong disambiguation: ', fg='red', nl=False)
                    click.echo(
                        'Text: %s Predicted: %s GS: %s' %
                        (mention.text, predicted.title, mention.entity_title)
                    )
                    click.echo('Score: %.3f' % alias_score_pairs[0][1])

                    found = False
                    for (alias, score) in alias_score_pairs:
                        if alias.title == mention.entity_title:
                            click.echo('GS Score: %.3f' % score)
                            found = True

                    if not found:
                        click.echo('GS Score: NULL')

            if total_doc_mentions:
                doc_precisions.append(float(correct_doc_mentions) / total_doc_mentions)

            else:
                doc_precisions.append(1.0)

    processing_time = time.time() - start_time
    click.echo('Processing time: %.3fs' % processing_time)
    click.echo('Average time per document: %.3fms' % (processing_time / len(_documents) * 1000,))
    click.echo('Correct mentions: %d' % correct_mentions)
    click.echo('Total mentions: %d' % total_mentions)
    click.echo('Precision (Micro): %.4f' % (float(correct_mentions) / total_mentions))
    click.echo('Precision (Macro): %.4f' % np.mean(doc_precisions))
