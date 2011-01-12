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

# Arguments from environment
L1		?= da
L2		?= en
PREFIX		?= europarl.cleaned
#PREFIX		?= europarl.truncated
# LM_PREFIX may be used to specify a language model from a different corpus
LM_PREFIX	?= $(PREFIX)
#LM_PREFIX	?= europarl.cleaned

# Derived variables
PAIR 		= $(L1)-$(L2)
CORPUS_DIR 	= corpus/$(PAIR)
MODEL_DIR	= models/$(PAIR)
MODEL_BASE	= $(MODEL_DIR)/$(PREFIX)
CORPUS_MAKEFILE = $(CORPUS_DIR)/Makefile
UNFACTORED_TRAIN= $(CORPUS_DIR)/train/$(PREFIX)
UNFACTORED_DEV 	= $(CORPUS_DIR)/dev/$(PREFIX)
UNFACTORED_TEST	= $(CORPUS_DIR)/test/$(PREFIX)
FACTORED_TRAIN	= $(CORPUS_DIR)/train/$(PREFIX).factored
FACTORED_DEV 	= $(CORPUS_DIR)/dev/$(PREFIX).factored
FACTORED_TEST	= $(CORPUS_DIR)/test/$(PREFIX).factored
UNFACTORED_CORPORA = \
	$(UNFACTORED_TRAIN).$(L1) $(UNFACTORED_TRAIN).$(L2) \
	$(UNFACTORED_DEV).$(L1)   $(UNFACTORED_DEV).$(L2) \
	$(UNFACTORED_TEST).$(L1)  $(UNFACTORED_TEST).$(L2) 
FACTORED_CORPORA = \
	$(FACTORED_TRAIN).$(L1) $(FACTORED_TRAIN).$(L2) \
	$(FACTORED_DEV).$(L1)   $(FACTORED_DEV).$(L2) \
	$(FACTORED_TEST).$(L1)  $(FACTORED_TEST).$(L2)	

# Factors
form		= 0
lemma		= 1
pos		= 2
cluster		= 3
deprel		= 4
wsd		= 5
FACTORS 	= pos cluster deprel wsd lemma
FACTOR_MAX	= 5
# Moses
LM_SUFFIX	= qblm
LM_BASE 	= $(CORPUS_DIR)/train/$(LM_PREFIX).$(L2)
LM_PATH		= $(shell pwd)/$(LM_BASE)
LM_OPT_FACTORS	= $(foreach FACTOR, $(FACTORS), --lm $($(FACTOR)):3:$(LM_PATH).$(FACTOR).$(LM_SUFFIX))
FACTOR_LMS	= $(foreach FACTOR, $(FACTORS), $(LM_BASE).$(FACTOR).$(LM_SUFFIX))
MOSES 		= /usr/local/bin/moses
MOSES_OPTS	= --f $(L1) --e $(L2) --mgiza --mgiza-cpus 4 --lm $(form):3:$(LM_PATH).$(LM_SUFFIX) 
UNFACTORED_OPTS	= $(MOSES_OPTS) --corpus $(shell pwd)/$(UNFACTORED_TRAIN) 
FACTORED_OPTS 	= $(MOSES_OPTS) --corpus $(shell pwd)/$(FACTORED_TRAIN) --input-factor-max $(FACTOR_MAX)
FACTORED_DEPS	= $(FACTORED_CORPORA) $(LM_BASE).$(LM_SUFFIX) 
UNFACTORED_DEPS	= $(UNFACTORED_CORPORA) $(LM_BASE).$(LM_SUFFIX) 
TRAIN_CMD	= train-model.perl
CLEAN_MODEL_CMD	= rm -f $(dir $@)extract.gz $(dir $@)extract.inv.gz # rm -rf $(dir $@)
# Mert
MERT_OPTS 	= --mertdir=/opt/mosesdecoder/mert
MERT_CMD	= mert-moses.pl $(MERT_OPTS)
# Testing
FACTOR_CONFIGS 	= tb ts as.ts tb.alt tb.alt.gen
MODEL_CONFIGS 	= $(foreach FACTOR_CONFIG, $(FACTOR_CONFIGS), $(addprefix $(FACTOR_CONFIG)., $(FACTORS))) 
MODELS 		= unfactored $(MODEL_CONFIGS) combined # gen_cluster gen_cluster_deprel
MODEL_BASES 	= $(addprefix $(MODEL_BASE)., $(MODELS))
TESTS 		= $(addsuffix /model.test.out, $(MODEL_BASES)) # $(addsuffix /model.optimized.test.out, $(MODEL_BASES))
BLEUS 		= $(addsuffix .bleu, $(TESTS))
METEORS 	= $(addsuffix .meteor, $(TESTS))
# Logging
LOG_INIT_CMD	= mkdir -p $(dir $@)
LOG_CMD		= 2> $@.log >&2


