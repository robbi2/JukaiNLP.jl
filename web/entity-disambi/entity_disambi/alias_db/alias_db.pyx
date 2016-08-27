# -*- coding: utf-8 -*-

import dawg
import cPickle as pickle
from itertools import chain
from tempfile import NamedTemporaryFile


cdef class Alias:
    def __init__(self, unicode name, unicode title, float prior_prob):
        self.name = name
        self.title = title
        self.prior_prob = prior_prob

    def __repr__(self):
        return '<Alias %s->%s>' % (self.name.encode('utf-8'),
                                   self.title.encode('utf-8'))

    def __reduce__(self):
        return (
            self.__class__,
            (self.name, self.title, self.prior_prob)
        )


cdef class AliasDB:
    @staticmethod
    def load(in_file):
        obj = pickle.load(in_file)

        ret = AliasDB()
        ret._titles = obj['titles']

        # We need to use a file here since DAWG has an issue with pickle:
        # http://dawg.readthedocs.org/en/latest/#persistence
        with NamedTemporaryFile('wb') as f:
            f.write(obj['dawg'])
            f.flush()
            ret._dawg = dawg.RecordDAWG('<If')
            ret._dawg.load(f.name)

        return ret

    def save(self, out_file):
        pickle.dump(dict(
            dawg=self._dawg.tobytes(),
            titles=self._titles
        ), out_file, protocol=pickle.HIGHEST_PROTOCOL)

    def __len__(self):
        return len(self._dawg.keys())

    def __iter__(self):
        for (name, val) in self._dawg.iteritems():
            (index, prior_prob) = val
            yield Alias(name, self._titles[index], prior_prob)

    def __getitem__(self, unicode key):
        return sorted([
            Alias(key, self._titles[index], prior_prob)
            for (index, prior_prob) in self._dawg[key]
        ], key=lambda alias: alias.prior_prob, reverse=True)

    def __contains__(self, unicode key):
        return bool(key in self._dawg)
