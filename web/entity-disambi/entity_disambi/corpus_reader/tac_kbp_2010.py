# -*- coding: utf-8 -*-

import click
import os
import shelve
from bs4 import BeautifulSoup
from bs4.element import NavigableString
from collections import defaultdict
from nltk.tokenize import word_tokenize

from entity_disambi.models import Document
from entity_disambi.models import Mention
from . import BaseCorpusReader

QUERIES_XML_FILE_NAME = {
    'training': 'tac_kbp_2010_english_entity_linking_training_queries.xml',
    'eval': 'tac_kbp_2010_english_entity_linking_evaluation_queries.xml',
}

KB_LINKS_FILE_NAME = {
    'training': 'tac_kbp_2010_english_entity_linking_training_KB_links.tab',
    'eval': 'tac_kbp_2010_english_entity_linking_evaluation_KB_links.tab',
}

ENTITY_DB_FILE_NAME = 'entity_id_db'
TAG_ALIASES = {
    'train': 'training',
    'test': 'eval'
}


class TACKBP2010CorpusReader(BaseCorpusReader):
    def __init__(self, corpus_dir, dictionary, alias_db, num_candidates=50):
        super(TACKBP2010CorpusReader, self).__init__(
            corpus_dir, dictionary, alias_db
        )
        self._num_candidates = num_candidates

    def get_documents(self, tags=None, generate_candidates=True):
        if tags:
            tags = [TAG_ALIASES.get(tag, tag) for tag in tags]

        entity_id_db = shelve.open(
            os.path.join(self.corpus_dir, ENTITY_DB_FILE_NAME)
        )

        documents = []
        n_mentions = 0

        for tag in ('training', 'eval'):
            if tags and tag not in tags:
                continue

            base_path = os.path.join(os.path.join(self.corpus_dir, tag))

            link_entity_mapping = {}
            with open(os.path.join(base_path, KB_LINKS_FILE_NAME[tag])) as f:
                for line in f:
                    (link_id, entity_id) = line.split('\t')[:2]
                    entity_id = entity_id.encode('utf-8')
                    if entity_id.startswith('NIL'):
                        link_entity_mapping[link_id] = 'NIL'
                    else:
                        link_entity_mapping[link_id] = entity_id_db[entity_id]

            doc_mentions = defaultdict(list)

            with open(os.path.join(base_path, QUERIES_XML_FILE_NAME[tag])) as f:
                parsed = BeautifulSoup(f.read(), 'html.parser')
                for query in parsed.find_all('query'):
                    doc_id = query.docid.text

                    text = query.find('name').text
                    entity_title = link_entity_mapping[query['id']]
                    if entity_title == 'NIL':
                        continue

                    mention = Mention(n_mentions, text, entity_title)
                    doc_mentions[doc_id].append(mention)
                    n_mentions += 1

            doc_path = os.path.join(base_path, 'source_documents')

            for (doc_id, mentions) in doc_mentions.items():
                with open(os.path.join(doc_path, doc_id + '.xml')) as f:
                    text = self._get_text(f.read(), doc_id)

                words = word_tokenize(text)
                if generate_candidates:
                    for mention in mentions:
                        self._generate_candidates(mention)

                    documents.append(Document(doc_id, words, mentions, tag))

        click.echo('The number of mentions: %d' % n_mentions)
        click.echo('The number of documents: %d' % len(documents))

        return documents

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
            mention.candidates = candidates[:self._num_candidates]

        except KeyError:
            pass

    @staticmethod
    def _get_text(xml_text, doc_id):
        parsed = BeautifulSoup(xml_text, 'html.parser')
        if doc_id.startswith('eng-NG-') or doc_id.startswith('eng-WL'):
            texts = []
            for content in parsed.post.contents:
                if isinstance(content, NavigableString):
                    texts.append(unicode(content))
            return u'\n'.join(texts)

        else:
            return parsed.find('text').text