.DELETE_ON_ERROR : # don't leave half-baked files around

.SECONDARY : # keep "intermediate" files (for reuse)

.PHONY: corpora all eval bleu meteor clean clean-optimized clean-eval

#
# Corpus stuff
#

corpora : $(CORPUS_MAKEFILE)
	cd $(CORPUS_DIR) && L=$(L1) PREFIX=$(LM_PREFIX) make all
	cd $(CORPUS_DIR) && L=$(L2) PREFIX=$(LM_PREFIX) make all

$(CORPUS_MAKEFILE) : $(CORPUS_DIR)
	rm -f $@
	cd $(CORPUS_DIR) && ln -s ../Makefile 

$(CORPUS_DIR)/train/%.$(L1).$(LM_SUFFIX) : 
	cd $(CORPUS_DIR) && L=$(L1) PREFIX=$(LM_PREFIX) LM_SUFFIX=$(LM_SUFFIX) make train/$*.$(L1).$(LM_SUFFIX) 

$(CORPUS_DIR)/train/%.$(L2).$(LM_SUFFIX) : 
	cd $(CORPUS_DIR) && L=$(L2) PREFIX=$(LM_PREFIX) LM_SUFFIX=$(LM_SUFFIX) make train/$*.$(L2).$(LM_SUFFIX) 

$(CORPUS_DIR)/$(PREFIX).$(L1).% : 
	cd $(CORPUS_DIR) && L=$(L1) PREFIX=$(PREFIX) LM_SUFFIX=$(LM_SUFFIX) make $(PREFIX).$(L1).$*

$(CORPUS_DIR)/$(PREFIX).$(L2).% : 
	cd $(CORPUS_DIR) && L=$(L2) PREFIX=$(PREFIX) LM_SUFFIX=$(LM_SUFFIX) make $(PREFIX).$(L2).$*

#
# Models 
#

$(MODEL_BASE).unfactored/model/moses.ini : $(UNFACTORED_DEPS) 
	$(CLEAN_MODEL_CMD) 
	$(LOG_INIT_CMD)
	$(TRAIN_CMD) --root-dir $(MODEL_BASE).unfactored $(UNFACTORED_OPTS) $(LOG_CMD)

# Generic rule for an additional translation factor on both sides
$(MODEL_BASE).tb.%/model/moses.ini : $(FACTORED_DEPS) $(LM_BASE).%.$(LM_SUFFIX)
	$(CLEAN_MODEL_CMD) 
	$(LOG_INIT_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) $(FACTORED_OPTS) --translation-factors $(form),$($*)-$(form),$($*) --lm $($*):3:$(LM_PATH).$*.$(LM_SUFFIX) $(LOG_CMD)

# Generic rule for an additional translation and alignment factor on the source side only
$(MODEL_BASE).as.ts.%/model/moses.ini : $(FACTORED_DEPS) 
	$(CLEAN_MODEL_CMD) 
	$(LOG_INIT_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) $(FACTORED_OPTS) --alignment-factors $(form),$($*)-$(form) --translation-factors $(form),$($*)-$(form) $(LOG_CMD)

# Generic rule for an additional translation factor on the source side only
$(MODEL_BASE).ts.%/model/moses.ini : $(FACTORED_DEPS) 
	$(CLEAN_MODEL_CMD) 
	$(LOG_INIT_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) $(FACTORED_OPTS) --translation-factors $(form),$($*)-$(form) $(LOG_CMD)

# An additional translation factor as an alternative decoding path
$(MODEL_BASE).tb.alt.%/model/moses.ini : $(FACTORED_DEPS) $(LM_BASE).%.$(LM_SUFFIX) 
	$(CLEAN_MODEL_CMD) 
	$(LOG_INIT_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) $(FACTORED_OPTS) --translation-factors $(form)-$(form),$($*)+$($*)-$(form),$($*) --lm $($*):3:$(LM_PATH).$*.$(LM_SUFFIX) --decoding-steps t0:t1 $(LOG_CMD)

# An additional translation factor as an alternative decoding path, with generation
$(MODEL_BASE).tb.alt.gen.%/model/moses.ini : $(FACTORED_DEPS) $(LM_BASE).%.$(LM_SUFFIX) 
	$(CLEAN_MODEL_CMD) 
	$(LOG_INIT_CMD)
	$(TRAIN_CMD) --root-dir $(subst /model/moses.ini,,$@) $(FACTORED_OPTS) --translation-factors $(form)-$(form)+$($*)-$($*) --lm $($*):3:$(LM_PATH).$*.$(LM_SUFFIX) --generation-factors $(form)-$($*) --decoding-steps t0,g0:t1 $(LOG_CMD) 

