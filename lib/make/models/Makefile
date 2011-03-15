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
include $(BASE)/common_rules.mk

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
FACTORED_DEPS	= random-sleep $(LM_BASE).$(BASE_FACTOR).$(L2).$(LM_SUFFIX) $(FACTORED_TRAIN).$(L1) $(FACTORED_TRAIN).$(L2) $(LM_BASE).%.$(L2).$(LM_SUFFIX)
UNFACTORED_DEPS	= random-sleep $(LM_BASE).$(BASE_FACTOR).$(L2).$(LM_SUFFIX) $(UNFACTORED_TRAIN).$(L1) $(UNFACTORED_TRAIN).$(L2) 

# Moses
BASE_LM_OPT	= --lm $($(BASE_FACTOR)):3:$(abspath $(LM_BASE).$(BASE_FACTOR).$(L2).$(LM_SUFFIX))
MOSES_OPTS	= --f $(L1) --e $(L2) --mgiza --mgiza-cpus 4 $(BASE_LM_OPT)
UNFACTORED_OPTS	= $(MOSES_OPTS) --corpus $(UNFACTORED_TRAIN)
FACTORED_OPTS 	= $(MOSES_OPTS) --corpus $(FACTORED_TRAIN) --input-factor-max $(FACTOR_MAX) 
TRAIN_CMD	= train-model.perl
PRE_TRAIN_CMD	= mkdir -p $(@D) && \
	cd $(dir $(@D)) && \
	ln -fs ../../../lib/make/model/Makefile . && \
	rm -f extract*.gz 

# Testing
FACTOR_CONFIGS 	= tb # ts ab # as.ts backoff f_pos.backoff # tb.alt.gen # tb.alt # 
MODEL_CONFIGS 	= $(foreach FACTOR_CONFIG, $(FACTOR_CONFIGS), $(addprefix $(FACTOR_CONFIG)., $(NONBASE_FACTORS))) 
MODEL_NAMES	= unfactored $(MODEL_CONFIGS) # combined # gen_cluster gen_cluster_deprel
MODEL_DIRS	= $(addprefix $(TRAIN_CORPUS)., $(MODEL_NAMES))
MODELS		= $(addsuffix /model/moses.ini, $(MODEL_DIRS)) 
BINARY_MODELS   = $(addsuffix /model/moses.binarized.ini, $(MODEL_DIRS)) 
OPTIMIZED_MODELS = $(addsuffix /model.optimized/moses.ini, $(MODEL_DIRS)) 
TESTS 		= $(addsuffix /model.test.out, $(MODEL_DIRS)) # $(addsuffix /model.optimized.test.out, $(MODELS))
BLEUS 		= $(addsuffix .bleu, $(TESTS))
METEORS 	= $(addsuffix .meteor, $(TESTS))

models : $(OPTIMIZED_MODELS)

%/model.optimized/moses.ini : %/model/moses.ini
	$(MAKE) -C $* model.optimized/moses.ini

# Shorthand

%-model : $(TRAIN_CORPUS).%/model/moses.ini
	echo "Made $* model"

# Training

$(TRAIN_CORPUS).unfactored/model/moses.ini : $(UNFACTORED_DEPS) 
	$(PRE_TRAIN_CMD)
	$(TRAIN_CMD) --root-dir $(TRAIN_CORPUS).unfactored \
		$(UNFACTORED_OPTS) \
		$(LOG_CMD)

# Generic rule for an additional translation factor on both sides
$(TRAIN_CORPUS).tb.%/model/moses.ini : $(FACTORED_DEPS) 
	$(PRE_TRAIN_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) \
		$(FACTORED_OPTS) \
		--translation-factors $($(BASE_FACTOR)),$($*)-$($(BASE_FACTOR)),$($*) \
		--lm $($*):3:$(abspath $(FACTOR_LM)) \
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
		--lm $($*):3:$(abspath $(FACTOR_LM)) \
		--lm $(pos):3:$(abspath $(LM_BASE).pos.$(LM_SUFFIX)) \
		--decoding-steps t0:t1 \
		$(LOG_CMD) 

