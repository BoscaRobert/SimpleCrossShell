#!/bin/bash

#Acest script primeste lantul de comenzi cu pipe-uri, executa prima comanda, sterge prima comanda din lant, 
#si se executa din nou pana cand ramane doar o comanda, moment in care aceasta se termina


currentComand="$(echo "$1" | cut -d'|' -f1)"
echo "ChainProcess; Comanda curenta este: $currentComand"

#In cazul in care scriptul este powershel, acesta va avea header-ul #!/usr/bin/env pwsh , si va putea fi tratat
#la fel ca un script bash.

#Verificam daca comanda este prima din chain, daca este, se va executa direct si va crea un fisier temporar, 
#daca nu, va citi input-ul din fisierul temp, si il va sterge dupa
if [ "$3" = 1 ]; then
    rezultat="$($currentComand)"
    dataExecutie=$(date)
    echo "rexultatul primei comenzii este $rezultat"
else
    tempo=$5
    rezultat="$($currentComand < "$tempo")"
    dataExecutie=$(date)
    echo "rexultatul comenzii curente este $rezultat"
    echo "aceasta a preluat datele din $tempo"
    rm "$tempo"
    echo "Fisierul temporar a fost sters"
fi

#verificam daca se logheaza, in cazul in care da, scriem data executiei si comanda care urmeaza sa fie executata
if [ "$2" == 1 ]; then
    echo "$dataExecutie : $currentComand \n">"$4"/log.txt
fi

# daca nu mai exista pipe-uri in script inseamna ca s-au terminat toate procesele, deci trimitem outputul functiei la outstream si nu mai executam nimic
nrPipes=$(echo "$1" | grep -o '|' | wc -l)
if [ "$nrPipes" = 0  ]; then
    echo "mai sunt: $nrPipes pipe-uri"
    echo "$rezultat">"$4"/outstream
    echo "rezultatul final: $rezultat a fost trimis la $4/outstream"
else
# daca exista mai multe pipe-uri se va executa din nou acest script, taind prima comanda, si transmitand output-ul printrun temp
    sentTemp=$(mktemp "$4/procPipeXXX")
    echo "$rezultat">"$sentTemp"
    echo "rezultatul curent: $rezultat a fost trimis la $sentTemp"
    "$4/Bash_Chain.sh" "$( echo $1 | cut -d'|' -f2- )" "$2" 0 "$4" $sentTemp
    echo "un nou Chain Process a fost ececutat cu atributele $( echo $1 | cut -d'|' -f2- ) $2 0 $4 $sentTemp"
fi