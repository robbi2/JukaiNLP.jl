entity-disambi
---

## Installing entity-disambi

This package can be installed by running the following commands.
Note that before starting to run these commands, Java JDK is required to be installed.

```
% pip install Cython numpy scipy
% pip install -r requirements.txt
% python setup.py install
```

## Downloading Required Files

The following files are required to use this package.
These files should be stored in a same directory.

* Entity Vector
 * [enwiki_entity_vector_500_20151026.pickle](http://entity-vector.s3.amazonaws.com/pub/enwiki_entity_vector_500_20151026.pickle) (803MB)
 * [enwiki_entity_vector_500_20151026_syn0.npy](http://entity-vector.s3.amazonaws.com/pub/enwiki_entity_vector_500_20151026_syn0.npy) (14GB)
* Dictionary
 * [enwiki_dictionary_20150706.pickle](https://s3-ap-northeast-1.amazonaws.com/entity-vector/pub/enwiki_dictionary_20150706.pickle) (803MB)
* Alias DB
 * [enwiki_alias_db_20150928.pickle](https://s3-ap-northeast-1.amazonaws.com/entity-disambi/pub/enwiki_alias_db_20150928.pickle) (1.1GB)
* Learned GBRT model using AIDA/CoNLL
 * [aida_two_step_gbrt_20151130.pickle](https://s3-ap-northeast-1.amazonaws.com/entity-disambi/pub/aida_two_step_gbrt_20151130.pickle) (41MB)

## Basic Usage

### Creating Disambiguator Instance

#### Loading AliasDB

`AliasDB` contains mappings between mention surfaces to their possible entity candidates (e.g., *washington* -> *Washington_D.C.*, *George_Washington*, etc.).
The database also includes prior probability *P(e|m)*, the probability appearing an entity *e* given a mention *m*.

```python
>>> from entity_disambi.alias_db import AliasDB
>>> alias_db = AliasDB.load(open('enwiki_alias_db_20150928.pickle'))
```

#### Loading Dictionary

`Dictionary` is a key-value database containing words and Wikipedia entities with their statistics such as the number of occurrences in Wikipedia.
It can also handle the redirects of Wikipedia entities.

```python
>>> from entity_vector import Dictionary
>>> dictionary = Dictionary.load(open('enwiki_dictionary_20150706.pickle'))
```

#### Loading Entity Vector

`EntityVector` contains distributional representations of words and Wikipedia entities.

```python
>>> from entity_vector import EntityVector
>>> entity_vector = EntityVector.load('enwiki_entity_vector_500_20151026.pickle')
```

#### Creating Disambiguator

Finally, `Disambiguator` can be instantiated by running the following code.

```python
>>> import cPickle as pickle
>>> from entity_disambi.disambiguator import get_disambiguator
>>>
>>> ml_model = pickle.load(open('aida_two_step_gbrt_20151130.pickle'))
>>> disambiguator = get_disambiguator(ml_model['name'])(ml_model, dictionary, alias_db, entity_vector)
```

### Disambiguating Named Entity Mentions

Given a `Document` instance and a `Mention` instance, `Disambiguator` provides the corresponding candidate `Alias` instances of the mention with the confidence scores.

```python
>>> from entity_disambi.models import Document, Mention
>>>
>>> mention_surfaces = [u'Star Wars']
>>> mentions = []
>>> for (mention_id, surface) in enumerate(mention_surfaces):
...     mention = Mention(mention_id, surface, None)
...     if surface.lower() in alias_db:
...         mention.candidates = alias_db[surface.lower()]
...     mentions.append(mention)
>>> document_id = 0  # required to be a unique number
>>> words = [u'I', u'like', u'Star', u'Wars' u'.']
>>> document = Document(document_id, words, mentions)
>>> for (alias, score) in disambiguator.get_aliases_with_scores(mention, document):
...     print 'title: %s, score: %.3f' % (alias.title, score)
title: Star Wars, score: 0.999
title: Star Wars (film), score: 0.219
title: Star Wars (comics), score: 0.022
title: Strategic Defense Initiative, score: 0.014
title: Star Wars (1983 video game), score: 0.014
...
```
<!--
## Advanced Usage

### Building Alias DB from Wikipedia dump

The following command builds serialized `AliasDB` file directly from a Wikipedia dump.

```
% entity_disambi build_wikipedia_alias_db WIKIPEDIA_DUMP_FILE OUT_FILE DICTIONARY_FILE
```

### Training Machine Learning Model

```
% entity-disambi disambiguator build_dataset --corpus-type=aida --corpus-tag=train DATASET_DIR DICTIONARY_FILE ALIAS_DB_FILE ENTITY_VECTOR_FILE OUT_FILE
% entity-disambi disambiguator build_gradient_boosting --n-estimators=10000 --learning-rate=0.02 --max-depth=4 DATASET_FILE MODEL_FILE
% entity-disambi disambiguator build_two_step_dataset --corpus-type=aida --corpus-tag=train dataset/aida-yago2 DICTIONARY_FILE ALIAS_DB_FILE ENTITY_VECTOR_FILE MODEL_FILE OUT_FILE
% entity-disambi disambiguator build_two_step_gradient_boosting --n-estimators=10000 --learning-rate=0.02 --max-depth=4 TWO_STEP_DATASET_FILE OUT_FILE
```
 -->
