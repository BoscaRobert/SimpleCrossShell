#!/bin/bash

#Acest script primeste lantul de comenzi cu pipe-uri, executa prima comanda, sterge prima comanda din lant, 
#si se executa din nou pana cand ramane doar o comanda, moment in care aceasta se termina


currentComand="$(echo "$1" | cut -d'|' -f1)"
echo "$currentComand"
if [ "$(echo "$1" | grep -o 't' | wc -l)" == 0 ]; then
    echo "finishedChain"
    if [ $3 = 1 ]; then
        echo "logat"
        echo "La $(date) , s-a executat comanda: $currentComand">>"$4/log.txt"
        printf '\n'>>"$4/log.txt"
    fi
    $currentComand > "$4/outstream"
fi