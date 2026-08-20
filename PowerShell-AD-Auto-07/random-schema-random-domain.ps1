param (
    [string]$OutputJson = ".\out.json",
    [int]$UserCount = 0,
    [int]$GroupCount = 0
    ,[int]$LocalAdminCount = 0
)

$dataPath = ".\data"

$groupNames = @(Get-Content "$dataPath\group-names.txt" | ForEach-Object { $_.ToString().Trim() })
$firstNames = @(Get-Content "$dataPath\firstnames.txt" | ForEach-Object { $_.ToString().Trim() })
$lastNames  = @(Get-Content "$dataPath\lastnames.txt" | ForEach-Object { $_.ToString().Trim() })
$passwords  = @(Get-Content "$dataPath\passwords.txt" | ForEach-Object { $_.ToString().Trim() })
$availableGroups = [System.Collections.ArrayList]$groupNames

if ($GroupCount -eq 0) { $GroupCount = 1 }
if ($UserCount -eq 0) { $UserCount = 5 }
if ($LocalAdminCount -gt $UserCount) { $LocalAdminCount = $UserCount }
$groups = @()
$LocalAdminIndexes = @()

while ($LocalAdminIndexes.Count -lt $LocalAdminCount) {
    $randomIndex = Get-Random -Minimum 0 -Maximum $UserCount
    if ($LocalAdminIndexes -notcontains $randomIndex) {
        $LocalAdminIndexes += $randomIndex
    }
}

for ($i = 0; $i -lt $GroupCount; $i++) {
    $newGroup = Get-Random -InputObject $availableGroups
    $groups += $newGroup
    $availableGroups.Remove($newGroup)
}

$users = @()

$availableFirstNames = [System.Collections.ArrayList]$firstNames
$availableLastNames  = [System.Collections.ArrayList]$lastNames

for ($i = 0; $i -lt $UserCount; $i++) {
    $firstName = Get-Random -InputObject $availableFirstNames
    $lastName  = Get-Random -InputObject $availableLastNames
    $password  = Get-Random -InputObject $passwords
    $group     = Get-Random -InputObject $groups

    $newUser = @{
        Name     = "$firstName $lastName"
        Password = $password
        Groups   = @($group)
        LocalAdmin = ($LocalAdminIndexes -contains $i)
    }

    $users += $newUser
    $availableFirstNames.Remove($firstName)
    $availableLastNames.Remove($lastName)
}

$domain = @{
    Domain = "DeleDFIR.local"
    Groups = $groups
    Users  = $users
}

$json = $domain | ConvertTo-Json -Depth 5
$json | Set-Content -Path $OutputJson