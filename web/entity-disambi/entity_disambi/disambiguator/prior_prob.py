# -*- coding: utf-8 -*-

from base import BaseDisambiguator
from . import register_disambiguator


class PriorProbDisambiguator(BaseDisambiguator):
    def __init__(self, *args, **kwargs):
        super(PriorProbDisambiguator, self).__init__(*args, **kwargs)

    def get_aliases_with_scores(self, mention, document):
        return sorted([
            (alias, alias.prior_prob) for alias in mention.candidates
        ], key=lambda o: o[1], reverse=True)


register_disambiguator(PriorProbDisambiguator)
