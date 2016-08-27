# -*- coding: utf-8 -*-

import click
import cPickle as pickle
import itertools
import numpy as np

from entity_vector import Dictionary, EntityVector

from entity_disambi.disambiguator import disambiguator
from entity_disambi.alias_db import AliasDB
from entity_disambi.corpus_reader import get_corpus_reader

from base_ml import BaseMLDisambiguator, TwoStepMLDisambiguator
from gbrt import GradientBoostingDisambiguator, TwoStepGradientBoostingDisambiguator
from random_forest import RandomForestDisambiguator, TwoStepRandomForestDisambiguator


@disambiguator.command()
@click.argument('corpus_dir', type=click.Path())
@click.argument('dictionary_file', type=click.File())
@click.argument('alias_db_file', type=click.File())
@click.argument('entity_vector_file', type=click.Path())
@click.argument('out_file', type=click.File(mode='w'))
@click.option('--corpus-type', default='aida')
@click.option('--corpus-tag', default='train')
def build_dataset(
    corpus_dir, dictionary_file, alias_db_file, entity_vector_file, out_file,
    corpus_type, corpus_tag
):
    click.echo('Loading alias db...')
    alias_db = AliasDB.load(alias_db_file)

    click.echo('Loading dictionary...')
    dictionary = Dictionary.load(dictionary_file)

    click.echo('Loading corpus...')
    corpus_reader_cls = get_corpus_reader(corpus_type)
    corpus_reader = corpus_reader_cls(corpus_dir, dictionary, alias_db)
    documents = corpus_reader.get_documents(tags=[corpus_tag])

    click.echo('Loading entity vector...')
    entity_vector = EntityVector.load(entity_vector_file)

    disambi = BaseMLDisambiguator(dictionary, alias_db, entity_vector)
    dataset = disambi.build_dataset(documents)

    pickle.dump(dataset, out_file, protocol=pickle.HIGHEST_PROTOCOL)


@disambiguator.command()
@click.argument('dataset_file', type=click.File())
@click.argument('model_file', type=click.File())
def ml_eval(dataset_file, model_file):
    dataset = pickle.load(dataset_file)
    model = pickle.load(model_file)

    ml_model = model['ml_model']
    if hasattr(ml_model, 'predict_proba'):
        scores = [o[1] for o in ml_model.predict_proba(dataset.feature_matrix)]
    else:
        scores = [o for o in ml_model.predict(dataset.feature_matrix)]
    labels = dataset.labels
    cur = 0
    correct = 0
    total = 0
    for (_, g) in itertools.groupby(dataset.groups):
        end = cur + len(list(g))
        group_probas = scores[cur:end]
        gs_labels = labels[cur:end]

        if gs_labels[np.argsort(group_probas)[-1]]:
            correct += 1

        cur = end
        total += 1

    click.echo('Precision (Micro): %.4f' % (float(correct) / total))


@disambiguator.command()
@click.argument('corpus_dir', type=click.Path(exists=True))
@click.argument('dictionary_file', type=click.File())
@click.argument('alias_db_file', type=click.File())
@click.argument('entity_vector_file', type=click.Path())
@click.argument('base_disambiguator_file', type=click.File())
@click.argument('out_file', type=click.File(mode='w'))
@click.option('--corpus-type', default='aida')
@click.option('--corpus-tag', default='train')
def build_two_step_dataset(
    corpus_dir, dictionary_file, alias_db_file, entity_vector_file,
    base_disambiguator_file, out_file, corpus_type, corpus_tag
):
    click.echo('Loading alias db...')
    alias_db = AliasDB.load(alias_db_file)

    click.echo('Loading dictionary...')
    dictionary = Dictionary.load(dictionary_file)

    click.echo('Loading corpus...')
    corpus_reader_cls = get_corpus_reader(corpus_type)
    corpus_reader = corpus_reader_cls(corpus_dir, dictionary, alias_db)
    documents = corpus_reader.get_documents(tags=[corpus_tag])

    click.echo('Loading entity vector...')
    entity_vector = EntityVector.load(entity_vector_file)

    click.echo('Loading disambiguator...')
    base_disambiguator_model = pickle.load(base_disambiguator_file)

    disambi = TwoStepMLDisambiguator(
        base_disambiguator_model, dictionary, alias_db, entity_vector
    )
    dataset = disambi.build_dataset(documents)

    pickle.dump(dataset, out_file, protocol=pickle.HIGHEST_PROTOCOL)


@disambiguator.command()
@click.argument('dataset_file', type=click.File())
@click.argument('out_file', type=click.File(mode='w'))
@click.option('--n-estimators', default=300)
@click.option('--min-samples-split', default=30)
@click.option('--max-features', default='auto')
def build_random_forest(dataset_file, out_file, **kwargs):
    if kwargs['max_features'] and kwargs['max_features'].isdigit():
        kwargs['max_features'] = int(kwargs['max_features'])
    dataset = pickle.load(dataset_file)
    model = RandomForestDisambiguator.build_model(dataset, **kwargs)

    pickle.dump(model, out_file, protocol=pickle.HIGHEST_PROTOCOL)


@disambiguator.command()
@click.argument('dataset_file', type=click.File())
@click.argument('out_file', type=click.File(mode='w'))
@click.option('--n-estimators', default=300)
@click.option('--min-samples-split', default=30)
@click.option('--max-features', default='auto')
def build_two_step_random_forest(dataset_file, out_file, **kwargs):
    if kwargs['max_features'] and kwargs['max_features'].isdigit():
        kwargs['max_features'] = int(kwargs['max_features'])
    dataset = pickle.load(dataset_file)
    model = TwoStepRandomForestDisambiguator.build_model(dataset, **kwargs)

    pickle.dump(model, out_file, protocol=pickle.HIGHEST_PROTOCOL)


@disambiguator.command()
@click.argument('dataset_file', type=click.File())
@click.argument('out_file', type=click.File(mode='w'))
@click.option('--n-estimators', default=10000)
@click.option('--learning-rate', default=0.01)
@click.option('--max-depth', default=3)
def build_gradient_boosting(dataset_file, out_file, **kwargs):
    dataset = pickle.load(dataset_file)
    model = GradientBoostingDisambiguator.build_model(dataset, **kwargs)

    pickle.dump(model, out_file, protocol=pickle.HIGHEST_PROTOCOL)


@disambiguator.command()
@click.argument('dataset_file', type=click.File())
@click.argument('out_file', type=click.File(mode='w'))
@click.option('--n-estimators', default=10000)
@click.option('--learning-rate', default=0.01)
@click.option('--max-depth', default=3)
def build_two_step_gradient_boosting(dataset_file, out_file, **kwargs):
    dataset = pickle.load(dataset_file)
    model = TwoStepGradientBoostingDisambiguator.build_model(dataset, **kwargs)

    pickle.dump(model, out_file, protocol=pickle.HIGHEST_PROTOCOL)
