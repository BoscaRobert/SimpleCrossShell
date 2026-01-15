#!/usr/bin/pwsh

# Script: mkdir.ps1
# Descriere: Implementare mkdir cu logging și validare opțiuni.

param(
    [switch]$p,          # Echivalent -p (parents)
    [switch]$v,          # Echivalent -v (verbose)
    [switch]$h,          # Help
    
    # Parametru pentru mod (permisiuni)
    [string]$m = "",     

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Directories # Lista de directoare
)

$LogFile = "summary.log"

function Print-Usage {
@"
usage: mkdir [options] DIRECTORY...

options:
  -p        nu returna eroare dacă există; creează directoarele părinte
  -v        afișează un mesaj pentru fiecare director creat
  -m MODE   (opțional) specifică modul, ex: -m 755
  -h        afișează acest mesaj
"@ | Write-Output
}

if ($h) {
    Print-Usage
    exit 0
}

if ($null -eq $Directories -or $Directories.Count -eq 0) {
    Write-Error "mkdir: lipsește operandul"
    exit 1
}

# Iterăm prin directoare
foreach ($dir in $Directories) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Construim mesajul de log
    $extraInfo = ""
    if (-not [string]::IsNullOrEmpty($m)) {
        $extraInfo = " [Mode: $m - Simulat]"
    }

    # Logăm intenția
    Add-Content -Path $LogFile -Value "[$timestamp] [mkdir-pwsh] START $dir $extraInfo" -ErrorAction SilentlyContinue

    try {
        # Pregătim parametrii pentru comanda nativă PowerShell (New-Item)
        $params = @{
            ItemType = "Directory"
            Path     = $dir
            ErrorAction = "Stop"
        }

        # -p în Linux devine -Force în PowerShell 
        # (creează părinți, nu dă eroare la existent)
        if ($p) {
            $params["Force"] = $true
        }

        # Executăm crearea
        $null = New-Item @params

        # Gestionăm afișarea (-v)
        if ($v) {
            Write-Output "mkdir: created directory '$dir'"
        }
        
        Add-Content -Path $LogFile -Value "[$timestamp] [mkdir-pwsh] SUCCESS '$dir'" -ErrorAction SilentlyContinue
    }
    catch {
        # Tratare erori specifice 
        # (excepții .NET)
        $msg = $_.Exception.Message
        
        # Emulare comportament mkdir Linux: 
        # dacă există și nu avem -p -> Eroare
        if ($msg -like "*already exists*") {
            if (-not $p) {
                Write-Error "mkdir: cannot create directory '$dir': File exists"
                Add-Content -Path $LogFile -Value "[$timestamp] [mkdir-pwsh] ERROR Exists '$dir'"
            } else {
                # Cu -p ignorăm eroarea
                Add-Content -Path $LogFile -Value "[$timestamp] [mkdir-pwsh] INFO Exists (Skipped) '$dir'"
            }
        } else {
            # Alte erori 
            # (acces denied, nume invalid)
            Write-Error $msg
            Add-Content -Path $LogFile -Value "[$timestamp] [mkdir-pwsh] ERROR '$dir' - $msg"
        }
    }
}
