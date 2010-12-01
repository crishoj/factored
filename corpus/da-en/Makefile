# 
# Makefile for factored MT corpora
# 
# OBJECTIVE: Let GNU's make handle the dependency chain for 
# constructing factored MT corpora, including updating files
# when their dependencies have been updated with newer versions.
#
# AUTHOR: crjensen@hum.ku.dk
#
# NOTE: Expects environment variable L to contain a language code
# for the desired language
#

# Arguments from environment
L		?= en

# Derived variables
CLUSTER = clusters/$(L)/europarl.cleaned-c1000-p1.out/paths
DEPPARSE = ../../../stacked_dep/data/$(L)/europarl-da-en/mst2.out.conll
CLEANED = europarl.cleaned.$(L)
PREFIX = europarl.factored
FACTORED = $(PREFIX).$(L)
TRAIN = $(PREFIX).train.$(L)
TEST = $(PREFIX).test.$(L)
DEV = $(PREFIX).dev.(L)

POS_CORPUS = $(TRAIN).pos
DEPREL_CORPUS = $(TRAIN).deprel
CLUSTER_CORPUS = $(TRAIN).cluster

LM = $(TRAIN).lm
POS_LM = $(POS_CORPUS).lm
DEPREL_LM = $(DEPREL_CORPUS).lm
CLUSTER_LM = $(CLUSTER_CORPUS).lm

LMS = $(LM) $(POS_LM) $(CLUSTER_LM) $(DEPREL_LM)

CSTLEMMA = $(HOME)/src/cstlemma/bin/linux/64/cstlemma
CSTLEMMA_OPTS = -t- -b '$$w' -B '$$w' -c '$$b1[[$$b?]~1$$B]$$s' -f $(HOME)/opt/cstlemma/da/flexrules -d $(HOME)/opt/cstlemma/da/dict -eU

LEMMAGEN = /nyusers/anders/stemmers/v2/lemmagen/binary/linux/lemmatize
LEMMAGEN_OPTS = -l /nyusers/anders/stemmers/v2/data/lemmatizer/lem-me-en.bin

SRILM_OPTIONS = -order 3 -interpolate -kndiscount -unk 
SRILM_OPTIONS2 = -order 3 -interpolate 

%.da.lemmas : %.da 
	$(CSTLEMMA) $(CSTLEMMA_OPTS) -i $< -o $@

%.en.lemmas : %.en 
	$(LEMMAGEN) $(LEMMAGEN_OPTS) $< $@

$(CLUSTER) : $(CLEANED)
	mkdir -p clusters/$(L)
	wcluster --text $(CLEANED) --c 1000 --ms-per-line 1000

$(FACTORED) : $(CLEANED) $(CLUSTER) $(DEPPARSE)
	../../factor --trace combine $(CLEANED) --conll $(DEPPARSE) --clusters $(CLUSTER) --output $(FACTORED)

$(TRAIN) : $(FACTORED)
	../../split.sh $(PREFIX) $(L)

$(LM) : $(TRAIN)
	ngram-count $(SRILM_OPTIONS) -text $(TRAIN) -lm $(LM)

$(POS_LM) : $(POS_CORPUS)
	ngram-count $(SRILM_OPTIONS2) -text $(POS_CORPUS) -lm $(POS_LM)

$(DEPREL_LM) : $(DEPREL_CORPUS)
	ngram-count $(SRILM_OPTIONS2) -text $(DEPREL_CORPUS) -lm $(DEPREL_LM)

$(CLUSTER_LM) : $(CLUSTER_CORPUS)
	ngram-count $(SRILM_OPTIONS2) -text $(CLUSTER_CORPUS) -lm $(CLUSTER_LM)

%.factored.$(L).pos %.factored.$(L).deprel %.factored.$(L).cluster : %.factored.$(L) # Using pattern rule to prevent parallel invocations with the multiple outputs 
	../../factor --trace split $< --skip 1 --factors pos,deprel,cluster

lms : $(LMS)

clean-lms : 
	rm -rf $(LMS)




