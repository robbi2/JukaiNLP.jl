# -*- coding: utf-8 -*-


class BaseCorpusReader(object):
    def __init__(self, corpus_dir, dictionary, alias_db):
        self.corpus_dir = corpus_dir
        self.dictionary = dictionary
        self.alias_db = alias_db


from aida import AIDACorpusReader
from aida_ppr import AIDAPPRCorpusReader
from tac_kbp_2010 import TACKBP2010CorpusReader


def get_corpus_reader(name):
    if name == 'aida':
        return AIDACorpusReader

    elif name == 'tac_kbp':
        return TACKBP2010CorpusReader

    elif name == 'aida_ppr':
        return AIDAPPRCorpusReader

    else:
        raise NotImplementedError()
