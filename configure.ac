AC_PREREQ(2.50)
AC_INIT(FactoredSMT, 0.1, crjensen@hum.ku.dk)
AC_CONFIG_AUX_DIR(cfg)
AM_INIT_AUTOMAKE(FactoredSMT, 0.1)

AC_ARG_WITH(train,
            [AC_HELP_STRING([--with-train=PREFIX], [(optional) name (prefix) of the training corpus])],
            [TRAIN=$withval],
            [TRAIN=wmt11]
           )
AC_MSG_NOTICE([Using training corpus: ${TRAIN}])

AC_ARG_WITH(dev,
            [AC_HELP_STRING([--with-dev=PREFIX], [(optional) name (prefix) of the development corpus])],
            [DEV=$withval],
            [DEV=newstest2009]
           )
AC_MSG_NOTICE([Using development corpus: ${DEV}])

AC_ARG_WITH(test,
            [AC_HELP_STRING([--with-test=PREFIX], [(optional) name (prefix) of the test corpus])],
            [TEST=$withval],
            [TEST=newstest2011]
           )
AC_MSG_NOTICE([Using testing corpus: ${TEST}])

AC_ARG_WITH(mono,
            [AC_HELP_STRING([--with-mono=PREFIX], [(optional) name (prefix) of the monolingual corpus])],
            [MONO=$withval],
            [MONO=all]
           )
AC_MSG_NOTICE([Using monolingual corpus: ${MONO}])

AC_ARG_WITH(lm-suffix,
            [AC_HELP_STRING([--with-lm-suffix=SUFFIX], [what sort of language model to use (e.g. kblm for binary KenLM)])],
            [LM_SUFFIX=$withval],
            [LM_SUFFIX=kblm]
           )
AC_MSG_NOTICE([Using language model type: ${LM_SUFFIX}])

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

AC_MSG_NOTICE([Translating from '${L1}' to '${L2}', using ${TEST_SENTS} sentences for testing and ${DEV_SENTS} sentences for development])

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

AC_ARG_WITH(moses-scripts,
            [AC_HELP_STRING([--with-moses-scripts=DIR], [location of moses scripts])],
            [MOSES_SCRIPTS=$withval],
	    [MOSES_SCRIPTS=/opt/mosesdecoder/scripts]
           )

AC_PATH_PROG(MULTI_BLEU, multi-bleu.perl, , $MOSES_SCRIPTS/generic)
if test -z "$MULTI_BLEU"; then
    AC_MSG_ERROR([moses scripts could not be found, please specify location])
fi

AC_MSG_NOTICE([Using ${MOSES_SCRIPTS} for MOSES_SCRIPTS])

AC_PATH_PROGS(MOSES_BIN, moses)
if test -z "$MOSES_BIN"; then
    AC_MSG_ERROR([moses decoder could not be found, please install or adjust PATH])
fi

AC_SUBST(TRAIN)
AC_SUBST(DEV)
AC_SUBST(TEST)
AC_SUBST(MONO)
AC_SUBST(LM_SUFFIX)
AC_SUBST(L1)
AC_SUBST(L2)
#AC_SUBST(TEST_SENTS)
#AC_SUBST(DEV_SENTS)
AC_SUBST(MERT_BIN)
AC_SUBST(MERT_DIR)
AC_SUBST(MOSES_BIN)
AC_SUBST(MOSES_SCRIPTS)

AC_CONFIG_FILES([
    standard_defs.mk
])

AC_OUTPUT()
