# -*- coding: utf-8 -*-

import numpy as np
from setuptools import setup, find_packages, Extension
from Cython.Build import cythonize

setup(
    name='entity-disambi',
    version='0.0.1.2',
    description='An experimental implementation of named entity disambiguation',
    author='Studio Ousia',
    author_email='ikuya@ousia.jp',
    packages=find_packages(),
    include_package_data=True,
    zip_safe=False,
    entry_points={
        'console_scripts': [
            'entity-disambi=entity_disambi:cli'
        ]
    },
    ext_modules=cythonize([
        Extension(
            '*', ['entity_disambi/alias_db/*.pyx'],
            include_dirs=[np.get_include()],
        ),
        Extension(
            '*', ['entity_disambi/*.pyx'],
            include_dirs=[np.get_include()],
        ),
        Extension(
            '*', ['entity_disambi/disambiguator/*.pyx'],
            include_dirs=[np.get_include()],
        ),
        Extension(
            '*', ['entity_disambi/utils/*.pyx'],
            include_dirs=[np.get_include()],
        ),
    ]),
    install_requires=[
        'beautifulsoup4',
        'click',
        'DAWG',
        'gensim',
        'nltk',
        'numpy',
        'python-Levenshtein',
        'scikit-learn',
        'scipy',
        'xgboost',
        'jnius',
        'entity-vector',
    ],
    tests_require=['nose'],
    test_suite='nose.collector',
)
