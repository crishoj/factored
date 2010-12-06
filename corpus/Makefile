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
PREFIX 		?= europarl.cleaned
DEV_SENTS	?= 2000
TEST_SENTS	?= 10000

# Derived variables
PWD 		= $(shell pwd)
PAIR 		= $(shell basename $(PWD))
CORPUS 		= $(PREFIX).$(L)
CLUSTER_PATHS 	= clusters/$(L)/$(PREFIX)-c1000-p1.out/paths
DEPPARSE 	= ../../../stacked_dep/data/$(L)/europarl-$(PAIR)/mst2.out.conll

LM	    	= train/$(CORPUS).lm
LEMMA_LM    	= train/$(CORPUS).lemma.lm
POS_LM	    	= train/$(CORPUS).pos.lm
DEPREL_LM  	= train/$(CORPUS).deprel.lm
CLUSTER_LM  	= train/$(CORPUS).cluster.lm
WSD_LM	    	= train/$(CORPUS).wsd.lm

LMS 		= $(LM) $(LEMMA_LM) $(POS_LM) $(CLUSTER_LM) $(DEPREL_LM) $(WSD_LM)

FACTOR_TOOL 	= ../../factor

CSTLEMMA 	= /opt/cstlemma/cstlemma
CSTLEMMA_OPTS 	= -t- -b '$$w' -B '$$w' -c '$$b1[[$$b?]~1$$B]$$s' -f /opt/cstlemma/da/flexrules -d /opt/cstlemma/da/dict -eU

LEMMAGEN 	= /nyusers/anders/stemmers/v2/lemmagen/binary/linux/lemmatize
LEMMAGEN_OPTS 	= -l /nyusers/anders/stemmers/v2/data/lemmatizer/lem-me-en.bin

SRILM_OPTIONS 	= -order 3 -interpolate -kndiscount -unk 
SRILM_OPTIONS2 	= -order 3 -interpolate 

SPLIT_CMD	= ../../split.sh $(DEV_SENTS) $(TEST_SENTS)

.DELETE_ON_ERROR : # don't leave half-baked files around

.SECONDARY : # keep "intermediate" files (for reuse)

.PHONY : lms clean-lms factored unfactored

%.da.lemma : %.da 
	$(CSTLEMMA) $(CSTLEMMA_OPTS) -i $< -o $@

%.en.lemma : %.en 
	$(LEMMAGEN) $(LEMMAGEN_OPTS) $< $@

$(CORPUS).pos $(CORPUS).deprel : $(DEPPARSE)
	$(FACTOR_TOOL) --trace conll_extract $< --output-pos $(CORPUS).pos --output-deprel $(CORPUS).deprel

$(CLUSTER_PATHS) : $(CORPUS)
	mkdir -p clusters/$(L)
	wcluster --text $(CORPUS) --c 1000 --ms-per-line 1000

%.cluster : % $(CLUSTER_PATHS)
	$(FACTOR_TOOL) cluster_extract --output $@ $^

%.factored : % %.lemma %.pos %.cluster %.deprel %.wsd
	$(FACTOR_TOOL) combine $^ --output $@

%.wsd.context : %.lemma %.pos
	$(FACTOR_TOOL) --trace prepare_wsd --output $@ --before 0 --after 0 $^

%.wsd.output : %.wsd.context
	../../parallelize --output $@ --chunks=16 --granularity=2 -- ukb_wsd -D ../../wsd/$(L)/dict.txt -K ../../wsd/$(L)/rels.bin --ppr {$<}

%.wsd : %.wsd.output
	$(FACTOR_TOOL) --trace wsd_extract $(CORPUS) $< --output $@

$(LM) : train/$(CORPUS)
	ngram-count $(SRILM_OPTIONS) -text $< -lm $@

%.lm : %
	ngram-count $(SRILM_OPTIONS2) -text $< -lm $@

train/% : %
	$(SPLIT_CMD) $<

dev/% : %
	$(SPLIT_CMD) $<

test/% : %
	$(SPLIT_CMD) $<

lms : $(LMS)

clean-lms : 
	rm -rf $(LMS)

factored : $(PREFIX).factored.$(L) train/$(PREFIX).factored.$(L)
unfactored : train/$(PREFIX).$(L)

$(PREFIX).factored.$(L) : $(CORPUS).factored
	rm -f $@
	ln -s $< $@

all : lms factored unfactored 