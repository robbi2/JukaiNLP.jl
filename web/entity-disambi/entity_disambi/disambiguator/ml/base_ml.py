# -*- coding: utf-8 -*-

import click
import Levenshtein
import math
import numpy as np
import re
from collections import defaultdict
from scipy.spatial.distance import cosine
from sklearn.feature_extraction import DictVectorizer

from entity_disambi.disambiguator import get_disambiguator
from entity_disambi.disambiguator.base import BaseDisambiguator
from entity_disambi.utils import test_alias_correctness

TITLE_DISAMBI_MATCHER = re.compile(r'\s\(.*\)$')
# DEFAULT_COS_SIM = 2.0
DEFAULT_COS_SIM = 3.0
_cache = {}


class MLDisambiguatorDataset(object):
    def __init__(self, feature_matrix, labels, groups, vectorizer,
                 base_disambiguator_model=None):
        self.feature_matrix = feature_matrix
        self.labels = labels
        self.groups = groups
        self.vectorizer = vectorizer
        self.base_disambiguator_model = base_disambiguator_model


class BaseMLDisambiguator(BaseDisambiguator):
    def __init__(self, *args, **kwargs):
        super(BaseMLDisambiguator, self).__init__(*args, **kwargs)

    @staticmethod
    def build_model(dataset):
        raise NotImplementedError()

    def build_dataset(self, documents):
        feature_list = []
        labels = []
        groups = []
        group_num = 0
        with click.progressbar(documents, show_pos=True) as bar:
            for document in bar:
                for mention in document.mentions:
                    candidates = mention.candidates
                    features_list = self._generate_features(mention, document)
                    for (alias, features) in zip(candidates, features_list):
                        label = test_alias_correctness(alias, mention,
                                                       self.dictionary)
                        feature_list.append(features)
                        labels.append(label)
                        groups.append(group_num)

                    group_num += 1

        vectorizer = DictVectorizer(sparse=False)
        feature_matrix = vectorizer.fit_transform(feature_list)
        labels = np.array(labels)

        return MLDisambiguatorDataset(feature_matrix, labels, groups,
                                      vectorizer)

    def get_aliases_with_scores(self, mention, document):
        if not mention.candidates:
            return []

        features_list = self._generate_features(mention, document)
        if not features_list:
            return []

        feature_matrix = self._vectorizer.transform(features_list)
        scores = self._get_scores(feature_matrix)

        return sorted(zip(mention.candidates, scores), key=lambda o: o[1],
                      reverse=True)

    def _generate_features(self, mention, document):
        n_candidates = len(mention.candidates)
        if n_candidates == 0:
            return []

        word_cos_sims = []
        ent_cos_sims = []

        cxt_word_vec = self.get_vector_of_context_words(
            mention, document, noun_only=True, tfidf=False
        )

        for alias in mention.candidates:
            try:
                entity = self.dictionary.get_entity(alias.title)
            except KeyError:
                word_cos_sims.append(DEFAULT_COS_SIM)
                ent_cos_sims.append(DEFAULT_COS_SIM)
                continue

            ent_vec = self.entity_vector.get_vector(entity)

            if cxt_word_vec is not None:
                word_cos_sims.append(cosine(ent_vec, cxt_word_vec))
            else:
                word_cos_sims.append(DEFAULT_COS_SIM)

            cxt_ent_vec = self.get_vector_of_context_entities(alias, mention,
                                                              document)
            if cxt_ent_vec is not None:
                ent_cos_sims.append(cosine(ent_vec, cxt_ent_vec))
            else:
                ent_cos_sims.append(DEFAULT_COS_SIM)

        word_cos_ranks = [0] * n_candidates
        ent_cos_ranks = [0] * n_candidates
        for (i, x) in enumerate(sorted(range(n_candidates),
                                       key=lambda y: word_cos_sims[y])):
            word_cos_ranks[x] = i

        for (i, x) in enumerate(sorted(range(n_candidates),
                                       key=lambda y: ent_cos_sims[y])):
            ent_cos_ranks[x] = i

        features_list = []
        for (n, alias) in enumerate(mention.candidates):
            features = self._generate_local_features(alias, mention, document)
            features['word_vec_cos_sim'] = word_cos_sims[n]
            features['ent_vec_cos_sim'] = ent_cos_sims[n]
            features['word_vec_sim_rank'] = word_cos_ranks[n]
            features['ent_vec_sim_rank'] = ent_cos_ranks[n]
            features['num_candidates'] = n_candidates

            features_list.append(features)

        return features_list

    def _generate_local_features(self, alias, mention, document):
        features = {}

        try:
            entity = self.dictionary.get_entity(alias.title)
            features['inlink_count'] = math.log(entity.doc_count)

            max_probs = self._get_entities_with_max_prior_prob(document)
            features['max_prior_prob'] = max_probs[entity.title]

        except KeyError:
            pass

        features['wiki_prior_prob'] = alias.prior_prob

        normalized_title = TITLE_DISAMBI_MATCHER.sub('', alias.title).lower()
        normalized_mention_text = mention.text.lower()

        distance = Levenshtein.distance(normalized_title, normalized_mention_text)
        length = max(len(normalized_mention_text), len(normalized_title))

        features['edit_dist_norm'] = float(distance) / length

        features['mention_eq_title'] = bool(normalized_title == normalized_mention_text)
        features['mention_in_title'] = bool(
            (normalized_mention_text in normalized_title) and
            (normalized_mention_text != normalized_title)
        )
        features['title_starts_with_mention'] = normalized_title.startswith(normalized_mention_text)
        features['title_ends_with_mention'] = normalized_title.endswith(normalized_mention_text)

        features['title_len'] = len(normalized_title.split())
        features['mention_len'] = len(mention.text.split())

        return features

    def _get_entities_with_max_prior_prob(self, document):
        cache_key = ('get_entities_with_max_prior_prob', document.id)
        if cache_key in self._cache:
            return self._cache[cache_key]

        ret = defaultdict(float)
        for mention in document.mentions:
            for candidate in mention.candidates:
                if candidate.prior_prob > ret[candidate.title]:
                    ret[candidate.title] = candidate.prior_prob

        self._cache[cache_key] = ret
        return ret

    def get_vector_of_context_words(self, mention, document, noun_only=False,
                                    tfidf=True):
        mention_words = frozenset([w.lower() for w in mention.text.split()])
        word_pos_tag_pairs = [
            (w, p)
            for (w, p) in zip(document.words, document.pos_tags)
            if w.lower() not in mention_words
        ]
        words = [unicode(o[0]) for o in word_pos_tag_pairs]
        pos_tags = [o[1] for o in word_pos_tag_pairs]

        if noun_only:
            words = [word for (word, pos_tag) in zip(words, pos_tags)
                     if pos_tag.startswith('NN')]

        bow = self.dictionary.get_bow_vector(
            [w.lower() for w in words], tfidf=tfidf
        )
        vectors = [
            self.entity_vector.get_word_vector(w.text.lower())
            for (w, _) in bow
        ]
        weights = [score for (_, score) in bow]

        if vectors:
            return np.average(vectors, axis=0, weights=weights)
        else:
            return None

    def get_vector_of_context_entities(self, alias, mention, document,
                                       min_prior_prob=0.95):
        vectors = []
        mentions = [m for m in document.mentions if m != mention]
        for target_mention in mentions:
            for alias2 in target_mention.candidates:
                if alias.title == alias2.title:
                    continue

                if alias2.prior_prob > min_prior_prob:
                    try:
                        entity = self.dictionary.get_entity(alias2.title)
                        vectors.append(self.entity_vector.get_vector(entity))

                    except KeyError:
                        continue

        if vectors:
            return np.mean(vectors, axis=0)
        else:
            return None


