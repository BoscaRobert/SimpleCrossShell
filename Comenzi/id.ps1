param(
  [switch]$u,          # doar uid
  [switch]$gid,        # doar "gid" (primar, simulat)
  [switch]$groups,     # toate grupurile
  [switch]$n,          # nume în loc de id-uri
  [switch]$h,          # help
  [string]$username    # utilizator țintă (opțional)
)

function Print-Usage {
@"
usage: id [options] [username]

options:
  -u         afișează doar UID (numeric stabil pe Windows)
  -gid       afișează doar GID (simulat)
  -groups    afișează toate grupurile
  -n         afișează nume în loc de id-uri (folosit cu -u/-gid/-groups)
  -h         afișează acest mesaj

examples:
  powershell -ExecutionPolicy Bypass -File .\id.ps1
  powershell -ExecutionPolicy Bypass -File .\id.ps1 -u
  powershell -ExecutionPolicy Bypass -File .\id.ps1 -gid
  powershell -ExecutionPolicy Bypass -File .\id.ps1 -groups -n
"@ | Write-Output
}

if ($h) {
  Print-Usage
  exit 0
}

# Scriptul determină utilizatorul țintă.
# Dacă nu se oferă username, se folosește utilizatorul curent.
$targetUser = $username
if ([string]::IsNullOrWhiteSpace($targetUser)) {
  $targetUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
}

# Scriptul încearcă să obțină o identitate Windows pentru utilizator.
# Pentru user-ul curent, se folosește token-ul complet (grupuri disponibile).
# Pentru alt user, se încearcă doar traducerea numelui în SID (limitări normale).
function Get-IdentityObject([string]$userName) {
  $currentName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
  if ($userName -eq $currentName) {
    return [System.Security.Principal.WindowsIdentity]::GetCurrent()
  }

  try {
    $acc = New-Object System.Security.Principal.NTAccount($userName)
    $sid = $acc.Translate([System.Security.Principal.SecurityIdentifier])
    return $sid
  } catch {
    return $null
  }
}

$identityObj = Get-IdentityObject $targetUser
if ($null -eq $identityObj) {
  Write-Error "id: utilizator inexistent sau nerecunoscut: $targetUser"
  exit 1
}

# Scriptul extrage SID-ul utilizatorului ca identificator primar (string).
function Get-UserSidString {
  if ($identityObj -is [System.Security.Principal.WindowsIdentity]) {
    return $identityObj.User.Value
  }
  return $identityObj.Value
}

# Scriptul produce un UID numeric stabil din SID (hash simplu).
# Se evită dependența de comenzi externe și se obține un număr repetabil.
function Get-UidNumeric {
  $sid = Get-UserSidString
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($sid)
  $hash = 0
  foreach ($b in $bytes) {
    $hash = (($hash * 31) + $b) % 2147483647
  }
  return $hash
}

function Get-UserName {
  return $targetUser
}

# Scriptul colectează grupurile doar dacă există token complet (user curent).
# Dacă ținta nu este user curent, grupurile nu pot fi enumerate sigur fără privilegii.
function Get-GroupSidList {
  $list = @()
  if ($identityObj -is [System.Security.Principal.WindowsIdentity]) {
    foreach ($gSid in $identityObj.Groups) {
      $list += $gSid.Value    }
  }
  return $list
}

# Scriptul convertește SID-urile în nume (acolo unde este posibil).
function Get-GroupNameList {
  $list = @()
  if ($identityObj -is [System.Security.Principal.WindowsIdentity]) {
    foreach ($gSid in $identityObj.Groups) {
      try {
        $list += $gSid.Translate([System.Security.Principal.NTAccount]).Value
      } catch {
        $list += $gSid.Value
      }
    }
  }
  return $list
}

# Scriptul simulează GID ca fiind primul grup din listă (dacă există).
function Get-GidValue {
  $g = Get-GroupSidList
  if ($g.Count -gt 0) { return $g[0] }
  return "unknown"
}

function Get-GidName {
  $g = Get-GroupNameList
  if ($g.Count -gt 0) { return $g[0] }
  return "unknown"
}

# Dacă utilizatorul cere -u/-gid/-groups, scriptul afișează doar acele câmpuri.
# Dacă nu cere nimic, se afișează un rezumat.
$printedAny = $false

if ($u) {
  if ($n) {
    Write-Output (Get-UserName)
  } else {
    Write-Output (Get-UidNumeric)
  }
  $printedAny = $true
}

if ($gid) {
  if ($n) {
    Write-Output (Get-GidName)
  } else {
    Write-Output (Get-GidValue)
  }
  $printedAny = $true
}

if ($groups) {
  if ($n) {
    (Get-GroupNameList) -join " " | Write-Output
  } else {
    (Get-GroupSidList) -join " " | Write-Output
  }
  $printedAny = $true
}

if ($printedAny) {
  exit 0
}

# Output default: rezumat.
$uname = Get-UserName
$uidNum = Get-UidNumeric
$uidSid = Get-UserSidString
$gidVal = Get-GidValue
$gidName = Get-GidName
$gIds = (Get-GroupSidList) -join " "
$gNames = (Get-GroupNameList) -join " "

Write-Output "user=$uname uid_num=$uidNum uid_sid=$uidSid gid=$gidVal group=$gidName groups_ids=$gIds groups_names=$gNames"