# -*- coding: utf-8 -*-

import bz2
import csv
import dawg
import json
import logging
from collections import defaultdict

from alias_db import AliasDB

logger = logging.getLogger(__name__)


def build(aida_means_file, wiki_label_jsonl_file, out_file):
    logger.info('Starting to build an entity alias DB...')

    entity_name_dict = defaultdict(dict)

    logger.info('Step 1/3: Processing AIDA means dataset...')
    for (n, (name, title)) in enumerate(
        csv.reader(bz2.BZ2File(aida_means_file), delimiter='\t'), 1
    ):
        if n % 1000000 == 0:
            logger.info('Processed: %d', n)

        name = name.decode('unicode-escape').lower()
        title = title.decode('unicode-escape').replace(u'_', u' ')

        # default probability of prior_prob is obtained from here:
        # https://github.com/wikilinks/nel/blob/master/nel/model/model.py
        entity_name_dict[title][name] = dict(prior_prob=1e-20)

    logger.info('Step 2/3: Processing Label JSON lines file...')

    for (n, line) in enumerate(wiki_label_jsonl_file, 1):
        if n % 1000000 == 0:
            logger.info('Processed: %d', n)

        parsed = json.loads(line)

        if parsed['name'] not in entity_name_dict[parsed['title']]:
            continue

        obj = entity_name_dict[parsed['title']][parsed['name']]
        obj['prior_prob'] = parsed['prior_prob']

    logger.info('Step 3/3: Building DAWG...')

    titles = entity_name_dict.keys()
    title_index = {title: n for (n, title) in enumerate(titles)}

    def item_generator():
        for (title, name_dict) in entity_name_dict.iteritems():
            for (name, obj) in name_dict.iteritems():
                yield (name, (title_index[title], obj['prior_prob']))

    db = AliasDB()
    db._dawg = dawg.RecordDAWG('<If', item_generator())
    db._titles = titles

    db.save(out_file)
