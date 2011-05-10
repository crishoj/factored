# 
# Makefile for factored MT models
# 
# OBJECTIVE: Let GNU's make handle the dependency chain for 
# constructing factored MT models, including updating files
# when their dependencies have been updated with newer versions.
#
# AUTHOR: crjensen@hum.ku.dk
#

BASE		:= ../..
include $(BASE)/lib/gmsl
PAIR 		:= $(shell basename $(CURDIR))
L1		:= $(call substr,$(PAIR),1,2)
L2		:= $(call substr,$(PAIR),4,5)
include $(BASE)/standard_defs.mk
include $(BASE)/lib/make/common.mk

# Corpora
UNFACTORED_TRAIN= $(CORPUS_DIR)/train/$(TRAIN_CORPUS).$(BASE_FACTOR)
UNFACTORED_DEV 	= $(CORPUS_DIR)/dev/$(DEV_CORPUS).$(BASE_FACTOR)
UNFACTORED_TEST	= $(CORPUS_DIR)/test/$(TEST_CORPUS).$(BASE_FACTOR)
FACTORED_TRAIN	= $(CORPUS_DIR)/train/$(TRAIN_CORPUS).factored
FACTORED_DEV 	= $(CORPUS_DIR)/dev/$(DEV_CORPUS).factored
FACTORED_TEST	= $(CORPUS_DIR)/test/$(TEST_CORPUS).factored
UNFACTORED_CORPORA = \
	$(UNFACTORED_TRAIN).$(L1) $(UNFACTORED_TRAIN).$(L2) \
	$(UNFACTORED_DEV).$(L1)   $(UNFACTORED_DEV).$(L2) \
	$(UNFACTORED_TEST).$(L1)  $(UNFACTORED_TEST).$(L2) 
FACTORED_CORPORA = \
	$(FACTORED_TRAIN).$(L1) $(FACTORED_TRAIN).$(L2) \
	$(FACTORED_DEV).$(L1)   $(FACTORED_DEV).$(L2) \
	$(FACTORED_TEST).$(L1)  $(FACTORED_TEST).$(L2)	
FACTOR_LM	= $(LM_BASE).$*.$(L2).$(LM_SUFFIX)
FACTORED_DEPS	= $(LM_BASE).$(BASE_FACTOR).$(L2).$(LM_SUFFIX) $(FACTORED_TRAIN).$(L1) $(FACTORED_TRAIN).$(L2) $(LM_BASE).%.$(L2).$(LM_SUFFIX)
UNFACTORED_DEPS	= $(LM_BASE).$(BASE_FACTOR).$(L2).$(LM_SUFFIX) $(UNFACTORED_TRAIN).$(L1) $(UNFACTORED_TRAIN).$(L2) 

# Moses
BASE_LM_OPT	= -lm $($(BASE_FACTOR)):$(LM_ORDER):$(abspath $(LM_BASE).$(BASE_FACTOR).$(L2).$(LM_SUFFIX))
MOSES_OPTS	= -f $(L1) -e $(L2) -alignment grow-diag-final-and -reordering msd-bidirectional-fe $(BASE_LM_OPT) 
UNFACTORED_OPTS	= $(MOSES_OPTS) -corpus $(UNFACTORED_TRAIN)
FACTORED_OPTS 	= $(MOSES_OPTS) -corpus $(FACTORED_TRAIN) -input-factor-max $(FACTOR_MAX) 
TRAIN_CMD	= train-model.perl
PRE_TRAIN_CMD	= rm -rf $(dir $(@D)) && mkdir -p $(@D) && cd $(dir $(@D)) && \
	ln -fs ../../../lib/make/model/Makefile . 

# Testing
MODEL_CONFIGS 	= $(foreach FACTOR_CONFIG, $(FACTOR_CONFIGS), $(addprefix $(FACTOR_CONFIG)., $(ENABLED_FACTORS))) 
MODEL_NAMES	= unfactored $(MODEL_CONFIGS) # combined # gen_cluster gen_cluster_deprel
MODEL_DIRS	= $(addprefix $(TRAIN_CORPUS)., $(MODEL_NAMES))
MODELS		= $(addsuffix /model/moses.ini, $(MODEL_DIRS)) 
BINARY_MODELS   = $(addsuffix /model/moses.binarized.ini, $(MODEL_DIRS)) 
OPTIMIZED_MODELS = $(addsuffix /model.optimized/moses.ini, $(MODEL_DIRS)) 
TESTS 		= $(addsuffix /model.test.out, $(MODEL_DIRS)) # $(addsuffix /model.optimized.test.out, $(MODELS))
BLEUS 		= $(addsuffix .bleu, $(TESTS))
METEORS 	= $(addsuffix .meteor, $(TESTS))

.PHONY : models

models : $(OPTIMIZED_MODELS)

%/model.optimized/moses.ini : %/model/moses.ini
	$(MAKE) -C $* model.optimized/moses.ini

submissions : $(foreach MODEL_NAME, $(MODEL_NAMES), $(MODEL_NAME)-submission)

evals : $(foreach MODEL_NAME, $(MODEL_NAMES), $(MODEL_NAME)-eval)
	
# Oracle testing 

