# -*- coding: utf-8 -*-

import click
import multiprocessing

from alias_db import Alias, AliasDB

from .. import cli


@cli.command()
@click.argument('dump_file', type=click.Path(exists=True))
@click.argument('out_file', type=click.File(mode='w'))
@click.argument('dictionary', type=click.File(mode='r'))
@click.option('--tokenize-title', is_flag=True)
@click.option('--parallel/--no-parallel', default=True)
@click.option('--pool-size', default=multiprocessing.cpu_count())
@click.option('--chunk-size', default=100)
def build_wikipedia_alias_db(dump_file, out_file, dictionary, **kwargs):
    from entity_vector.dictionary import Dictionary
    import wikipedia_alias_db_builder

    dictionary = Dictionary.load(dictionary)
    wikipedia_alias_db_builder.build(dump_file, out_file, dictionary, **kwargs)


@cli.command()
@click.argument('aida_means_file', type=click.Path(exists=True))
@click.argument('wiki_label_jsonl_file', type=click.File())
@click.argument('out_file', type=click.File(mode='w'))
def build_yago_alias_db(**kwargs):
    import yago_alias_db_builder

    yago_alias_db_builder.build(**kwargs)
