param (
    [Parameter(Position=0)]
    [string]$Arg1,

    [Parameter(Position=1)]
    [string]$Arg2,

    [switch]$d,
    [switch]$s
)

#valori start
$mode = "translate" # translate, delete, squeeze
$set1 = ""
$set2 = ""

#pasare argumente
if ($d) {
    $mode = "delete"
    $set1 = $Arg1
} elseif ($s) {
    $mode = "squeeze"
    $set1 = $Arg1
} else {
    $mode = "translate"
    $set1 = $Arg1
    $set2 = $Arg2
}

#citire input de la STDIN, deoarece tr lucreaza cu pipe-uri
#$input | Out-String pentru a citi tot textul venit prin pipe
$input_content = $input | Out-String

if ($mode -eq "delete") {
    #sterge caracterele din set1
    #regex powershell (-replace)
    #construim patternul [set1]
    if (-not $set1) { Write-Error "Lipseste setul de caractere."; exit 1 }
    
    $pattern = "[$set1]"
    Write-Output ($input_content -replace $pattern, "")

} elseif ($mode -eq "squeeze") {
    #comprima repetitiile caracterelor din set1
    if (-not $set1) { Write-Error "Lipseste setul de caractere."; exit 1 }

    #regex pentru repetitii: (caracter)\1+
    $pattern = "([$set1])\1+"
    
    #clasa .NET Regex pentru inlocuire cu back-reference ($1)
    Write-Output ([System.Text.RegularExpressions.Regex]::Replace($input_content, $pattern, '$1'))

} else {
    #translate
    #inlocuire set1 cu set2 (ex.: tr a-z A-Z)
    if (-not $set2) {
        Write-Host "Eroare: Lipseste setul 2 pentru translate."
        exit 1
    }

    #Implementare manuala (fara sed y///)
    $chars = $input_content.ToCharArray()
    $result = [System.Text.StringBuilder]::new()
    
    #creare mapa de inlocuire
    $map = @{}
    $len = [Math]::Min($set1.Length, $set2.Length)
    for ($i = 0; $i -lt $len; $i++) {
        if (-not $map.ContainsKey($set1[$i])) {
            $map[$set1[$i]] = $set2[$i]
        }
    }

    #parcurgere si inlocuire
    foreach ($c in $chars) {
        if ($map.ContainsKey($c)) {
            [void]$result.Append($map[$c])
        } else {
            [void]$result.Append($c)
        }
    }
    Write-Output $result.ToString()
}