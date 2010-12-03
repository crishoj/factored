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
L		?= da

# Derived variables
PWD = $(shell pwd)
PAIR = $(shell basename $(PWD))
PREFIX = europarl.cleaned
CORPUS = $(PREFIX).$(L)
CLUSTER = clusters/$(L)/$(CLEANED)-c1000-p1.out/paths
DEPPARSE = ../../../stacked_dep/data/$(L)/europarl-$(PAIR)/mst2.out.conll
FACTORED = $(PREFIX).factored.$(L)

LM	    = train/$(CORPUS).lm
POS_LM	    = train/$(CORPUS).pos.lm
DEPREL_LM   = train/$(CORPUS).deprel.lm
CLUSTER_LM  = train/$(CORPUS).cluster.lm
WSD_LM	    = train/$(CORPUS).wsd.lm

LMS = $(LM) $(POS_LM) $(CLUSTER_LM) $(DEPREL_LM) $(WSD_LM)

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

$(CORPUS).pos $(CORPUS).deprel : $(DEPPARSE)
	../../factor --trace conll_extract $< --output-pos $(CORPUS).pos --output-deprel $(CORPUS).deprel

$(CLUSTER) : $(CORPUS)
	mkdir -p clusters/$(L)
	wcluster --text $(CORPUS) --c 1000 --ms-per-line 1000

$(FACTORED) : $(CORPUS) $(CLUSTER) $(DEPPARSE)
	../../factor --trace combine $(CORPUS) --conll $(DEPPARSE) --clusters $(CLUSTER) --output $(FACTORED)

#%.factored : % %.lemmas %.pos %.clusters %.deprels %.wsds
#	../../factor combine $^ --output $@

train/%.$(L) : %.$(L)
	../../split.sh $<

dev/%.$(L) : %.$(L)
	../../split.sh $<

test/%.$(L) : %.$(L)
	../../split.sh $<

$(LM) : train/$(CORPUS)
	ngram-count $(SRILM_OPTIONS) -text $< -lm $@

train/%.lm : train/%
	ngram-count $(SRILM_OPTIONS2) -text $< -lm $@

#$(POS_LM) : train/$(CORPUS).pos
#	ngram-count $(SRILM_OPTIONS2) -text $< -lm $@
#
#$(DEPREL_LM) : train/$(CORPUS).deprel
#	ngram-count $(SRILM_OPTIONS2) -text $< -lm $@
#
#$(CLUSTER_LM) : train/$(CORPUS).cluster
#	ngram-count $(SRILM_OPTIONS2) -text $< -lm $@
#
#$(WSD_LM) : train/$(CORPUS).wsd
#	ngram-count $(SRILM_OPTIONS2) -text $< -lm $@
#
#%.factored.$(L).pos %.factored.$(L).deprel %.factored.$(L).cluster : %.factored.$(L) # Using pattern rule to prevent parallel invocations with the multiple outputs 
#	../../factor --trace split $< --skip 1 --factors pos,deprel,cluster

lms : $(LMS)

clean-lms : 
	rm -rf $(LMS)
