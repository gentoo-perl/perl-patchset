set -e -E -o pipefail

for suffix in 12-create-libperl-soname.diff; do
  einfo "Marking $suffix for exclusion";
  rm -vf "${patchdir}/${suffix}" || die "Excluding ${suffix} failed";
done
