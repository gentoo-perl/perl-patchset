einfo "Configuring Perl ${TARGET_PERL}"
myconf="$myconf"
sh=$(which sh)

confopts=(
  -des
  -Duseshrplib        # note: breaks create_libperl_soname.diff
  -Dcc="${CC}"
  -Dd_semctl_semun

  -Dusedevel          # 5.odd fails
  -Ud_csh             # These three must come in tandom to not break CPANPLUS
  -Dsh="$sh"
  -Dtargetsh="$sh"

  -Uusenm
  -Dnoextensions="ODBM_File"
  -Dmyhostname='localhost'
  -Dperladmin='root@localhost'
  -Dinstallusrbinperl='n'
  -Ui_xlocale # https://bugs.gentoo.org/636206
)
if [[ -n "$CFLAGS" ]]; then
  confopts+=( "-Doptimize=${CFLAGS}" )
fi
if [[ -n "$LDFLAGS" ]]; then
    confopts+=( "-Dldflags=${LDFLAGS}" )
fi
(
  pushd "${S}";
  echo sh Configure "${confopts[@]}" $myconf >> /dev/stderr
  sh Configure "${confopts[@]}" $myconf
) || die "Configure failed"

einfo "Compiling Perl ${TARGET_PERL}"
(
  pushd "${S}";
  make -j6
) || die "Make failed"

einfo "Testing Perl ${TARGET_PERL}"
(
  pushd "${S}";
  TEST_JOBS=5 make test_harness
) || die "Test failed"
