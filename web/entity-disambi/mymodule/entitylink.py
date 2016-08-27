# -*- coding: utf-8 -*-
from entity_disambi.alias_db import AliasDB
from entity_vector import Dictionary
from entity_vector import EntityVector
import cPickle as pickle
from entity_disambi.disambiguator import get_disambiguator
from entity_disambi.models import Document, Mention

HOME = "/home/hshindo/entity-disambi/"
alias_db = AliasDB.load(open(HOME+"enwiki_alias_db_20150928.pickle"))
dictionary = Dictionary.load(open(HOME+"enwiki_dictionary_20150706.pickle"))
entity_vector = EntityVector.load(HOME+"enwiki_entity_vector_500_20151026.pickle")
ml_model = pickle.load(open(HOME+"aida_two_step_gbrt_20151130.pickle"))
disambiguator = get_disambiguator(ml_model['name'])(ml_model, dictionary, alias_db, entity_vector)

# query example: predict(["Louisiana"], ["Diamond", "Shamrock", "Offshore", "Partners","said","it","had","discovered","gas","offshore","Louisiana", "."])
# predict(["Star Wars"], ["I", "like", "Star", "Wars", "."])

def to_utf8(data):
	for i in range(len(data)):
		data[i] = unicode(data[i], 'utf-8')

def predict(surfaces, words):
	to_utf8(surfaces)
	to_utf8(words)

	mention_surfaces = surfaces
	mentions = []
	for (mention_id, surface) in enumerate(mention_surfaces):
		mention = Mention(mention_id, surface, None)
		if surface.lower() in alias_db:
			mention.candidates = alias_db[surface.lower()]
		mentions.append(mention)

	document_id = 0  # required to be a unique number
	document = Document(document_id, words, mentions)
	alias, score = disambiguator.get_aliases_with_scores(mention, document)[0]
	print 'title: %s, score: %.3f' % (alias.title, score)

	#for mention in mentions:
	#	for (alias, score) in disambiguator.get_aliases_with_scores(mention, document):
	#		print 'title: %s, score: %.3f' % (alias.title, score)
