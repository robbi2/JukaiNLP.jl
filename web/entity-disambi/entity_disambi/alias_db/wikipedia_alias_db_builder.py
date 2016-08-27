# -*- coding: utf-8 -*-

import dawg
import logging
import re
from collections import defaultdict, Counter
from functools import partial
from itertools import imap
from multiprocessing.pool import Pool
from entity_vector import wiki_page

from alias_db import AliasDB

from entity_vector.wiki_dump_reader import WikiDumpReader

logger = logging.getLogger(__name__)

TITLE_DISAMBI_MATCHER = re.compile(r'\s\(.*\)$')


def build(dump_file, out_file, dictionary, tokenize_title, parallel, pool_size,
          chunk_size):
    logger.info('Starting to build an entity alias DB...')

    dump_reader = WikiDumpReader(dump_file)

    if parallel:
        pool = Pool(pool_size)
        imap_func = partial(pool.imap_unordered, chunksize=chunk_size)
    else:
        imap_func = imap

    name_title_dict = defaultdict(lambda: Counter())
    for (page, links) in imap_func(_process_page, dump_reader,
                                   chunksize=chunk_size):
        try:
            dest_title = dictionary.get_entity(page.title).title
        except KeyError:
            dest_title = page.title
        # dest_title = page.title

        normalized_title = _normalize_title(page.title)
        name_title_dict[normalized_title][dest_title] += 1

        if tokenize_title:
            for word in normalized_title.split():
                if word != normalized_title:
                    name_title_dict[word][dest_title] += 0

        for link_obj in links:
            try:
                link_title = dictionary.get_entity(link_obj.title).title
            except KeyError:
                link_title = link_obj.title
            # link_title = link_obj.title

            name_title_dict[link_obj.text.lower()][link_title] += 1

    if parallel:
        pool.close()

    titles = list(set([
        title
        for (name, title_counter) in name_title_dict.iteritems()
        for (title, _) in title_counter.iteritems()
    ]))
    title_index = {title: n for (n, title) in enumerate(titles)}

    def item_generator():
        for (name, title_counter) in name_title_dict.iteritems():
            total_count = sum(title_counter.values())
            for (title, count) in title_counter.iteritems():
                if total_count > 0:
                    prior_prob = float(count) / total_count
                else:
                    prior_prob = 0.0
                yield (name, (title_index[title], prior_prob))

    logger.info('Building DAWG...')

    db = AliasDB()
    db._dawg = dawg.RecordDAWG('<If', item_generator())
    db._titles = titles

    db.save(out_file)


def _normalize_title(title):
    return TITLE_DISAMBI_MATCHER.sub('', title).lower()


def _process_page(page):
    return (page, [
        item
        for paragraph in page.extract_paragraphs()
        for item in paragraph
        if isinstance(item, wiki_page.WikiLink)
    ])
