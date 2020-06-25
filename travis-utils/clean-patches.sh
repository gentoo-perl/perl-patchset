set -e -E -o pipefail
patchdir=$(pwd)/patches

STRIP=( $(
  cd "${patchdir}";
  echo 0012*
  ) )
for suffix in "${STRIP[@]}"; do
  einfo "Marking $suffix for exclusion";
  rm -vf "${patchdir}/${suffix}" || die "Excluding ${suffix} failed";
done
