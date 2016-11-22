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
)
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

einfo "Getting version info from ./perl -Ilib -V"
(
  pushd "${S}";
  LD_LIBRARY_PATH=. ./perl -Ilib -V
)

einfo "Testing Perl ${TARGET_PERL}"
(
  pushd "${S}";
  TEST_JOBS=5 make test_harness
) || die "Test failed"
