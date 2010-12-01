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

# Derived variables
PAIR 		= $(L1)-$(L2)
CORPUS_DIR 	= corpus/$(PAIR)
MODEL_DIR	= models/$(PAIR)
PREFIX 		= $(CORPUS_DIR)/europarl.factored
LM_PREFIX 	= `pwd`/$(PREFIX).train.$(L2)
LM_OPT 		= --lm 0:3:$(LM_PREFIX).lm 
POS_LM_OPT 	= --lm 1:3:$(LM_PREFIX).pos.lm 
DEPREL_LM_OPT 	= --lm 2:3:$(LM_PREFIX).deprel.lm 
CLUSTER_LM_OPT 	= --lm 3:3:$(LM_PREFIX).cluster.lm 
MOSES 		= /usr/local/bin/moses
MOSES_OPTS 	= --corpus `pwd`/$(PREFIX).train --f $(L1) --e $(L2) --mgiza --mgiza-cpus 4 $(LM_OPT) --alignment-factors 0-0
MERT_OPTS 	= --mertdir=/opt/mosesdecoder/mert 
MERT_ARGS 	= $(PREFIX).dev.$(L1) $(PREFIX).dev.$(L2) $(MOSES) 

corpora : l1_corpus l2_corpus

l1_corpus : 
	cd $(CORPUS_DIR) ; L=$(L1) make

l2_corpus : 
	cd $(CORPUS_DIR) ; L=$(L2) make

baseline : unfactored_model

%_model : $(MODEL_DIR)/%/model/moses.ini
	echo $< # Bogus.. rule doesn't seem to work without a command??

.PHONY: corpora l1_corpus l2_corpus baseline unfactored_model

# Models 

$(MODEL_DIR)/unfactored/model/moses.ini : corpora 
	train-model.perl $(MOSES_OPTS) --root-dir $(MODEL_DIR)/unfactored 

$(MODEL_DIR)/gen_cluster/model/moses.ini : corpora
	train-model.perl $(MOSES_OPTS) --root-dir $(MODEL_DIR)/gen_cluster --translation-factors 0-0+3-3 --generation-factors 0-3 --decoding-steps t0,g0,t1 $(POS_LM_OPT) $(CLUSTER_LM_OPT)

$(MODEL_DIR)/pos/model/moses.ini : corpora
	train-model.perl $(MOSES_OPTS) --root-dir $(MODEL_DIR)/pos --translation-factors 0,1-0,1 --decoding-steps t0 $(POS_LM_OPT)

$(MODEL_DIR)/deprel/model/moses.ini : corpora
	train-model.perl $(MOSES_OPTS) --root-dir $(MODEL_DIR)/deprel --translation-factors 0,2-0,2 --decoding-steps t0 $(DEPREL_LM_OPT)

$(MODEL_DIR)/cluster/model/moses.ini : corpora
	train-model.perl $(MOSES_OPTS) --root-dir $(MODEL_DIR)/cluster --translation-factors 0,3-0,3 --decoding-steps t0 $(CLUSTER_LM_OPT)

$(MODEL_DIR)/combined/model/moses.ini : corpora
	train-model.perl $(MOSES_OPTS) --root-dir $(MODEL_DIR)/combined --translation-factors 0,1,2,3-0,1,2,3 --decoding-steps t0 $(POS_LM_OPT) $(DEPREL_LM_OPT) $(CLUSTER_LM_OPT)

$(MODEL_DIR)/gen_cluster-deprel/model/moses.ini : corpora
	train-model.perl $(MOSES_OPTS) --root-dir $(MODEL_DIR)/gen_cluster-deprel --translation-factors 0-0+2,3-2,3 --generation-factors 0-2,3 --decoding-steps t0,g0,t1 $(CLUSTER_LM_OPT) $(DEPREL_LM_OPT)

# MERT

$(OPTIMIZED_UNFACTORED_MODEL) : $(UNFACTORED_MODEL) corpora 
	mert-moses.pl $(MERT_OPTS) --working-dir=$(MODEL_DIR)/unfactored.optimized $(MERT_ARGS) $(MODEL_DIR)/unfactored/model/moses.ini

$(MODEL_DIR)/%/model.optimized/moses.ini : $(MODEL_DIR)/%/model/moses.ini
	echo `dirname $(input)







