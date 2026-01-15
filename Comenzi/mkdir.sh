#!/usr/bin/env bash

# Setam flag-uri de siguranta
# -e: opreste la eroare
# -u: eroare la variabile nedeclarate
set -euo pipefail

LOGFILE="summary.log"

print_usage() {
  cat <<'EOF'
usage: mkdir [options] DIRECTORY...

options:
  -p        nu returna eroare dacă există; creează directoarele părinte
  -v        afișează un mesaj pentru fiecare director creat
  -m MODE   setează permisiunile (ca în chmod), ex: 755
  -h        afișează acest mesaj

note:
  Comanda simulează mkdir dar adaugă logging în summary.log
EOF
}

# Variabile pentru opțiuni (inițializare)
create_parents=0
verbose=0
mode_val=""

# Parser de opțiuni cu getopts
while getopts ":pvm:h" opt; do
  case "$opt" in
    p) create_parents=1 ;;
    v) verbose=1 ;;
    m) 
       # Verificăm dacă modul e numeric (ex: 755)
       if [[ "$OPTARG" =~ ^[0-7]{3,4}$ ]]; then
           mode_val="$OPTARG"
       else
           echo "mkdir: mod invalid '$OPTARG'" >&2
           exit 1
       fi
       ;;
    h)
      print_usage
      exit 0
      ;;
    :)
      echo "mkdir: opțiunea -$OPTARG necesită un argument" >&2
      exit 1
      ;;
    \?)
      echo "mkdir: opțiune invalidă: -$OPTARG" >&2
      print_usage >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

# Verificăm dacă avem operanzi
if [ $# -eq 0 ]; then
    echo "mkdir: lipsește operandul" >&2
    exit 1
fi

timestamp=$(date "+%Y-%m-%d %H:%M:%S")

# Logica principală de execuție
for target_dir in "$@"; do
    # Construim lista de argumente într-un array
    cmd_args=()
    
    if [ "$create_parents" -eq 1 ]; then
        cmd_args+=("-p")
    fi
    
    if [ "$verbose" -eq 1 ]; then
        cmd_args+=("-v")
    fi
    
    # Gestionare mod permisiuni (-m)
    log_extra="[Mode: Default]"
    if [ -n "$mode_val" ]; then
        cmd_args+=("-m" "$mode_val")
        log_extra="[Mode: $mode_val]"
    fi
    
    # Logăm intenția în summary.log 
    echo "[$timestamp] [mkdir-bash] START creare: $target_dir $log_extra" >> "$LOGFILE"

    # Executăm comanda reală, capturând stderr și stdout
    # "|| true" previne ieșirea scriptului din cauza "set -e" dacă mkdir eșuează
    output=$(mkdir "${cmd_args[@]}" "$target_dir" 2>&1) || true
    exit_code=$?

    # Procesare rezultat și scriere în log
    if [ $exit_code -eq 0 ]; then
        if [ "$verbose" -eq 1 ]; then echo "$output"; fi
        echo "[$timestamp] [mkdir-bash] SUCCESS: $target_dir" >> "$LOGFILE"
    else
        # Filtrare eroare: dacă folderul există și avem -p, e ok
        if [[ "$output" == *"File exists"* && "$create_parents" -eq 1 ]]; then
             echo "[$timestamp] [mkdir-bash] INFO: Director existent (skipped)" >> "$LOGFILE"
        else
             echo "$output" >&2
             echo "[$timestamp] [mkdir-bash] FAIL: $output" >> "$LOGFILE"
        fi
    fi
done

exit 0
