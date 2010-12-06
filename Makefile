# 
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
LM_PREFIX	?= $(PREFIX) # for using a language model from a differentcorpus

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
# Factors
FORM		= 0
LEMMA		= 1
POS		= 2
CLUSTER		= 3
DEPREL		= 4
WSD		= 5
# Moses
FACTOR_MAX	= 5
LM_BASE 	= `pwd`/$(CORPUS_DIR)/train/$(LM_PREFIX).$(L2)
LM_OPT		= --lm $(FORM):3:$(LM_BASE).lm 
LM_OPT_LEMMA	= --lm $(LEMMA):3:$(LM_BASE).lemma.lm 
LM_OPT_POS	= --lm $(POS):3:$(LM_BASE).pos.lm 
LM_OPT_CLUSTER	= --lm $(CLUSTER):3:$(LM_BASE).cluster.lm 
LM_OPT_DEPREL	= --lm $(DEPREL):3:$(LM_BASE).deprel.lm 
LM_OPT_WSD	= --lm $(WSD):3:$(LM_BASE).wsd.lm 
MOSES 		= /usr/local/bin/moses
MOSES_OPTS	= --f $(L1) --e $(L2) --mgiza --mgiza-cpus 4 --lm $(FORM):3:$(LM_BASE).lm --alignment-factors 0-0
UNFACTORED_OPTS	= $(MOSES_OPTS) --corpus `pwd`/$(UNFACTORED_TRAIN) 
FACTORED_OPTS 	= $(MOSES_OPTS) --corpus `pwd`/$(FACTORED_TRAIN) --input-factor-max $(FACTOR_MAX)
# Mert 
MERT_OPTS 	= --mertdir=/opt/mosesdecoder/mert 

.DELETE_ON_ERROR : # don't leave half-baked files around

.SECONDARY : # keep "intermediate" files (for reuse)

.PHONY: corpora l1_corpus l2_corpus baseline models

corpora : # l1_corpus l2_corpus

l1_corpus : $(CORPUS_MAKEFILE)
	cd $(CORPUS_DIR) ; L=$(L1) make factored lms

l2_corpus : $(CORPUS_MAKEFILE)
	cd $(CORPUS_DIR) ; L=$(L2) make factored lms

$(CORPUS_MAKEFILE) : $(CORPUS_DIR)
	rm -f $@
	cd $(CORPUS_DIR) && ln -s ../Makefile 

baseline : optimized_unfactored_model

%_model : $(MODEL_BASE).%/model/moses.ini
	echo "Made $* model"

optimized_%_model : $(MODEL_BASE).%/model.optimized/moses.ini
	echo "Made optimized $* model"

#
# Models 
#

$(MODEL_BASE).unfactored/model/moses.ini : # corpora -- always remakes when specifying phony dependency here?
	train-model.perl $(UNFACTORED_OPTS) --root-dir $(MODEL_BASE).unfactored 

$(MODEL_BASE).lemma/model/moses.ini : 
	train-model.perl $(FACTORED_OPTS) --root-dir $(MODEL_BASE).lemma   --translation-factors $(FORM),$(LEMMA)-$(FORM),$(LEMMA) $(LM_OPT_LEMMA)

$(MODEL_BASE).pos/model/moses.ini : 
	train-model.perl $(FACTORED_OPTS) --root-dir $(MODEL_BASE).pos     --translation-factors $(FORM),$(POS)-$(FORM),$(POS) $(LM_OPT_POS)

$(MODEL_BASE).cluster/model/moses.ini : 
	train-model.perl $(FACTORED_OPTS) --root-dir $(MODEL_BASE).cluster --translation-factors $(FORM),$(CLUSTER)-$(FORM),$(CLUSTER) $(LM_OPT_CLUSTER)

$(MODEL_BASE).deprel/model/moses.ini : 
	train-model.perl $(FACTORED_OPTS) --root-dir $(MODEL_BASE).deprel  --translation-factors $(FORM),$(DEPREL)-$(FORM),$(DEPREL) $(LM_OPT_DEPREL)

$(MODEL_BASE).wsd/model/moses.ini : 
	train-model.perl $(FACTORED_OPTS) --root-dir $(MODEL_BASE).wsd  --translation-factors $(FORM),$(WSD)-$(FORM),$(WSD) $(LM_OPT_WSD)

$(MODEL_BASE).combined/model/moses.ini : 
	train-model.perl $(FACTORED_OPTS) --root-dir $(MODEL_BASE).combined --translation-factors $(FORM),$(LEMMA),$(POS),$(CLUSTER),$(DEPREL),$(WSD)-$(FORM),$(LEMMA),$(POS),$(CLUSTER),$(DEPREL),$(WSD) $(LM_OPT_LEMMA) $(LM_OPT_POS) $(LM_OPT_CLUSTER) $(LM_OPT_DEPREL) $(LM_OPT_WSD)

$(MODEL_BASE).gen_cluster/model/moses.ini : 
	train-model.perl $(FACTORED_OPTS) --root-dir $(MODEL_BASE).gen_cluster --translation-factors $(FORM)-$(FORM)+$(CLUSTER)-$(CLUSTER) --generation-factors $(FORM)-$(CLUSTER) --decoding-steps t0,g0,t1 

$(MODEL_BASE).gen_cluster-deprel/model/moses.ini : 
	train-model.perl $(FACTORED_OPTS) --root-dir $(MODEL_BASE).gen_cluster-deprel --translation-factors $(FORM)-$(FORM)+$(DEPREL),$(CLUSTER)-$(DEPREL),$(CLUSTER) --generation-factors $(FORM)-$(DEPREL),$(CLUSTER) --decoding-steps t0,g0,t1 

MODELS = unfactored lemma pos cluster deprel wsd combined gen_cluster gen_cluster-deprel
UNOPTIMIZED_MODELS = $(addsuffix _model, $(MODELS))
OPTIMIZED_MODELS = $(addprefix optimized_, $(UNOPTIMIZED_MODELS))

unoptimized_models : $(UNOPTIMIZED_MODELS)

optimized_models : $(OPTIMIZED_MODELS)

models : $(OPTIMIZED_MODELS)

# MERT

$(MODEL_BASE).unfactored/model.optimized/moses.ini : $(MODEL_BASE).unfactored/model/moses.ini
	mert-moses.pl $(MERT_OPTS) --working-dir=$(MODEL_BASE).unfactored/model.optimized $(UNFACTORED_DEV).$(L1) $(UNFACTORED_DEV).$(L2) $(MOSES) $<

$(MODEL_BASE).%/model.optimized/moses.ini : $(MODEL_BASE).%/model/moses.ini
	mert-moses.pl $(MERT_OPTS) --working-dir=$(MODEL_BASE).$*/model.optimized $(FACTORED_DEV).$(L1) $(FACTORED_DEV).$(L2) $(MOSES) $<







