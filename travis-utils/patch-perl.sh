set -e -E -o pipefail
PF=perl
PATCH_VER=1
prefix=""
patchdir=$(pwd)/patches
infodir=$(pwd)/patch-info
patchoutput="patchlevel-gentoo.h"

for suffix in 12-create-libperl-soname.diff; do
  einfo "Marking $suffix for exclusion";
  rm -vf "${patchdir}/${suffix}" || die "Excluding ${suffix} failed";
done

PATCHES=($(
  find "${patchdir}" -maxdepth 1 -mindepth 1 -type f -printf "%f\n" |\
    grep -E '[.](diff|patch)$' |\
    sort -n
))

for patch in "${PATCHES[@]}"; do
  einfo "Applying $patch";
  (
    pushd "${S}" >> /dev/null
    patch -p 1 -f -s -g0 --no-backup-if-mismatch <"${patchdir}/${patch}"
  ) || die "Could not apply ${patchdir}${patch}";
done

c_escape() {
  printf "%q" "$1" |\
    sed "s|\\ | |g"
}
c_escape_file() {
  c_escape "$( cat "$1" )"
}

einfo "Generating $patchoutput"
for patch in "${PATCHES[@]}"; do
  name_f="${infodir}/${patch}.name"
  desc_f="${infodir}/${patch}.desc"

  name="$( echo $suffix | sed 's/\.\(diff\|patch\)$//' )"
  desc=""

  if [[ ! -e "${name_f}" ]]; then 
    ewarn "No ${name_f}, will substitute";
  else
    name="$(c_escape_file "${name_f}")"
  fi
  if [[ ! -e "${desc_f}" ]]; then
    ewarn "No ${desc_f}";
  else
    desc=" - $(c_escape_file "${desc_f}")"
  fi
  printf ',"%s%s"\n' "${name}" "${desc}"
done > "${S}/${patchoutput}"

einfo "Updating MANIFEST"
chmod a+w "${S}/MANIFEST" || die "Can't mark manifest writeable"
echo "${patchoutput}" >> "${S}/MANIFEST"
