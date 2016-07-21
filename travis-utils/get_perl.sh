einfo "Fetching ${TARGET_PERL}"
wget -O /tmp/perl.tar.bz2 ${TARGET_PERL} || die "Cannot fetch ${TARGET_PERL}";
