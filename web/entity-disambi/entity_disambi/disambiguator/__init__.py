# -*- coding: utf-8 -*-

from entity_disambi import cli


@cli.group(chain=True)
def disambiguator():
    pass


_disambiguators = {}


def get_disambiguator(name):
    return _disambiguators[name]


def register_disambiguator(cls):
    _disambiguators[cls.__name__] = cls


import ml
from entity_prior import EntityPriorDisambiguator
from prior_prob import PriorProbDisambiguator