oracle : $(TEST_CORPUS).combined-oracle.out.bleu
	head $<

$(TEST_CORPUS).combined-oracle.out : $(addsuffix /$(TEST_CORPUS).optimized.out, $(MODEL_DIRS)) 
	$(BASE)/bin/smt oracle --trace --multi-bleu $(MULTI_BLEU) --reference $(CORPUS_DIR)/test/$(TEST_CORPUS).$(BASE_FACTOR).$(L2) $^ > $@

$(TEST_CORPUS).combined-oracle.out.bleu : $(TEST_CORPUS).combined-oracle.out
	$(MULTI_BLEU) $(CORPUS_DIR)/test/$(TEST_CORPUS).$(BASE_FACTOR).$(L2) < $< > $@ 

# Shorthand

%-model : $(TRAIN_CORPUS).%/model/moses.ini
	echo "Made $* model"

%-submission : 
	$(MAKE) -C $(TRAIN_CORPUS).$* submission

%-eval : 
	$(MAKE) -C $(TRAIN_CORPUS).$* eval

# Training

$(TRAIN_CORPUS).unfactored/model/moses.ini : $(UNFACTORED_DEPS) 
	$(PRE_TRAIN_CMD)
	$(TRAIN_CMD) --root-dir $(TRAIN_CORPUS).unfactored \
		$(UNFACTORED_OPTS) \
		$(LOG_CMD)

# Alignment using only the given factor
$(TRAIN_CORPUS).ao.%/model/moses.ini : $(FACTORED_DEPS) 
	$(PRE_TRAIN_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) \
		$(FACTORED_OPTS) \
		--alignment-factors $($*)-$($*) \
		$(LOG_CMD)

# Alternative FACTOR-FORM decoding path
$(TRAIN_CORPUS).alt.%/model/moses.ini : $(FACTORED_DEPS) 
	$(PRE_TRAIN_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) \
		$(FACTORED_OPTS) \
		--translation-factors $($(BASE_FACTOR))-$($(BASE_FACTOR))+$($*)-$($(BASE_FACTOR)) \
		--decoding-steps t0:t1 \
		$(LOG_CMD)

# Generic rule for an additional translation factor on both sides
$(TRAIN_CORPUS).tb.%/model/moses.ini : $(FACTORED_DEPS) 
	$(PRE_TRAIN_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) \
		$(FACTORED_OPTS) \
		--translation-factors $($(BASE_FACTOR)),$($*)-$($(BASE_FACTOR)),$($*) \
		--lm $($*):$(LM_ORDER):$(abspath $(FACTOR_LM)) \
		$(LOG_CMD)

# Generic rule for an additional translation and alignment factor on the source side only
$(TRAIN_CORPUS).as.ts.%/model/moses.ini : $(FACTORED_DEPS) 
	$(PRE_TRAIN_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) \
		$(FACTORED_OPTS) \
		--alignment-factors $($(BASE_FACTOR)),$($*)-$($(BASE_FACTOR)) \
		--translation-factors $($(BASE_FACTOR)),$($*)-$($(BASE_FACTOR)) \
		$(LOG_CMD)

# Generic rule for an additional translation factor on the source side only
$(TRAIN_CORPUS).ts.%/model/moses.ini : $(FACTORED_DEPS) 
	$(PRE_TRAIN_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) \
		$(FACTORED_OPTS) \
		--translation-factors $($(BASE_FACTOR)),$($*)-$($(BASE_FACTOR)) \
		$(LOG_CMD)

# Alignment factor (both sides)
$(TRAIN_CORPUS).ab.%/model/moses.ini : $(FACTORED_DEPS) 
	$(PRE_TRAIN_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) \
		$(FACTORED_OPTS) \
		--alignment-factors $($(BASE_FACTOR)),$($*)-$($(BASE_FACTOR)),$($*) \
		--translation-factors $($(BASE_FACTOR))-$($(BASE_FACTOR)) \
		$(LOG_CMD)

# A strategy for translating surface forms which have not been seen in the training corpus: Backoff to another factor
$(TRAIN_CORPUS).backoff.%/model/moses.ini : $(FACTORED_DEPS) 
	$(PRE_TRAIN_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) \
		$(FACTORED_OPTS) \
		--translation-factors $($(BASE_FACTOR))-$($(BASE_FACTOR))+$($*)-$($(BASE_FACTOR)) \
		--decoding-steps t0:t1 \
		$(LOG_CMD) 

# A strategy for translating surface forms which have not been seen in the training corpus: Backoff to another factor (with POS)
$(TRAIN_CORPUS).f_pos.backoff.%/model/moses.ini : $(FACTORED_DEPS) $(LM_BASE).pos.$(LM_SUFFIX) 
	$(PRE_TRAIN_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) \
		$(FACTORED_OPTS) \
		--translation-factors $($(BASE_FACTOR))-$($(BASE_FACTOR)),$(pos)+$($*)-$($(BASE_FACTOR)),$(pos) \
		--lm $($*):$(LM_ORDER):$(abspath $(FACTOR_LM)) \
		--lm $(pos):$(LM_ORDER):$(abspath $(LM_BASE).pos.$(LM_SUFFIX)) \
		--decoding-steps t0:t1 \
		$(LOG_CMD) 