# Complex models
$(MODEL_BASE).combined/model/moses.ini : $(FACTORED_DEPS) $(FACTOR_LMS)
	$(CLEAN_MODEL_CMD) 
	$(LOG_INIT_CMD)
	$(TRAIN_CMD) --root-dir $(MODEL_BASE).combined $(FACTORED_OPTS) --translation-factors $(form),$(lemma),$(pos),$(cluster),$(deprel),$(wsd)-$(form),$(lemma),$(pos),$(cluster),$(deprel),$(wsd) $(LM_OPT_FACTORS) $(LOG_CMD)

$(MODEL_BASE).gen_cluster/model/moses.ini : $(FACTORED_DEPS) $(LM_BASE).cluster.$(LM_SUFFIX) 
	$(CLEAN_MODEL_CMD) 
	$(LOG_INIT_CMD)
	$(TRAIN_CMD) --root-dir $(MODEL_BASE).gen_cluster $(FACTORED_OPTS) --translation-factors $(form)-$(form)+$(cluster)-$(cluster) --generation-factors $(form)-$(cluster) --decoding-steps t0,g0,t1 $(LOG_CMD)

$(MODEL_BASE).gen_cluster_deprel/model/moses.ini : $(FACTORED_DEPS) $(LM_BASE).cluster.$(LM_SUFFIX) $(LM_BASE).deprel.$(LM_SUFFIX)
	$(CLEAN_MODEL_CMD) 
	$(LOG_INIT_CMD)
	$(TRAIN_CMD) --root-dir $(MODEL_BASE).gen_cluster_deprel $(FACTORED_OPTS) --translation-factors $(form)-$(form)+$(deprel),$(cluster)-$(deprel),$(cluster) --generation-factors $(form)-$(deprel),$(cluster) --decoding-steps t0,g0,t1 $(LOG_CMD)

baseline : unfactored_model

%_model : $(MODEL_BASE).%/model.optimized/moses.ini
	echo "Made optimized $* model"

#
# MERT
#
$(MODEL_BASE).unfactored/model.optimized/moses.ini : $(MODEL_BASE).unfactored/model/moses.ini
	$(CLEAN_MODEL_CMD) 
	$(LOG_INIT_CMD)
	$(MERT_CMD) --working-dir=$(MODEL_BASE).unfactored/model.optimized $(UNFACTORED_DEV).$(L1) $(UNFACTORED_DEV).$(L2) $(MOSES) $< $(LOG_CMD)

$(MODEL_BASE).%/model.optimized/moses.ini : $(MODEL_BASE).%/model/moses.ini
	$(CLEAN_MODEL_CMD) 
	$(LOG_INIT_CMD)
	$(MERT_CMD) --working-dir=$(MODEL_BASE).$*/model.optimized $(FACTORED_DEV).$(L1) $(FACTORED_DEV).$(L2) $(MOSES) $< $(LOG_CMD)

#
# Testing 
#
$(MODEL_BASE).unfactored/%.test.out : $(MODEL_BASE).unfactored/%/moses.ini 
	cat $(UNFACTORED_TEST).$(L1) | moses -f $< > $@ 2> $@.log

$(MODEL_BASE).%.test.out : $(MODEL_BASE).%/moses.ini 
	cat $(FACTORED_TEST).$(L1) | moses -f $< > $@ 2> $@.log

$(MODEL_BASE).%.test.out.bleu : $(MODEL_BASE).%.test.out
	cat $< | multi-bleu.perl $(UNFACTORED_TEST).$(L2) > $@ 2> $@.log

$(MODEL_BASE).%.test.out.meteor : $(MODEL_BASE).%.test.out
	java -XX:+UseCompressedOops -Xmx2G -jar /opt/meteor/meteor-1.2.jar $< $(UNFACTORED_TEST).$(L2) -l $(L2) > $@

bleu : $(BLEUS)
	tail $^

meteor : $(METEORS)
	tail $^

eval-all : bleu meteor

all : eval-all

clean-optimized : 
	rm -rf $(MODEL_BASE).*/model.optimized

clean-eval : 
	rm -rf $(MODEL_BASE).*/model*.out.bleu $(MODEL_BASE).*/model*.out.meteor

clean : 
	rm -rf $(MODEL_BASE).*

