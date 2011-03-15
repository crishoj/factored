
CSTLEMMA 	= /opt/cstlemma/cstlemma
CSTLEMMA_OPTS 	= -t- -b '$$w' -B '$$w' -c '$$b1[[$$b?]~1$$B]$$s' -f /opt/cstlemma/da/flexrules -d /opt/cstlemma/da/dict 

LEMMAGEN 	= /nyusers/anders/stemmers/v2/lemmagen/binary/linux/lemmatize
LEMMAGEN_OPTS 	= -f wpl

FACTOR_TOOL 	= $(BASE)/bin/factor
SPLIT		= $(BASE)/bin/split.sh

SRILM_OPTIONS 	= -order 3 -interpolate -kndiscount -unk 
SRILM_OPTIONS2 	= -order 3 -interpolate 

JUNSUPOS	= /opt/jUnsupos

EMBED		= /opt/neural-language-model

status :
	@echo PAIR = $(PAIR)
	@echo L1 = $(L1)
	@echo L2 = $(L2)
	@echo L = $(L)
	@echo OL = $(OL)
	@echo TRAIN_CORPUS = $(TRAIN_CORPUS)
	@echo TEST_CORPUS = $(TEST_CORPUS)
	@echo DEV_CORPUS = $(DEV_CORPUS)
	@echo FACTORS = $(FACTORS)
	@echo FACTOR_FILES = $(FACTOR_FILES)
	@echo FACTOR_MAX = $(FACTOR_MAX)
	@echo MODEL_NAME = $(MODEL_NAME)
	@echo DEV = $(DEV)

.PHONY : random-sleep

# To prevent Make from rushing to spawn too many processes
random-sleep : 
	sleep $(shell echo `od -N2 -An -i /dev/random` % 5 | bc)

# Tokenization
%.token.$(L) : %.raw.$(L)
	tokenizer.perl -l $(L) < $< > $@

# Lemmatization
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

# WSD
%.wsd.context.$(L) : %.lemma.$(L) %.pos.$(L)
	$(FACTOR_TOOL) --trace prepare_wsd --output $@ --before 0 --after 0 $^

%.wsd.output.$(L) : %.wsd.context.$(L)
	../../bin/parallelize --output $@ --chunks=16 --granularity=2 --nice=10 -- ukb_wsd -D ../../wsd/$(L)/dict.txt -K ../../wsd/$(L)/rels.bin --ppr {$<}

%.wsd.$(L) : %.lemma.$(L) %.wsd.output.$(L)
	$(FACTOR_TOOL) --trace wsd_extract $^ --output $@

# Brown clusters
%.cluster100.$(L) : %.lowercase.$(L) $(MONO)/clusters/$(L)/$(MONO_CORPUS)-c100-p1.out/paths
	$(FACTOR_TOOL) cluster_extract --output $@ $^

%.cluster320.$(L) : %.lowercase.$(L) $(MONO)/clusters/$(L)/$(MONO_CORPUS)-c320-p1.out/paths
	$(FACTOR_TOOL) cluster_extract --output $@ $^

%.cluster1000.$(L) : %.lowercase.$(L) $(MONO)/clusters/$(L)/$(MONO_CORPUS)-c1000-p1.out/paths
	$(FACTOR_TOOL) cluster_extract --output $@ $^

# jUnsupos
%.unsupos.$(L).output : $(JUNSUPOS)/models/$(L)/*.model %.lowercase.$(L) 
	java -Xmx4G -XX:+UseCompressedOops -XX:+UseConcMarkSweepGC -jar $(JUNSUPOS)/dist/lib/ViterbiTagger.jar $(basename $<) $*.lowercase.$(L) > $@

%.unsupos.$(L) : %.unsupos.$(L).output
	$(FACTOR_TOOL) --trace unsupos_extract $< --output $@

# Language modelling
%.lm : %
	ngram-count $(SRILM_OPTIONS2) -text $< -lm $@

# Binary LM for memory mapping with KenLM
%.kblm : %.lm
	build_binary $< $@


