set -e -E -o pipefail
patchdir=$(pwd)/patches
for suffix in 0012-Set-libperl*; do
  einfo "Marking $suffix for exclusion";
  rm -vf "${patchdir}/${suffix}" || die "Excluding ${suffix} failed";
done
