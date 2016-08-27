# -*- coding: utf-8 -*-

from base import BaseDisambiguator
from . import register_disambiguator


class EntityPriorDisambiguator(BaseDisambiguator):
    def __init__(self, *args, **kwargs):
        super(EntityPriorDisambiguator, self).__init__(*args, **kwargs)

    def get_aliases_with_scores(self, mention, document):
        scores = []

        for alias in mention.candidates:
            try:
                entity = self.dictionary.get_entity(alias.title)
                scores.append(entity.doc_count)

            except KeyError:
                scores.append(0)

        return sorted(zip(mention.candidates, scores), key=lambda o: o[1],
                      reverse=True)


register_disambiguator(EntityPriorDisambiguator)
