#!/bin/bash

#valori start
mode="translate" # translate, delete, squeeze
set1=""
set2=""

#pasare argumente
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d) mode="delete"; shift ;;
        -s) mode="squeeze"; shift ;;
        -*) echo "Optiune necunoscuta: $1"; exit 1 ;;
        *) 
           if [ -z "$set1" ]; then
               set1="$1"
           elif [ -z "$set2" ] && [ "$mode" == "translate" ]; then
               set2="$1"
           fi
           shift 
           ;;
    esac
done

#citire input de la STDIN, deoarece tr lucreaza cu pipe-uri
input_content=$(cat)

if [ "$mode" == "delete" ]; then
    #sterge caracterele din set1
    #folosim expansiune bash: ${var//pattern/replace}
    #construim patternul [set1]
    echo "$input_content" | while IFS= read -r line; do
        echo "$line" | sed "s/[$set1]//g"
    done

elif [ "$mode" == "squeeze" ]; then
    #comprima repetitiile caracterelor din set1
    echo "$input_content" | sed -E "s/([$set1])\1+/\1/g"

else
    #translate
    #inlocuire set1 cu set2 (ex.: tr a-z A-Z)
    if [ -z "$set2" ]; then
        echo "Eroare: Lipseste setul 2 pentru translate."
        exit 1
    fi
    echo "$input_content" | sed "y/$set1/$set2/"
fi