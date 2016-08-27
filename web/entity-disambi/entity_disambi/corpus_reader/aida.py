# -*- coding: utf-8 -*-

import os
import re

from entity_disambi.models import Document
from entity_disambi.models import Mention
from . import BaseCorpusReader

DATASET_FILE = 'AIDA-YAGO2-dataset.tsv'


class AIDACorpusReader(BaseCorpusReader):
    def __init__(self, corpus_dir, dictionary, alias_db, num_candidates=50):
        super(AIDACorpusReader, self).__init__(corpus_dir, dictionary, alias_db)
        self._num_candidates = num_candidates

    def get_documents(self, tags=None, filter_unlinkable=True,
                      filter_out_of_kb=True, generate_candidates=True):
        if tags:
            tags = frozenset(tags)

        documents = []
        n_mentions = 0
        for document in re.split(ur'-DOCSTART-\s', self._read_corpus())[1:]:
            (meta, document) = document.split('\n', 1)
            doc_id = int(re.match(r'\((\d+)', meta).group(1))
            if 'testa' in meta:
                tag = 'testa'
            elif 'testb' in meta:
                tag = 'testb'
            else:
                tag = 'train'

            if tags and (tag not in tags):
                continue

            words = []
            mentions = []

            begin = None
            mention_text = None
            entity_title = None
            for (n, line) in enumerate(document.split('\n')):
                items = line.split('\t')
                words.append(items[0])

                if begin is not None:
                    if len(items) == 1 or (len(items) >= 4 and items[1] == 'B'):
                        mentions.append(
                            Mention(n_mentions, mention_text, entity_title,
                                    (begin, n))
                        )
                        begin = None

                if len(items) >= 4:
                    (marker, text, title) = items[1:4]
                    if marker == 'B':
                        begin = n
                        mention_text = text
                        try:
                            title = title.decode('unicode_escape')
                        except UnicodeEncodeError:
                            title = title

                        entity_title = self._normalize_title(title)
                        n_mentions += 1

                elif len(items) != 1:
                    raise RuntimeError('Invalid annotation line: %s' % line)

            if begin is not None:
                mentions.append(Mention(n_mentions, mention_text, entity_title,
                                        (begin, n)))

            if filter_out_of_kb:
                mentions = self._filter_out_of_kb_mentions(mentions)

            if generate_candidates:
                for mention in mentions:
                    self._generate_candidates(mention)

            if filter_unlinkable:
                mentions = self._filter_unlinkable_mentions(mentions)

            if self._num_candidates:
                for mention in mentions:
                    mention.candidates = mention.candidates[:self._num_candidates]

            documents.append(Document(doc_id, words, mentions, tag))

        return documents

    def _filter_out_of_kb_mentions(self, mentions):
        return [
            mention for mention in mentions
            if mention.entity_title != '--NME--'
        ]

    def _filter_unlinkable_mentions(self, mentions):
        ret = []

        for mention in mentions:
            possible_titles = frozenset(c.title for c in mention.candidates)
            if mention.entity_title not in possible_titles:
                continue

            ret.append(mention)

        return ret

    def _generate_candidates(self, mention):
        try:
            aliases = self.alias_db[mention.text.lower()]
            scores = []
            for alias in aliases:
                try:
                    entity = self.dictionary.get_entity(alias.title)
                    scores.append(entity.doc_count)

                except KeyError:
                    scores.append(0)

            candidates = [o[0] for o in sorted(zip(aliases, scores),
                          key=lambda o: o[1], reverse=True)]
            mention.candidates = candidates

        except KeyError:
            pass

    @staticmethod
    def _normalize_title(title):
        return title.replace('_', ' ')

    def _read_corpus(self):
        corpus_file = os.path.join(self.corpus_dir, DATASET_FILE)
        with open(corpus_file) as f:
            return f.read().decode('utf-8')
