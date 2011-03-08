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

include ../../standard_defs.mk
include ../../lib/gmsl

PWD 		= $(shell pwd)
PAIR 		= $(shell basename $(PWD))
L		?= $(call substr,$(PAIR),1,2)
OL		?= $(call substr,$(PAIR),4,5)

# Derived variables
DEPPARSE 	= ../../../stacked_dep/data/$(L)/europarl-$(PAIR)/mst2.out.conll

FACTOR_TOOL 	= ../../bin/factor
SPLIT		= ../../bin/split.sh

CSTLEMMA 	= /opt/cstlemma/cstlemma
CSTLEMMA_OPTS 	= -t- -b '$$w' -B '$$w' -c '$$b1[[$$b?]~1$$B]$$s' -f /opt/cstlemma/da/flexrules -d /opt/cstlemma/da/dict 

LEMMAGEN 	= /nyusers/anders/stemmers/v2/lemmagen/binary/linux/lemmatize
LEMMAGEN_OPTS 	= -f wpl

SRILM_OPTIONS 	= -order 3 -interpolate -kndiscount -unk 
SRILM_OPTIONS2 	= -order 3 -interpolate 

FACTOR_FILES	= $(foreach FACTOR, $(FACTORS), $(TRAIN_CORPUS).$(FACTOR).$(L))

MONO_DIR	= ../../data/training-monolingual

status :
	@echo L = $(L)
	@echo OL = $(OL)

%.$(OL) : 
	L=$(OL) OL=$(L) $(MAKE) $@

# Fix for misnaming of Czech language files
../../data/dev/%.cs.sgm  : ../../data/dev/%.cz.sgm 
	cd ../../data/dev && ln -s $< $@

dev/%.raw.$(L) : ../../data/dev/%.$(L).sgm 
	mkdir -p dev
	$(MOSES_SCRIPTS)/ems/support/input-from-sgm.perl < $< > $@

test/%.raw.$(L) : ../../data/dev/%.$(L).sgm 
	mkdir -p test
	$(MOSES_SCRIPTS)/ems/support/input-from-sgm.perl < $< > $@

$(MONO_DIR)/all.raw.$(L) : $(MONO_DIR)/europarl-v6.$(L) $(MONO_DIR)/news-commentary-v6.$(L) # $(wildcard $(MONO_DIR)/news.*.$(L).shuffled) 
	cat $^ > $@

%.token.$(L) : %.raw.$(L)
	tokenizer.perl -l $(L) < $< > $@

%.clean.$(L) %.clean.$(OL) : %.token.$(L) %.token.$(OL)
	clean-corpus-n.perl $*.token $(L) $(OL) $*.clean 1 40

# We don't need to clean the monolingual data
$(MONO_DIR)/%.lowercase.$(L) : $(MONO_DIR)/%.token.$(L)
	lowercase.perl < $< > $@

%.lowercase.$(L) : %.clean.$(L)
	lowercase.perl < $< > $@

%.lemma.da : %.lowercase.da 
	$(CSTLEMMA) $(CSTLEMMA_OPTS) -i $< -o $@

%.lemma.$(L) : %.$(L).lemmatize.out
	 $(FACTOR_TOOL) --trace col_to_spl --col 2 --fallback 1 $< --output $@

%.cs.lemmatize.out : /opt/lemmagen/lem-me-cs.bin %.lowercase.cs.wpl 
	rm -f $@
	$(LEMMAGEN) $(LEMMAGEN_OPTS) -l $^ $@ $(LOG_CMD)

%.es.lemmatize.out : /opt/lemmagen/lem-m-sp.bin %.lowercase.es.wpl 
	rm -f $@
	$(LEMMAGEN) $(LEMMAGEN_OPTS) -l $^ $@ $(LOG_CMD)

%.en.lemmatize.out : /opt/lemmagen/lem-me-en.bin %.lowercase.en.wpl 
	rm -f $@
	$(LEMMAGEN) $(LEMMAGEN_OPTS) -l $^ $@ $(LOG_CMD)

%.fr.lemmatize.out : /opt/lemmagen/lem-me-fr.bin %.lowercase.fr.wpl 
	rm -f $@
	$(LEMMAGEN) $(LEMMAGEN_OPTS) -l $^ $@ $(LOG_CMD)

%.de.lemmatize.out : /opt/lemmagen/lem-m-ge.bin %.lowercase.de.wpl
	rm -f $@
	$(LEMMAGEN) $(LEMMAGEN_OPTS) -l $^ $@ $(LOG_CMD)

%.wpl : %
	$(FACTOR_TOOL) --trace spl_to_wpl $< --output $@

%.pos.$(L) %.deprel.$(L) : $(DEPPARSE)
	$(FACTOR_TOOL) --trace conll_extract $< --output-pos $(PREFIX).pos --output-deprel $(PREFIX).deprel

$(MONO_DIR)/clusters/$(L)/$(MONO_CORPUS)-c320-p1.out/paths : $(MONO_DIR)/$(MONO_CORPUS).lowercase.$(L)
	mkdir -p $(MONO_DIR)/clusters/$(L)
	cd $(MONO_DIR)/clusters/$(L) && ln -fs ../../$(MONO_CORPUS).lowercase.$(L) $(MONO_CORPUS).$(L) 
	cd $(MONO_DIR)/clusters/$(L) && wcluster --text $(MONO_CORPUS).$(L) --c 320 --ms-per-line 1000

%.cluster.$(L) : %.lowercase.$(L) 
	mkdir -p $(MONO_DIR)/clusters
	lockfile $(MONO_DIR)/clusters/$(L).lock # hack to prevent concurrent sub-makes to make the same clusters simultaneously
	$(MAKE)	$(MONO_DIR)/clusters/$(L)/$(MONO_CORPUS)-c320-p1.out/paths
	$(FACTOR_TOOL) cluster_extract --output $@ $^
	rm -f lockfile $(MONO_DIR)/clusters/$(L).lock

%.factored.$(L) : $(foreach FACTOR, $(FACTORS), %.$(FACTOR).$(L))
	$(FACTOR_TOOL) combine $^ --output $@

%.wsd.context.$(L) : %.lemma.$(L) %.pos.$(L)
	$(FACTOR_TOOL) --trace prepare_wsd --output $@ --before 0 --after 0 $^

%.wsd.output.$(L) : %.wsd.context.$(L)
	../../parallelize --output $@ --chunks=16 --granularity=2 --nice=10 -- ukb_wsd -D ../../wsd/$(L)/dict.txt -K ../../wsd/$(L)/rels.bin --ppr {$<}

%.wsd.$(L) : %.lemma.$(L) %.wsd.output.$(L)
	$(FACTOR_TOOL) --trace wsd_extract $^ --output $@

# Binary LM for memory mapping with KenLM
%.kblm : %.lm
	build_binary $< $@

%.lm : %
	ngram-count $(SRILM_OPTIONS2) -text $< -lm $@

#train/%.$(L) : %.$(L)
#	$(SPLIT) $(DEV_SENTS) $(TEST_SENTS) $<
#
#dev/% : %
#	$(SPLIT) $(DEV_SENTS) $(TEST_SENTS) $<
#
#test/% : %
#	$(SPLIT) $(DEV_SENTS) $(TEST_SENTS) $<

dev : dev/$(DEV_CORPUS).factored.$(L)

all : test/$(DEV_CORPUS).factored.$(L) test/$(DEV_CORPUS).factored.$(OL)

lms : $(LMS)

.PHONY : lms clean-lms factored unfactored dev train test

