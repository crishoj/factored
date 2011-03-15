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
include $(BASE)/common_rules.mk

# Mert
MERT_OPTS 	= --mertdir=$(MERT_DIR)
MERT_CMD	= mert-moses.pl $(MERT_OPTS)

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
	$(MERT_CMD) --working-dir=model.optimized $(DEV).$(L1) $(DEV).$(L2) $(MOSES) $< $(LOG_CMD)

#
# Filtering
#
model.filtered.$(TEST_CORPUS)/moses.ini : model.optimized/moses.ini $(TEST).$(L1)
	filter-model-given-input.pl $(@D) $^ -Binarizer processPhraseTable 2> $(@D).log >&2

#
# Testing
#
$(TEST_CORPUS).out : model.filtered.$(TEST_CORPUS)/moses.ini $(TEST).$(L1) 
	moses -f $< < $(TEST).$(L1) > $@ 2> $@.log

submission : $(TEST_CORPUS).out.sgm $(TEST_CORPUS).out.sgm.bleu
	echo "Made $^"

%.out.sgm : $(DATA)/*/%-src.$(L2).sgm %.out.recased.detokenized
	$(BASE)/scripts/wrap-xml.perl $< $(L2) $(basename $(@D)) < $*.out.recased.detokenized > $@

%.detokenized : %
	$(MOSES_SCRIPTS)/tokenizer/detokenizer.perl -l $(L2) < $< > $@

%.recased : %
	$(MOSES_SCRIPTS)/recaser/recase.perl -model $(BASE)/recasers/$(L2)/moses.ini -in $< -moses $(MOSES) > $@

#
# Evaluation
#
%.out.bleu : %.out
	$(MOSES_SCRIPTS)/generic/multi-bleu.perl $(TEST).$(L2) < $< > $@ 2> $@.log

%.out.sgm.bleu : %.out.sgm
	$(MTEVAL) -r $(DATA)/test/$*-src.$(L2).sgm -s $(DATA)/test/$*-src.$(L1).sgm -t $< -c -b

%.test.out.meteor : %.test.out
	java -XX:+UseCompressedOops -Xmx2G -jar /opt/meteor/meteor-1.2.jar $< $(TEST).$(L2) -l $(L2) > $@


