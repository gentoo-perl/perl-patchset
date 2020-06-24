set -e -E -o pipefail
patchdir=$(pwd)/patches
for suffix in 12-create-libperl-soname.diff; do
  einfo "Marking $suffix for exclusion";
  rm -vf "${patchdir}/${suffix}" || die "Excluding ${suffix} failed";
done
