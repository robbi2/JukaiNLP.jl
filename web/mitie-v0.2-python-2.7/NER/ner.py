import sys, os
# Make sure you put the mitielib folder into the python search path.  There are
# a lot of ways to do this, here we do it programmatically with the following
# two statements:
parent = os.path.dirname(os.path.realpath(__file__))
sys.path.append(parent + '/../../mitielib')

from mitie import *
from collections import defaultdict

print ("loading NER model...")
ner = named_entity_extractor('models/ner_model.dat')
#print ("\nTags output by this NER model:", ner.get_possible_ner_tags())

# Load a text file and convert it into a list of words.  
#tokens = tokenize(load_entire_file('sample_text.txt'))
#print ("Tokenized input:", tokens)

def predict(tokens):
	#tokens = tokenize(str)
	entities = ner.extract_entities(tokens)
	#print ("\nEntities found:", entities)
	#print ("\nNumber of entities detected:", len(entities))
	
	res = []
	for e in entities:
		range = e[0]
		tag = e[1]
		entity_text = " ".join(tokens[i] for i in range)
		#print ("    " + tag + ": " + entity_text)
		res.append((range,tag))
	return res