# An additional translation factor as an alternative decoding path, with generation
$(TRAIN_CORPUS).tb.alt.gen.%/model/moses.ini : $(FACTORED_DEPS) $(LM_BASE).%.$(LM_SUFFIX) 
	$(PRE_TRAIN_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) \
		$(FACTORED_OPTS) \
		--translation-factors $($(BASE_FACTOR))-$($(BASE_FACTOR))+$($*)-$($*) \
		--lm $($*):3:$(abspath $(FACTOR_LM)) \
		--generation-factors $($(BASE_FACTOR))-$($*) \
		--decoding-steps t0,g0:t1 \
		$(LOG_CMD) 

# An additional translation factor as an alternative decoding path
$(TRAIN_CORPUS).tb.alt.%/model/moses.ini : $(FACTORED_DEPS) $(LM_BASE).%.$(LM_SUFFIX) 
	$(PRE_TRAIN_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) \
		$(FACTORED_OPTS) \
		--translation-factors $($(BASE_FACTOR))-$($(BASE_FACTOR)),$($*)+$($*)-$($(BASE_FACTOR)),$($*) \
		--lm $($*):3:$(abspath $(FACTOR_LM)) \
		--decoding-steps t0:t1 \
		$(LOG_CMD)

# Translate using a single factor (e.g. Brown clusters), then generate surface forms
$(TRAIN_CORPUS).gen.%/model/moses.ini : $(FACTORED_DEPS) $(LM_BASE).%.$(LM_SUFFIX) 
	$(PRE_TRAIN_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) \
		$(FACTORED_OPTS) \
		--translation-factors $($*)-$($*) \
		--generation-factors $($*)-$($(BASE_FACTOR)) \
		--lm $($*):3:$(abspath $(FACTOR_LM)) \
		$(LOG_CMD)

# Complex models
#$(TRAIN_CORPUS).combined/model/moses.ini : $(FACTORED_DEPS) $(FACTOR_LMS)
#	$(PRE_TRAIN_CMD)
#	$(TRAIN_CMD) --root-dir $(TRAIN_CORPUS).combined \
#		$(FACTORED_OPTS) \
#		--translation-factors $($(BASE_FACTOR)),$(lemma),$(pos),$(cluster),$(deprel),$(wsd)-$($(BASE_FACTOR)),$(lemma),$(pos),$(cluster),$(deprel),$(wsd) \
#		$(LM_OPT_FACTORS) \
#		$(LOG_CMD)
#
#$(TRAIN_CORPUS).gen_cluster/model/moses.ini : $(FACTORED_DEPS) $(LM_BASE).cluster.$(LM_SUFFIX) 
#	$(PRE_TRAIN_CMD)
#	$(TRAIN_CMD) --root-dir $(TRAIN_CORPUS).gen_cluster \
#		$(FACTORED_OPTS) \
#		--translation-factors $($(BASE_FACTOR))-$($(BASE_FACTOR))+$(cluster)-$(cluster) \
#		--generation-factors $($(BASE_FACTOR))-$(cluster) \
#		--decoding-steps t0,g0,t1 \
#		$(LOG_CMD)
#
#$(TRAIN_CORPUS).gen_cluster_deprel/model/moses.ini : $(FACTORED_DEPS) $(LM_BASE).cluster.$(LM_SUFFIX) $(LM_BASE).deprel.$(LM_SUFFIX)
#	$(PRE_TRAIN_CMD)
#	$(TRAIN_CMD) --root-dir $(TRAIN_CORPUS).gen_cluster_deprel \
#		$(FACTORED_OPTS) \
#		--translation-factors $($(BASE_FACTOR))-$($(BASE_FACTOR))+$(deprel),$(cluster)-$(deprel),$(cluster) \
#		--generation-factors $($(BASE_FACTOR))-$(deprel),$(cluster) \
#		--decoding-steps t0,g0,t1 \
#		$(LOG_CMD)

bleu : $(BLEUS)
	tail $^

meteor : $(METEORS)
	tail $^

eval-all : bleu meteor

clean-optimized : 
	rm -rf $(TRAIN_CORPUS).*/model.optimized

clean-eval : 
	rm -rf $(TRAIN_CORPUS).*/model*.out.bleu $(TRAIN_CORPUS).*/model*.out.meteor

clean : 
	rm -rf $(TRAIN_CORPUS).*

.PHONY:  eval bleu meteor clean clean-optimized clean-eval 
