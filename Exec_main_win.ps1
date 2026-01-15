# arg 0 log;  arg 1 Director original; arg 2 working dir

#Setam directorul original din argument
$og=$args[1]
$log=$args[0]
#citim comanda transmisa de shell din fisierul comPWSH
$comanda = Get-Content "$og/comPWSH"
#Impartim comanda cu delimitatorul pipeline |
$splitCommands="$comanda" -split "\|"

foreach ($comm in $splitCommands){
    #Pentru Debugging
    Write-Output ("Comanda Curenta "+"$comm")
    #Daca nu este prima comanda din pipeline
    if ($comm -ne $splitCommands[0]) {
        #Imputul se ia din fisierul in care comanda anterioara a scris
        Write-Output ("Fisierul temporar contine"+(Get-Content -Raw "$og/tempPWSH"))
        Get-Content -Raw "$og/tempPWSH" | Invoke-Expression $comm > "$og/tempPWSH"
        Write-Output ("S-a executat cu input din fisier")
    } else {
        #Nu se ia imputul dintr-un fisier
        Invoke-Expression $comm > "$og/tempPWSH"
    }
    #Pentru Debugging
    Write-Output "S-a Executat"
    #Daca optiunea de logare este activa
    if ($log -eq "log"){
        #Se scrie in log.txt ora si instructiunea executata
        Write-Output ((Get-Date -Format "HH:mm:ss") + " PowerShell a executat: $comm")>>"$og/log.txt"
        Write-Output "s-a Logat"
    }
}
#La final, outputul ultimei comenzi se redirectioneaza la fifo-ul outstream (la Shell)
Get-Content "$OG/tempPWSH" > outstream
#scriem in fifo mesajul de terminare pentru ca shellul sa afiseze stdout-ul
Write-Output "TERM"> outstream