set -e -E -o pipefail
PF=perl
PATCH_VER=1
prefix=""
patchdir=$(pwd)/patches
patchoutput="patchlevel-gentoo.h"
patchin=${patchdir}/series

for suffix in create_libperl_soname.diff; do
  einfo "Marking $suffix for exclusion";
  cat $patchin | grep -Fv "$suffix" > $patchin.new || die "Filtering $patchin failed";
  mv $patchin.new $patchin || die "Relocating $patchin.new to $patchin failed";
done

cat ${patchin} | while read patch; do
  einfo "Applying $patch";
  (
    PATCH=$patchdir/$patch;
    pushd "${S}" >> /dev/null
    patch -p 1 -f -s -g0 --no-backup-if-mismatch <$PATCH
  ) || die "Could not apply $patch";
done

einfo "Generating $patchoutput"
cat ${patchin} | while read patch
do
	patchname=$(echo $patch | sed 's/\.diff$//')
	< $patchdir/$patch sed -e '/^Subject:/ { N; s/\n / / }' | sed -n -e '

	# massage the patch headers
	s|^Bug: .*https\?://rt\.perl\.org/.*id=\(.*\).*|[perl #\1]|; tprepend;
	s|^Bug: .*https\?://rt\.cpan\.org/.*id=\(.*\).*|[rt.cpan.org #\1]|; tprepend;
	s|^Bug-Gentoo: ||; tprepend;
	s/^\(Subject\|Description\): //; tappend;
	s|^Origin: .*http://perl5\.git\.perl\.org/perl\.git/commit\(diff\)\?/\(.......\).*|[\2]|; tprepend;

	# post-process at the end of input
	$ { x;
		# include the version number in the patchlevel.h description (if available)
		s/List packaged patches/&'" for ${PF}(#${PATCH_VER})"'/;

		# escape any backslashes and double quotes
		s|\\|\\\\|g; s|"|\\"|g;

		# add a prefix
		s|^|\t,"'"$prefix$patchname"' - |;
		# newlines away
		s/\n/ /g; s/  */ /g;
		# add a suffix
		s/ *$/"/; p
	};
	# stop all processing
	d;
	# label: append to the hold space
	:append H; d;
	# label: prepend to the hold space
	:prepend x; H; d;
	'
done > "${S}/${patchoutput}"

einfo "Updating MANIFEST"
chmod a+w "${S}/MANIFEST" || die "Can't mark manifest writeable"
echo "${patchoutput}" >> "${S}/MANIFEST"
