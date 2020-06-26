set -e -E -o pipefail
patchdir=$(pwd)/patches
infodir=$(pwd)/patch-info
PF=perl
PATCH_VER=1

FIX=( $(
  cd "${patchdir}";
  echo *List-packaged-patches*
) )
for suffix in "${FIX[@]}"; do
  if [[ -e "${patchdir}/${suffix}" ]]; then
    einfo "Injecting PV/Patchlevel into $suffix";
    printf "List packaged patches for %s(#%s) in patchlevel.h" "${PF}" "${PATCH_VER}" > "${infodir}/${suffix}.desc"
  else
    eerror "No file to patch: patch: $suffix, desc: $suffix.desc"
  fi
done
