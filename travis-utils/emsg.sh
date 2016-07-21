_e_color() {
  local color=$1
  shift;
  echo $'\e'"[${color}m * "$'\e[0m'"$@";
}

einfo() {
  _e_color 32 "$@" >> /dev/stderr
}
ewarn() {
  _e_color 33 "$@" >> /dev/stderr
}
eerror() {
  _e_color 31 "$@" >> /dev/stderr
}
die() {
  eerror "$@"
  set -e
  exit 1;
}
