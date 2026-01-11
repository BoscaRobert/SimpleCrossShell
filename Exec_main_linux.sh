#!/bin/bash

#pentru debugging
echo "pornit"

#verificam daca scriptul v-a loga comenziile
logheaza=0
if [ "$1" = "log" ] ; then
   logheaza=1
fi

#salvam directorul aplicatiei, dat prin al doilea atribut, in cazul in care directorul curent va fi schimbat de comanda
og=$2

#schimbam directorul catre directorul curent 
cd "$3" || { echo "Eroare, Nu s-a putut schimba directorul">"$og"/outstream; exit 1 ; }

#creem fisierul in care va fi stocat directorul de dupa executia scriptului
touch "$og"/current_directory

#outstream va fi fifo-ul care va trimite rezultatele scriptului GUI-ului
 if [ ! -e "$og"/outstream ]; then
    mkfifo "$og"/outstream
 fi

#luam comanda/comenziile care vor fi executate fin fifo-ul transmis de scriptul tcl
comanda=$(cat<"$og"/comSend)
echo "Sa primit comanda sau sirul de comenzi: $comanda"

#transformam comanda intr-o lista de comenzi in cazul in care acestea sunt combinate
IFS=';' read -ra listaComenzi <<< "$comanda"

#parcurgem toate comenziile, si pentru fiecare comanda vom porni un lant de executie
for com in "${listaComenzi[@]}"
do
   echo "Pornire Chain Process pentru $com"
   #Verificam daca prima comanda este cd. daca este, schimbam directorul
   if [ $(echo "$com" | cut -d'|' -f1 | grep 'cd' | wc -w) -ge 1 ]; then
      echo "schimb director"
      echo $(echo "$com" | cut -d'|' -f1)
      eval $(echo "$com" | cut -d'|' -f1)
   fi
   # se Incepe lantul de comenzi, primul argument este comanda, al doilea optiunea de a loga sau nu comenziile
   #executate (0/1), al treilea argument reprezinta daca este primul din sir sau nu (1/0), al patrulea directorul original,
   #si al cincelea, daca e cazul, fisierul temporar
   "$og"/Bash_Chain.sh "$com" $logheaza 1 "$og"
done

#setam noul (sau acelasi ) director
echo $(pwd)>"$og"/current_directory
#Trimitem TERM pentru a arata ca scriptul s-a terminat
echo "TERM">"$og"/outstream