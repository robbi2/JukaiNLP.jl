# -*- coding: utf-8 -*-

import numpy as np

from entity_vector.dictionary import Dictionary

from entity_disambi.alias_db.alias_db cimport Alias, AliasDB
from entity_disambi.models cimport Document, Mention


cdef class BaseDisambiguator:
    cdef _dictionary
    cdef AliasDB _alias_db
    cdef _entity_vector
    cdef public dict _cache

    def __init__(self, dictionary, AliasDB alias_db,
                 entity_vector=None):
        self._dictionary = dictionary
        self._alias_db = alias_db
        self._entity_vector = entity_vector

        self._cache = {}

    property alias_db:
        def __get__(self):
            return self._alias_db

    property dictionary:
        def __get__(self):
            return self._dictionary

    property entity_vector:
        def __get__(self):
            return self._entity_vector

    cpdef Alias disambiguate(self, Mention mention, Document document):
        self.get_aliases_with_scores(mention, document)[0][0]
