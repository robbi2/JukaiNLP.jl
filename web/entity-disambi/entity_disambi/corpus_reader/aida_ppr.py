# -*- coding: utf-8 -*-

import click
import os
import random

from aida import AIDACorpusReader
from entity_disambi.alias_db import Alias

CANDIDATES_DIR = 'PPRforNED/AIDA_candidates/'


class AIDAPPRCorpusReader(AIDACorpusReader):
    def __init__(self, corpus_dir, dictionary, alias_db):
        super(AIDAPPRCorpusReader, self).__init__(
            corpus_dir, dictionary, alias_db, None
        )

    def get_documents(self, tags=None, filter_out_of_kb=True,
                      filter_mentions_with_no_candidate=True):
        documents = super(AIDAPPRCorpusReader, self).get_documents(
            tags=tags, filter_out_of_kb=False, filter_unlinkable=False,
            generate_candidates=False
        )
        self._parse_corpus(documents)

        if filter_out_of_kb:
            for document in documents:
                document.mentions = self._filter_out_of_kb_mentions(document.mentions)

        if filter_mentions_with_no_candidate:
            for document in documents:
                document.mentions = self._filter_mentions_with_no_candidate(document.mentions)

        click.echo('The number of mentions: %d' % len(
            [m for doc in documents for m in doc.mentions]
        ))
        click.echo('The number of documents: %d' % len(documents))

        return documents

    def _filter_mentions_with_no_candidate(self, mentions):
        return [mention for mention in mentions if mention.candidates]

    def _parse_corpus(self, documents):
        candidates_dir = os.path.join(self.corpus_dir, CANDIDATES_DIR)
        for document in documents:
            if document.id <= 1000:
                dir_name = 'PART_1_1000'
            else:
                dir_name = 'PART_1001_1393'

            target_file = os.path.join(os.path.join(candidates_dir, dir_name),
                                       str(document.id))
            obj = None
            mentions = []
            with open(target_file) as f:
                for line in f:
                    line = line.decode('utf-8')

                    if line.startswith('ENTITY'):
                        text = line.split('\t')[7][9:]
                        if obj:
                            mentions.append(obj)
                        obj = (text, [])

                    elif line.startswith('CANDIDATE'):
                        wiki_uri = line.split('\t')[5][4:]
                        title = wiki_uri[29:].replace('_', ' ')

                        try:
                            title = self.dictionary.get_entity(title).title
                        except KeyError:
                            pass

                        obj[1].append(title)

                if obj:
                    mentions.append(obj)

            cur = 0
            random.seed(0)
            for (text, candidate_titles) in mentions:
                while text != document.mentions[cur].text:
                    cur += 1

                candidates = []

                try:
                    aliases = self.alias_db[text.lower()]
                except:
                    aliases = []

                title_prior_prob_map = {
                    alias.title: alias.prior_prob for alias in aliases
                }

                for title in candidate_titles:
                    prior_prob = title_prior_prob_map.get(title, 1e-20)
                    candidates.append(Alias(text, title, prior_prob))

                random.shuffle(candidates)
                document.mentions[cur].candidates = candidates
                cur += 1
