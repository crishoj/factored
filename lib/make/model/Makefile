# 
# Makefile for a factored MT model
# 
# Handles model binarization, etc.
#
# OBJECTIVE: Let GNU's make handle the dependency chain for 
# constructing factored MT models, including updating files
# when their dependencies have been updated with newer versions.
#
# AUTHOR: crjensen@hum.ku.dk
#

BASE		:= ../../..
include $(BASE)/lib/gmsl
PAIR 		:= $(subst $(abspath ../..)/,,$(abspath ..))
L1		:= $(call substr,$(PAIR),1,2)
L2		:= $(call substr,$(PAIR),4,5)
MODEL_NAME	:= $(subst $(abspath ..)/,,$(abspath .))
ifneq (,$(findstring unfactored,$(MODEL_NAME)))
DEV		?= $(CORPUS_DIR)/dev/$(DEV_CORPUS).$(BASE_FACTOR)
TEST		?= $(CORPUS_DIR)/test/$(TEST_CORPUS).$(BASE_FACTOR)
else
DEV		?= $(CORPUS_DIR)/dev/$(DEV_CORPUS).factored
TEST		?= $(CORPUS_DIR)/test/$(TEST_CORPUS).factored
endif
include $(BASE)/standard_defs.mk
include $(BASE)/lib/make/common.mk

REFERENCE	= $(CORPUS_DIR)/test/$(TEST_CORPUS).$(BASE_FACTOR).$(L2)

# Mert
MERT_OPTS 	= --mertdir=$(MERT_DIR)
MERT_CMD	= mert-moses.pl $(MERT_OPTS)
FILTER_CMD	= $(MOSES_SCRIPTS)/training/filter-model-given-input.pl -Binarizer processPhraseTable

submission : $(TEST_CORPUS).optimized.out.sgm 
	echo "Made $^"

eval : $(TEST_CORPUS).optimized.out.bleu $(TEST_CORPUS).optimized.oracle.out.bleu
	head $^
	
sgm-eval : $(TEST_CORPUS).optimized.out.sgm.bleu 
	head $^

#
# Binarization
#
model/moses.binarized.ini : model/moses.ini 
	cp $< $@
	perl -i'.bak' -pe 's/0 (\d \d \D.+lm)/9 \1/g' $@ # use binary KenLM language models

model/phrase-tab%.binphr.idx : model/phrase-tab%.gz
	zcat $< | processPhraseTable -ttable 0 0 - -nscores 5 -out $(subst .binphr.idx,,$@)

#
# Optimization
#
model.optimized/moses.ini : model/moses.binarized.ini $(DEV).$(L1) $(DEV).$(L2)
	mkdir -p $(@D)
	rm -rf $(@D)/filtered
	$(MERT_CMD) --working-dir=model.optimized --filtercmd="$(FILTER_CMD)" $(DEV).$(L1) $(DEV).$(L2) $(MOSES) $< $(LOG_CMD)

#
# Filtering
#
%.filtered_for_$(TEST_CORPUS)/moses.ini : %/moses.ini $(TEST).$(L1)
	rm -rf $(@D)
	filter-model-given-input.pl $(@D) $^ -Binarizer processPhraseTable 2> $(@D).log >&2

#
# Testing
#
$(TEST_CORPUS).default.out : model.filtered_for_$(TEST_CORPUS)/moses.ini $(TEST).$(L1) 
	moses -f $< < $(TEST).$(L1) > $@ 2> $@.log

$(TEST_CORPUS).optimized.out : model.optimized.filtered_for_$(TEST_CORPUS)/moses.ini $(TEST).$(L1) 
	moses -f $< < $(TEST).$(L1) > $@ 2> $@.log

%.default.out.sgm : $(DATA)/test/%-src.$(L2).sgm %.default.out.recased.detokenized.normalized
	$(BASE)/scripts/wrap-xml.perl $(L2) $< $(MODEL_NAME) < $*.default.out.recased.detokenized.normalized > $@

%.optimized.out.sgm : $(DATA)/test/%-src.$(L2).sgm %.optimized.out.recased.detokenized.normalized
	$(BASE)/scripts/wrap-xml.perl $(L2) $< $(MODEL_NAME) < $*.optimized.out.recased.detokenized.normalized > $@

%.normalized : %
	$(BASE)/scripts/normalize-punctuation.perl $(L2) < $< > $@

%.detokenized : %
	$(MOSES_SCRIPTS)/tokenizer/detokenizer.perl -l $(L2) < $< > $@

%.recased : %
	$(MOSES_SCRIPTS)/recaser/recase.perl -model $(BASE)/recasers/$(L2)/moses.ini -in $< -moses $(MOSES) > $@

#
# Evaluation
#
$(TEST_CORPUS).%.out.sgm.bleu : $(TEST_CORPUS).%.out.sgm
	$(MTEVAL) -r $(DATA)/test/$(TEST_CORPUS)-src.$(L2).sgm -s $(DATA)/test/$(TEST_CORPUS)-src.$(L1).sgm -t $< -c -b

$(TEST_CORPUS).%.out.bleu : $(TEST_CORPUS).%.out
	$(MULTI_BLEU) $(REFERENCE) < $< > $@ 

$(TEST_CORPUS).%.oracle.out : $(TEST_CORPUS).%.out ../$(TRAIN_CORPUS).unfactored/$(TEST_CORPUS).%.out 
	$(BASE)/bin/smt oracle --trace --multi-bleu $(MULTI_BLEU) --reference $(REFERENCE) $^ > $@

%.test.out.meteor : %.test.out
	java -XX:+UseCompressedOops -Xmx2G -jar /opt/meteor/meteor-1.2.jar $< $(TEST).$(L2) -l $(L2) > $@
