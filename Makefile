# Makefile for factored MT experiments
# 
# OBJECTIVE: Let GNU's make handle the dependency chain for 
# constructing and runnings experiments on factored MT corpora, 
# including updating files when their dependencies have been
# updated with newer versions.
#
# AUTHOR: crjensen@hum.ku.dk
#
# NOTE: Expects environment variables L1 and L2 to contain 
# source and target language codes, repectively.
#

BASE		= .
include standard_defs.mk
include lib/gmsl

#
# Corpus stuff
#

.PHONY: all 

all : lms corpora models recasers
lms : $(foreach LANG, $(LANGS), $(LANG)-lm)
embeds : $(foreach LANG, $(LANGS), $(LANG)-embed)
corpora : $(foreach PAIR, $(PAIRS), $(PAIR)-corpus)
recasers : $(foreach LANG, $(LANGS), $(LANG)-recaser)
models : $(foreach PAIR, $(PAIRS), $(PAIR)-models)
model-dirs : $(foreach PAIR, $(PAIRS), models/$(PAIR))
submissions : $(foreach PAIR, $(PAIRS), $(PAIR)-submissions)

%-lm : 
	L=$* $(MAKE) -C $(MONO) lms

%-embed : 
	L=$* $(MAKE) -C $(MONO) all.lowercase-embedding

%-recaser : $(MONO)/$(MONO_CORPUS).token.%
	mkdir -p recasers/$*
	$(MOSES_SCRIPTS)/recaser/train-recaser.perl \
		-train-script $(MOSES_SCRIPTS)/training/train-model.perl \
		-ngram-count $(NGRAM_COUNT) \
		-corpus $< \
		-dir $(abspath recasers/$*)

reverse-corpus : corpus
	cd corpus && ln -s $(L1)-$(L2) $(L2)-$(L1) 

%-corpus : corpus/% 
	$(MAKE) -C corpus/$* all

corpus/% : 
	mkdir -p $@/test
	mkdir -p $@/dev
	mkdir -p $@/train
	cd $@ && ln -s ../../data/training-monolingual monolingual
	cd $@ && ln -s ../Makefile .

$(CORPUS_DIR)/%.$(L1) : 
	L=$(L1) OL=$(L2) $(MAKE) -C $(CORPUS_DIR) $(subst $(CORPUS_DIR)/,,$@)

$(CORPUS_DIR)/%.$(L2) : 
	L=$(L2) OL=$(L1) $(MAKE) -C $(CORPUS_DIR) $(subst $(CORPUS_DIR)/,,$@)

%-models : models/% %-corpus
	$(MAKE) -C models/$* models

models/% : 
	mkdir -p $@
	cd $@ && ln -s ../Makefile .

%-submissions : %-models
	$(MAKE) -C models/$* submissions




