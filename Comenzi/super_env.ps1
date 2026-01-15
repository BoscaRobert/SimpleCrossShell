
# Script: super_env.ps1
# Descriere: Implementare 'env' in PowerShell + functionalitate custom (--PATH).


# Folosim $args direct, nu param(), pentru flexibilitate maxima
$arguments = [System.Collections.Generic.Queue[string]]::new($args)

#1. Initializare Variabile
$IgnoreEnv = $false
$DebugMode = $false
$NullOpt = $false
$SearchPathMode = $false
$SearchPattern = ""
$WorkDir = ""
$UnsetList = @()
$NewVars = @{}         # Hash pentru noile variabile (VAR=VAL)
$CommandName = $null
$CommandArgs = @()

#2. Parsare Argumente
while ($arguments.Count -gt 0) {
    $arg = $arguments.Dequeue()

    if ($arg -eq "-i" -or $arg -eq "--ignore-environment") {
        $IgnoreEnv = $true
    }
    elseif ($arg -eq "-v" -or $arg -eq "--debug") {
        $DebugMode = $true
    }
    elseif ($arg -eq "-0" -or $arg -eq "--null") {
        $NullOpt = $true
    }
    elseif ($arg -eq "-u" -or $arg -eq "--unset") {
        if ($arguments.Count -gt 0) {
            $UnsetList += $arguments.Dequeue()
        } else {
            Write-Error "Eroare: -u necesita un nume de variabila."
            exit 1
        }
    }
    elseif ($arg -eq "-C" -or $arg -eq "--chdir") {
        if ($arguments.Count -gt 0) {
            $WorkDir = $arguments.Dequeue()
        } else {
            Write-Error "Eroare: -C necesita un director."
            exit 1
        }
    }
    # Optiuni Custom 
    elseif ($arg -eq "--PATH") {
        $SearchPathMode = $true
    }
    elseif ($arg -eq "--pattern") {
        if ($arguments.Count -gt 0) {
            $SearchPattern = $arguments.Dequeue()
        } else {
            Write-Error "Eroare: --pattern necesita un argument."
            exit 1
        }
    }
    #Detectare VAR=VAL
    elseif ($arg -match "^([^=]+)=(.*)$") {
        # $matches[1] este cheia, $matches[2] este valoarea
        $NewVars[$matches[1]] = $matches[2]
    }
    # --- Comanda ---
    else {
        # Primul argument care nu e optiune sau variabila e Comanda
        $CommandName = $arg
        # Restul argumentelor din coada apartin comenzii
        while ($arguments.Count -gt 0) {
            $CommandArgs += $arguments.Dequeue()
        }
        break
    }
}

#3. Pregatire Mediu

# A. Debug
if ($DebugMode) { Write-Host "DEBUG: Initializare mediu..." }

# B. Schimbare Director (-C)
if (-not [string]::IsNullOrEmpty($WorkDir)) {
    if ($DebugMode) { Write-Host "DEBUG: Schimbare director in '$WorkDir'" }
    if (Test-Path -Path $WorkDir) {
        Set-Location -Path $WorkDir
    } else {
        Write-Error "Eroare: Directorul $WorkDir nu exista."
        exit 1
    }
}

# Construim mediul final intr-un Hashtable
$FinalEnv = @{}

# C. Gestionare -i (Mediu gol vs Mediu curent)
if ($IgnoreEnv) {
    if ($DebugMode) { Write-Host "DEBUG: Se sterge mediul curent (-i)." }
    # Pornim de la zero, nu copiem nimic din $env
} else {
    # Copiem toate variabilele curente
    foreach ($item in Get-ChildItem env:) {
        $FinalEnv[$item.Name] = $item.Value
    }
}

# D. Stergere Variabile (-u)
foreach ($uVar in $UnsetList) {
    if ($DebugMode) { Write-Host "DEBUG: Se sterge variabila '$uVar'." }
    if ($FinalEnv.ContainsKey($uVar)) {
        $FinalEnv.Remove($uVar)
    }
}

# E. Adaugare Variabile Noi (VAR=VAL)
foreach ($key in $NewVars.Keys) {
    if ($DebugMode) { Write-Host "DEBUG: Se seteaza '$key'." }
    $FinalEnv[$key] = $NewVars[$key]
}

# --- 4. Logica Speciala (--PATH) ---
if ($SearchPathMode) {
    if ([string]::IsNullOrEmpty($SearchPattern)) {
        Write-Error "Eroare: --PATH necesita si --pattern."
        exit 1
    }

    if ($DebugMode) { Write-Host "DEBUG: Cautare pattern '$SearchPattern' in PATH." }

    # Luam PATH-ul din mediul final construit (poate fi modificat de utilizator)
    if (-not $FinalEnv.ContainsKey("PATH")) {
        Write-Warning "PATH este gol sau inexistent."
        exit 1
    }

    # In Windows separatorul e ';', in Linux e ':'
    $PathSeparator = [System.IO.Path]::PathSeparator
    $Paths = $FinalEnv["PATH"] -split $PathSeparator
    $FoundAny = $false

    foreach ($dir in $Paths) {
        if (Test-Path -Path $dir) {
            # Cautam fisierele care respecta pattern-ul
            $files = Get-ChildItem -Path $dir -Filter $SearchPattern -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                Write-Output $file.FullName
                $FoundAny = $true
            }
        }
    }

    if (-not $FoundAny) { exit 1 }
    exit 0
}

#5. Executie sau Afisare

if ([string]::IsNullOrEmpty($CommandName)) {
    # CAZUL A: Nicio comanda -> Afisam variabilele
    if ($DebugMode) { Write-Host "DEBUG: Nicio comanda. Se afiseaza mediul." }

    foreach ($key in $FinalEnv.Keys) {
        $val = $FinalEnv[$key]
        if ($NullOpt) {
            # Afisare cu separator NULL (fara linie noua)
            Write-Host -NoNewline "$key=$val`0"
        } else {
            # Afisare standard
            Write-Output "$key=$val"
        }
    }
} else {
    # CAZUL B: Executam comanda in mediul modificat
    if ($DebugMode) { Write-Host "DEBUG: Se executa: $CommandName $CommandArgs" }

    try {
        # Start-Process permite definirea unui mediu specific (-Environment)
        # -NoNewWindow: ruleaza in consola curenta
        # -Wait: scriptul asteapta terminarea comenzii
        # -ArgumentList: argumentele comenzii
        
        $procInfo = New-Object System.Diagnostics.ProcessStartInfo
        $procInfo.FileName = $CommandName
        
        # Adaugam argumentele
        foreach ($arg in $CommandArgs) {
            $procInfo.ArgumentList.Add($arg)
        }

        # Setam mediul procesului
        $procInfo.Environment.Clear()
        foreach ($key in $FinalEnv.Keys) {
            $procInfo.Environment[$key] = $FinalEnv[$key]
        }
        
        $procInfo.UseShellExecute = $false
        
        $proc = [System.Diagnostics.Process]::Start($procInfo)
        $proc.WaitForExit()
        exit $proc.ExitCode
    }
    catch {
        Write-Error "env: '$CommandName': Comanda nu a putut fi executata. $_"
        exit 127
    }
}
