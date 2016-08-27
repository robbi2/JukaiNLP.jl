# -*- coding: utf-8 -*-

import click
from sklearn.ensemble import RandomForestClassifier

from entity_disambi.disambiguator import register_disambiguator
from base_ml import BaseMLDisambiguator, TwoStepMLDisambiguator


class RandomForestDisambiguator(BaseMLDisambiguator):
    def __init__(self, model, *args, **kwargs):
        super(RandomForestDisambiguator, self).__init__(*args, **kwargs)

        self._ml_model = model['ml_model']
        self._vectorizer = model['vectorizer']

    @classmethod
    def build_model(cls, dataset, **kwargs):
        click.echo('Model parameters: %s' % kwargs)

        model = RandomForestClassifier(random_state=0, n_jobs=-1, **kwargs)
        model = model.fit(dataset.feature_matrix, dataset.labels)
        model.n_jobs = 1

        click.echo('Feature importances:')
        for (score, name) in sorted(zip(model.feature_importances_,
                                        dataset.vectorizer.feature_names_)):
            click.echo('- %s, %.3f' % (name, score))

        return dict(name=cls.__name__, ml_model=model,
                    vectorizer=dataset.vectorizer)

    def _get_scores(self, feature_matrix):
        return [o[1] for o in self._ml_model.predict_proba(feature_matrix)]


class TwoStepRandomForestDisambiguator(TwoStepMLDisambiguator):
    def __init__(self, model, *args, **kwargs):
        self._ml_model = model['ml_model']
        self._vectorizer = model['vectorizer']

        super(TwoStepRandomForestDisambiguator, self).__init__(
            model['base_disambiguator_model'], *args, **kwargs
        )

    @classmethod
    def build_model(cls, dataset, **kwargs):
        click.echo('Model parameters: %s' % kwargs)

        model = RandomForestClassifier(random_state=0, n_jobs=-1, **kwargs)
        model = model.fit(dataset.feature_matrix, dataset.labels)
        model.n_jobs = 1

        click.echo('Feature importances:')
        for (score, name) in sorted(zip(model.feature_importances_,
                                        dataset.vectorizer.feature_names_)):
            click.echo('- %s, %.3f' % (name, score))

        return dict(
            name=cls.__name__, ml_model=model,
            base_disambiguator_model=dataset.base_disambiguator_model,
            vectorizer=dataset.vectorizer
        )

    def _get_scores(self, feature_matrix):
        return [o[1] for o in self._ml_model.predict_proba(feature_matrix)]


register_disambiguator(RandomForestDisambiguator)
register_disambiguator(TwoStepRandomForestDisambiguator)
