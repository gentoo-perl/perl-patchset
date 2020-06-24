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
  einfo "${name}${desc}"
  printf ',"%s%s"\n' "${name}" "${desc}"
done > "${S}/${patchoutput}"
