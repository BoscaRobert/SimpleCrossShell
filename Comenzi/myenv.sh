#!/bin/bash

# Script: myenv.sh
# Descriere: Remplementare 'env' completa + functionalitate custom (--PATH).
#
# Optiuni implementate:
#   -i, --ignore-environment  Porneste cu un mediu gol.
#   -u, --unset=NUME          sterge o variabila specifica.
#   -C, --chdir=DIR           Schimba directorul inainte de executie.
#   -0, --null                Termina liniile cu NULL (pt. iesire fara comanda).
#   -v, --debug               Afisează informatii detaliate.
#   VAR=VAL                   Seteaza variabile de mediu.
#
# Optiuni speciale:
#   --PATH                    Activează căutarea în PATH.
#   --pattern "glob"          Pattern-ul pentru căutare (necesită --PATH).


# 1. INIIALIZARE VARIABILE SI FLAG-URI

IGNORE_ENV=false
DEBUG_MODE=false
NULL_OPT=false
SEARCH_PATH_MODE=false
SEARCH_PATTERN=""
WORK_DIR=""
UNSET_LIST=()
NEW_VARS=()      
COMMAND_ARGS=()

# 2. PARSAREA ARGUMENTELOR
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--ignore-environment)
            IGNORE_ENV=true
            shift
            ;;
        -v|--debug)
            DEBUG_MODE=true
            shift
            ;;
        -0|--null)
            NULL_OPT=true
            shift
            ;;
        -u|--unset)
            if [[ -n "$2" ]]; then
                UNSET_LIST+=("$2")
                shift 2
            else
                echo "Eroare: -u necesita un nume de variabila." >&2
                exit 1
            fi
            ;;
        -C|--chdir)
            if [[ -n "$2" ]]; then
                WORK_DIR="$2"
                shift 2
            else
                echo "Eroare: -C necesita un director." >&2
                exit 1
            fi
            ;;
        # --- Opțiuni Custom ---
        --PATH)
            SEARCH_PATH_MODE=true
            shift
            ;;
        --pattern)
            if [[ -n "$2" ]]; then
                SEARCH_PATTERN="$2"
                shift 2
            else
                echo "Eroare: --pattern necesita un argument." >&2
                exit 1
            fi
            ;;
#  Variabile si Comanda
        *=*)
            # Daca argumentul contine '=', il pastram pentru a-l exporta mai tarziu.
            # Nu il exportam ACUM, pentru ca dacă vine -i după el, s-ar șterge.
            NEW_VARS+=("$1")
            shift
            ;;
        *)
            # Primul argument care nu e opaiune sau variabila este COMANDA.
            COMMAND_ARGS=("$@")
            break
            ;;
    esac
done

# 3. APLICAREA MODIFICARILOR DE SISTEM


# A. Mod debug
if [ "$DEBUG_MODE" = true ]; then
    echo "DEBUG: Se inițializează mediul..." >&2
fi

# B. Schimbarea Directorului (-C)
if [ -n "$WORK_DIR" ]; then
    if [ "$DEBUG_MODE" = true ]; then
        echo "DEBUG: Se schimba directorul în '$WORK_DIR'" >&2
    fi
    cd "$WORK_DIR" || { echo "Eroare: Nu pot schimba directorul în $WORK_DIR"; exit 1; }
fi

# C. Golirea Mediului (-i)
if [ "$IGNORE_ENV" = true ]; then
    if [ "$DEBUG_MODE" = true ]; then
        echo "DEBUG: Se sterge tot mediul curent (-i)." >&2
    fi
    # compgen -e listeaza toate variabilele exportate
    # Le stergem pe toate. Unele (readonly) vor da eroare, le aruncam (2>/dev/null).
    for var in $(compgen -e); do
        unset "$var" 2>/dev/null
    done
fi

# D. Stergerea selectiva (-u)
for var in "${UNSET_LIST[@]}"; do
    if [ "$DEBUG_MODE" = true ]; then
        echo "DEBUG: Se sterge variabila '$var'." >&2
    fi
    unset "$var"
done

# E. Aplicarea noilor variabile (VAR=VAL)
# Acestea se aplică dupa -i, deci vor exista in mediul final.
for assignment in "${NEW_VARS[@]}"; do
    if [ "$DEBUG_MODE" = true ]; then
        echo "DEBUG: Se setează '$assignment'." >&2
    fi
    export "$assignment"
done

# 4. LOGICA SPECIALA: CATARE IN PATH (--PATH)

if [ "$SEARCH_PATH_MODE" = true ]; then
    if [ -z "$SEARCH_PATTERN" ]; then
        echo "Eroare: --PATH necesita și --pattern." >&2
        exit 1
    fi
    
    if [ "$DEBUG_MODE" = true ]; then
        echo "DEBUG: Mod cautare activat. Pattern: $SEARCH_PATTERN. PATH: $PATH" >&2
    fi

    # Dacă PATH e gol (din cauza lui -i), avertizăm
    if [ -z "$PATH" ]; then
        echo "Avertisment: PATH este gol. Nu se poate cauta nimic." >&2
        exit 1
    fi

    IFS=':' read -r -a PATH_DIRS <<< "$PATH"
    shopt -s nullglob 
    found_any=false

    for dir in "${PATH_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            matches=("$dir"/$SEARCH_PATTERN)
            for file in "${matches[@]}"; do
                if [ -e "$file" ]; then
                    echo "$file"
                    found_any=true
                fi
            done
        fi
    done
    shopt -u nullglob

    if [ "$found_any" = false ]; then
        exit 1
    fi
    # In mod search ne oprim aici
    exit 0
fi

# 5. EXECUȚIA FINALA SAU AFIȘAREA

if [ ${#COMMAND_ARGS[@]} -eq 0 ]; then
    # CAZUL FARA COMANDA: AfisAm variabilele
    if [ "$DEBUG_MODE" = true ]; then
        echo "DEBUG: Nicio comandă specificata. Se afisează mediul." >&2
    fi

    # Setam separatorul: linie noua (\n) sau NULL (\0)
    separator=$'\n'
    if [ "$NULL_OPT" = true ]; then
        separator=$'\0'
    fi

    for var in $(compgen -e); do
# Printam NUME=VALOARE + separator
        printf "%s=%s%b" "$var" "${!var}" "$separator"
    done

else
    # CAZUL CU COMANDA: Executam
    command_name="${COMMAND_ARGS[0]}"
    
    if [ "$DEBUG_MODE" = true ]; then
        echo "DEBUG: Se execută comanda: ${COMMAND_ARGS[*]}" >&2
    fi

    # exec inlocuieste procesul curent.
    # Daca am folosit -i, PATH e gol, deci comanda trebuie sa fie cale absoluta
    # sau trebuie sa fi setat PATH=... in argumente.
    exec "${COMMAND_ARGS[@]}"
    
    # Dacaa exec esueaza (ex: comanda nu există):
    echo "env: '${command_name}': Comanda nu a fost găsită sau nu poate fi executată." >&2
    exit 127
fi