class TwoStepMLDisambiguator(BaseMLDisambiguator):
    def __init__(self, base_disambiguator_model, *args, **kwargs):
        super(TwoStepMLDisambiguator, self).__init__(*args, **kwargs)

        self._base_disambiguator_model = base_disambiguator_model
        self._base_disambiguator = get_disambiguator(
            self._base_disambiguator_model['name']
        )(
            self._base_disambiguator_model, self.dictionary, self.alias_db,
            self.entity_vector
        )

        self._processed_docs = set()

    def build_dataset(self, documents):
        click.echo('Step 1/2: Disambiguating mentions using base disambiguator...')
        with click.progressbar(documents, show_pos=True) as bar:
            for document in bar:
                for mention in document.mentions:
                    pairs = self._base_disambiguator.get_aliases_with_scores(
                        mention, document
                    )
                    if pairs:
                        mention.predicted_title = pairs[0][0].title

        click.echo('Step 2/2: Building dataset...')
        dataset = super(TwoStepMLDisambiguator, self).build_dataset(documents)
        dataset.base_disambiguator_model = self._base_disambiguator_model

        return dataset

    def get_aliases_with_scores(self, mention, document):
        if document.id not in self._processed_docs:
            for m in document.mentions:
                pairs = self._base_disambiguator.get_aliases_with_scores(
                    m, document
                )
                if pairs:
                    m.predicted_title = pairs[0][0].title
            self._processed_docs.add(document.id)

        return super(TwoStepMLDisambiguator, self).get_aliases_with_scores(
            mention, document
        )

    def get_vector_of_context_entities(self, alias, mention, document):
        entities_vec = []
        for m in document.mentions:
            if m == mention:
                continue
            if m.predicted_title is None:
                continue
            if m.predicted_title == alias.title:
                continue

            try:
                entities_vec.append(
                    self.entity_vector.get_entity_vector(m.predicted_title)
                )
            except KeyError:
                pass

        if entities_vec:
            return np.mean(entities_vec, axis=0)
        else:
            return None
