set -e -E -o pipefail
einfo "Updating MANIFEST"
chmod a+w "${S}/MANIFEST" || die "Can't mark manifest writeable"
echo "${patchoutput}" >> "${S}/MANIFEST"
