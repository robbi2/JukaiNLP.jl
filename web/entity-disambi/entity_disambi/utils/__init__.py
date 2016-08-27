# -*- coding: utf-8 -*-


def test_alias_correctness(alias, mention, dictionary):
    try:
        mention_title = dictionary.get_entity(mention.entity_title).title
    except KeyError:
        mention_title = mention.entity_title

    try:
        alias_title = dictionary.get_entity(alias.title).title
    except KeyError:
        alias_title = alias.title

    return mention_title == alias_title
