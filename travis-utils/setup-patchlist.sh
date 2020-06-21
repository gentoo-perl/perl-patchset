set -e -E -o pipefail
patchdir=$(pwd)/patches
PATCHES=($(
  find "${patchdir}" -maxdepth 1 -mindepth 1 -type f -printf "%f\n" |\
    grep -E '[.](diff|patch)$' |\
    sort -n
))
