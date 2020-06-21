set -e -E -o pipefail
patchdir=$(pwd)/patches

for patch in "${PATCHES[@]}"; do
  einfo "Applying $patch";
  (
    pushd "${S}" >> /dev/null
    patch -p 1 -f -s -g0 --no-backup-if-mismatch <"${patchdir}/${patch}"
  ) || die "Could not apply ${patchdir}${patch}";
done
