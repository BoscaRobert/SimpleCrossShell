#!/usr/bin/env bash

set -euo pipefail

print_usage() {
  cat <<'EOF'
usage: id [options] [username]

options:
  -u        afișează doar UID
  -g        afișează doar GID (primar)
  -G        afișează toate GID-urile grupurilor
  -n        afișează nume în loc de numere (folosit cu -u/-g/-G)
  -h        afișează acest mesaj

note:
  dacă nu se dă niciuna dintre opțiunile -u/-g/-G, scriptul afișează un rezumat.
EOF
}

# Variabile pentru opțiuni.
only_uid=0
only_gid=0
only_groups=0
use_names=0

# Parser de opțiuni cu getopts.
while getopts ":ugGnh" opt; do
  case "$opt" in
    u) only_uid=1 ;;
    g) only_gid=1 ;;
    G) only_groups=1 ;;
    n) use_names=1 ;;
    h)
      print_usage
      exit 0
      ;;
    :)
      echo "id: opțiunea -$OPTARG necesită argument (nefolosit aici)" >&2
      exit 2
      ;;
    \?)
      echo "id: opțiune invalidă: -$OPTARG" >&2
      print_usage >&2
      exit 2
      ;;
  esac
done
shift $((OPTIND - 1))

# Dacă există un argument rămas, acesta este tratat ca username.
target_user="${1:-}"

# Funcții helper: obțin info fie despre userul curent, fie despre un user dat.
get_uid() {
  if [[ -n "$target_user" ]]; then
    # Scriptul încearcă să obțină uid pentru userul cerut.
    id -u "$target_user" 2>/dev/null || return 1
  else
    id -u
  fi
}

get_gid() {
  if [[ -n "$target_user" ]]; then
    id -g "$target_user" 2>/dev/null || return 1
  else
    id -g
  fi
}

get_groups_gid_list() {
  if [[ -n "$target_user" ]]; then
    id -G "$target_user" 2>/dev/null || return 1
  else
    id -G
  fi
}

get_user_name() {
  if [[ -n "$target_user" ]]; then
    echo "$target_user"
  else
    # Scriptul folosește cine este utilizatorul curent.
    id -un
  fi
}

get_primary_group_name() {
  # Scriptul convertește gid -> nume grup (dacă există).
  local gid
  gid="$(get_gid)"
  getent group "$gid" | cut -d: -f1
}

get_group_names_list() {
  # Scriptul convertește lista de GID-uri în nume de grupuri.
  local gids
  gids="$(get_groups_gid_list)"
  local out=()
  local g

  for g in $gids; do
    # Pentru fiecare GID, scriptul caută numele în baza de grupuri.
    name="$(getent group "$g" | cut -d: -f1 || true)"
    if [[ -n "${name:-}" ]]; then
      out+=("$name")
    else
      out+=("$g")
    fi
  done

  # Scriptul afișează numele separate prin spațiu (comportament similar id -Gn).
  echo "${out[*]}"
}

# Dacă userul cerut nu există, scriptul iese cu eroare.
if [[ -n "$target_user" ]]; then
  if ! id "$target_user" >/dev/null 2>&1; then
    echo "id: utilizator inexistent: $target_user" >&2
    exit 1
  fi
fi

# Cazuri: -u / -g / -G au prioritate, altfel se afișează rezumat.
# Dacă utilizatorul combină mai multe (-u -g), scriptul afișează în ordinea: u, g, G.
printed_any=0

if [[ "$only_uid" -eq 1 ]]; then
  if [[ "$use_names" -eq 1 ]]; then
    echo "$(get_user_name)"
  else
    get_uid
  fi
  printed_any=1
fi

if [[ "$only_gid" -eq 1 ]]; then
  if [[ "$use_names" -eq 1 ]]; then
    get_primary_group_name
  else
    get_gid
  fi
  printed_any=1
fi

if [[ "$only_groups" -eq 1 ]]; then
  if [[ "$use_names" -eq 1 ]]; then
    get_group_names_list
  else
    get_groups_gid_list
  fi
  printed_any=1
fi

if [[ "$printed_any" -eq 1 ]]; then
  exit 0
fi

# Rezumat default (fără -u/-g/-G).
uid="$(get_uid)"
gid="$(get_gid)"
uname="$(get_user_name)"
gname="$(get_primary_group_name || true)"
groups_gids="$(get_groups_gid_list)"
groups_names="$(get_group_names_list)"

# Scriptul afișează un rezumat simplu și stabil.
echo "user=${uname} uid=${uid} gid=${gid} group=${gname:-unknown} groups_gids=${groups_gids} groups_names=${groups_names}"

