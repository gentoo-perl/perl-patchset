set -e -E -o pipefail
patchdir=$(pwd)/patches
infodir=$(pwd)/patch-info
patchoutput="patchlevel-gentoo.h"

c_escape_string() {
  local slash dquote
  slash='\'
  dquote='"'
  re_slash="${slash}${slash}"
  re_dquote="${slash}${dquote}"

  # Convert \ to \\,
  #         " to \"
  echo "$1" |\
  sed "s|${re_slash}|${re_slash}${re_slash}|g" |\
    sed "s|${re_dquote}|${re_slash}${re_dquote}|g"
}
c_escape_file() {
  c_escape_string "$(cat "$1")"
}

einfo "Generating $patchoutput"
for patch in "${PATCHES[@]}"; do
  desc_f="${infodir}/${patch}.desc"
  bugs_f="${infodir}/${patch}.bugs"

  name="$( echo $patch | sed 's/\.\(diff\|patch\)$//' )"

  printf ',"%s"\n' "${name}";
  einfo "${name}"
  if [[ ! -e "${desc_f}" ]]; then
    ewarn "No ${desc_f}";
  else
    desc="$(c_escape_file "${desc_f}")"
  
    printf ',"    - %s"\n' "${desc}"
    einfo "    - ${desc}"
  fi
  if [[ -e "${bugs_f}" ]]; then
    printf ',"    Bugs:"\n'
    einfo "    Bugs:"
    while read -d $'\n' -r line ; do
      esc_line="$(c_escape_string "${line}")"
      printf ',"      - %s"\n' "${esc_line}"
      einfo "      - ${esc_line}"
    done <"${bugs_f}"
  fi
done > "${S}/${patchoutput}"
