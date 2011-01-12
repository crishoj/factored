AC_PREREQ(2.50)
AC_INIT(FactoredSMT, 0.1, crjensen@hum.ku.dk)
AC_CONFIG_AUX_DIR(cfg)

AM_INIT_AUTOMAKE(FactoredSMT, 0.1)

AC_ARG_WITH(corpus_prefix,
            [AC_HELP_STRING([--with-corpus-prefix=PREFIX], [(optional) name (prefix) of the corpus])],
            [CORPUS_PREFIX=$withval],
            [CORPUS_PREFIX=europarl.cleaned]
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

AC_SUBST(CORPUS_PREFIX)
AC_SUBST(L1)
AC_SUBST(L2)

AC_CONFIG_FILES([Makefile])

AC_OUTPUT()
