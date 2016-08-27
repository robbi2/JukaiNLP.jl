# -*- coding: utf-8 -*-

# import uuid

_pos_tagger = None


cdef class Document:
    def __init__(self, id, list words, list mentions, str tag=None):
        self.id = id
        self.words = words
        self.mentions = mentions
        self.tag = tag

    property pos_tags:
        def __get__(self):
            global _pos_tagger
            if self._pos_tags:
                return self._pos_tags

            from entity_disambi.utils.opennlp import OpenNLPPOSTagger

            if _pos_tagger is None:
                _pos_tagger = OpenNLPPOSTagger()

            self._pos_tags = _pos_tagger.tag(self.words)
            self.words = [unicode(w) for w in self.words]

            return self._pos_tags

    def __repr__(self):
        return '<Document %s...>' % (u' '.join(self.words[:3]).encode('utf-8'))

    def __reduce__(self):
        return (self.__class__, (self.words, self.mentions, self.tag),
                dict(id=self.id))

    def __setstate__(self, state):
        self.id = state['id']


cdef class Mention:
    def __init__(self, int id, unicode text, unicode entity_title,
                 tuple span=None):
        self.id = id
        self.text = text
        self.entity_title = entity_title
        self.span = span

        self.candidates = []

    def __repr__(self):
        return '<Mention %s->%s>' % (self.text.encode('utf-8'),
                                     self.entity_title.encode('utf-8'))

    def __reduce__(self):
        return (self.__class__, (self.text, self.entity_title, self.span),
                dict(predicted_title=self.predicted_title,
                     candidates=self.candidates))

    def __setstate__(self, state):
        self.predicted_title = state['predicted_title']
        self.candidates = state['candidates']
