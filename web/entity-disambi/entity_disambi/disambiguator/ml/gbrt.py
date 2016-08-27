# -*- coding: utf-8 -*-

import click
from sklearn.ensemble import GradientBoostingClassifier

from entity_disambi.disambiguator import register_disambiguator
from base_ml import BaseMLDisambiguator, TwoStepMLDisambiguator


class GradientBoostingDisambiguator(BaseMLDisambiguator):
    def __init__(self, model, *args, **kwargs):
        super(GradientBoostingDisambiguator, self).__init__(*args, **kwargs)

        self._ml_model = model['ml_model']
        self._vectorizer = model['vectorizer']

    @classmethod
    def build_model(cls, dataset, **kwargs):
        click.echo('Model parameters: %s' % kwargs)

        model = GradientBoostingClassifier(random_state=0, **kwargs)
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


class TwoStepGradientBoostingDisambiguator(TwoStepMLDisambiguator):
    def __init__(self, model, *args, **kwargs):
        self._ml_model = model['ml_model']
        self._vectorizer = model['vectorizer']

        super(TwoStepGradientBoostingDisambiguator, self).__init__(
            model['base_disambiguator_model'], *args, **kwargs
        )

    @classmethod
    def build_model(cls, dataset, **kwargs):
        click.echo('Model parameters: %s' % kwargs)

        model = GradientBoostingClassifier(random_state=0, **kwargs)
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


register_disambiguator(GradientBoostingDisambiguator)
register_disambiguator(TwoStepGradientBoostingDisambiguator)
