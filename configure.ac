AC_PREREQ(2.50)
AC_INIT(FactoredSMT, 0.1, crjensen@hum.ku.dk)
AC_CONFIG_AUX_DIR(cfg)
AM_INIT_AUTOMAKE(FactoredSMT, 0.1)

AC_ARG_WITH(corpus,
            [AC_HELP_STRING([--with-corpus=PREFIX], [(optional) name (prefix) of the corpus])],
            [CORPUS_PREFIX=$withval],
            [CORPUS_PREFIX=europarl.cleaned]
           )

AC_ARG_WITH(lm,
            [AC_HELP_STRING([--with-lm=PREFIX], [(optionally) use the language models from another corpus])],
            [LM_PREFIX=$withval]
           )

AC_ARG_WITH(lm-suffix,
            [AC_HELP_STRING([--with-lm-suffix=SUFFIX], [what sort of language model to use (e.g. kblm.mmap for memory mapped KenLM)])],
            [LM_SUFFIX=$withval],
            [LM_SUFFIX=kblm.mmap]
           )

AC_ARG_WITH(source-lang,
            [AC_HELP_STRING([--with-source-lang=LANG], [source language code (e.g. "da")])],
            [L1=$withval],
            [L1=da]
           )

AC_ARG_WITH(target-lang,
            [AC_HELP_STRING([--with-target-lang=LANG], [target language code (e.g. "en")])],
            [L2=$withval],
            [L2=en]
           )

AC_ARG_WITH(test-sents,
            [AC_HELP_STRING([--with-test-sents=N], [number of sentences to use in the test set])],
            [TEST_SENTS=$withval],
            [TEST_SENTS=10000]
           )

AC_ARG_WITH(dev-sents,
            [AC_HELP_STRING([--with-dev-sents=N], [number of sentences to use in the development (optimization) set])],
            [DEV_SENTS=$withval],
            [DEV_SENTS=2000]
           )

AC_PATH_PROGS(MERT_BIN, mert)
if test -z "mert"; then
    AC_MSG_ERROR([mert binary could not be found, please install or adjust PATH])
fi

AC_ARG_WITH(mert-dir,
            [AC_HELP_STRING([--with-mert-dir=DIR], [location of mert utilities])],
            [MERT_DIR=$withval],
            [MERT_DIR=`dirname $MERT_BIN`]
           )

AC_MSG_NOTICE([Using ${MERT_DIR} for MERT_DIR])

AC_PATH_PROGS(MOSES_BIN, moses)
if test -z "moses"; then
    AC_MSG_ERROR([moses decoder could not be found, please install or adjust PATH])
fi

AC_SUBST(CORPUS_PREFIX)
AC_SUBST(LM_PREFIX)
AC_SUBST(LM_SUFFIX)
AC_SUBST(L1)
AC_SUBST(L2)
AC_SUBST(TEST_SENTS)
AC_SUBST(DEV_SENTS)
AC_SUBST(MERT_BIN)
AC_SUBST(MERT_DIR)
AC_SUBST(MOSES_BIN)

AC_CONFIG_FILES([
    Makefile
    corpus/Makefile
])

AC_OUTPUT()
