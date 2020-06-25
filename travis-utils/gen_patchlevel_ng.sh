set -e -E -o pipefail
patchdir=$(pwd)/patches
infodir=$(pwd)/patch-info
patchoutput="patchlevel-gentoo.h"

c_escape_file() {
  local slash dquote
  slash='\'
  dquote='"'
  re_slash="${slash}${slash}"
  re_dquote="${slash}${dquote}"

  # Convert \ to \\,
  #         " to \"
  sed "s|${re_slash}|${re_slash}${re_slash}|g" "$1" |\
    sed "s|${re_dquote}|${re_slash}${re_dquote}|g"
}

einfo "Generating $patchoutput"
for patch in "${PATCHES[@]}"; do
  desc_f="${infodir}/${patch}.desc"

  name="$( echo $patch | sed 's/\.\(diff\|patch\)$//' )"
  desc=""

  if [[ ! -e "${desc_f}" ]]; then
    ewarn "No ${desc_f}";
  else
    desc=" - $(c_escape_file "${desc_f}")"
  fi
  einfo "${name}${desc}"
  printf ',"%s%s"\n' "${name}" "${desc}"
done > "${S}/${patchoutput}"
