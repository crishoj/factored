# 
# Makefile for factored MT corpora
# 
# OBJECTIVE: Let GNU's make handle the dependency chain for 
# constructing factored MT corpora, including updating files
# when their dependencies have been updated with newer versions.
#
# AUTHOR: crjensen@hum.ku.dk
#

BASE		= ../..
PAIR 		= $(shell basename $(CURDIR))
L		?= $(call substr,$(PAIR),1,2)
OL		?= $(call substr,$(PAIR),4,5)
include $(BASE)/lib/gmsl
include $(BASE)/standard_defs.mk
include $(BASE)/lib/make/common.mk

# Derived variables
DEPPARSE 	= ../../../stacked_dep/data/$(L)/europarl-$(PAIR)/mst2.out.conll

%.$(OL) : 
	L=$(OL) OL=$(L) $(MAKE) $@

# Fix for misnaming of Czech language files
$(BASE)/data/dev/%.cs.sgm  : $(BASE)/data/dev/%.cz.sgm 
	cd $(BASE)/data/dev && ln -s $< $@

dev/%.raw.$(L) : $(BASE)/data/dev/%-src.$(L).sgm 
	$(MOSES_SCRIPTS)/ems/support/input-from-sgm.perl < $< > $@

test/%.raw.$(L) : $(BASE)/data/test/%-src.$(L).sgm 
	$(MOSES_SCRIPTS)/ems/support/input-from-sgm.perl < $< > $@

train/wmt11.raw.$(L) : $(DATA)/training/*.$(PAIR).$(L) 
	cat $^ > $@

# Training data needs "cleaning" (filtering out long sentences)
$(TRAIN_CORPUS).clean.$(L) $(TRAIN_CORPUS).clean.$(OL) : %.token.$(L) %.token.$(OL)
	@echo "Sanity check:" && wc -l $^ | uniq
	clean-corpus-n.perl $*.token $(L) $(OL) $*.clean 1 40 $*.retained

$(TRAIN_CORPUS).lowercase.$(L) : $(TRAIN_CORPUS).clean.$(L)
	lowercase.perl < $< > $@

%.lowercase.$(L) : %.token.$(L)
	lowercase.perl < $< > $@

# POS and dependency relations from a dependency parse
%.pos.$(L) %.deprel.$(L) : $(DEPPARSE)
	$(FACTOR_TOOL) --trace conll_extract $< --output-pos $(PREFIX).pos --output-deprel $(PREFIX).deprel

# Factored
%.factored.$(L) : $(FACTOR_FILES)
	@echo "Sanity check:" && wc -l $^ | uniq
	$(FACTOR_TOOL) combine $^ --output $@

train : train/$(TRAIN_CORPUS).factored.$(L) train/$(TRAIN_CORPUS).factored.$(OL)
test : test/$(TEST_CORPUS).factored.$(L) test/$(TEST_CORPUS).factored.$(OL)
dev : dev/$(DEV_CORPUS).factored.$(L) dev/$(DEV_CORPUS).factored.$(OL)

all : dev test train

lms : $(LMS)

.PHONY : lms clean-lms factored unfactored dev train test

