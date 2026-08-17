param (
    [string]$OutputJson = ".\out.json"
)

$dataPath = ".\data"

$groupNames = @(Get-Content "$dataPath\group-names.txt" | ForEach-Object { $_.ToString().Trim() })
$firstNames = @(Get-Content "$dataPath\firstnames.txt" | ForEach-Object { $_.ToString().Trim() })
$lastNames  = @(Get-Content "$dataPath\lastnames.txt" | ForEach-Object { $_.ToString().Trim() })
$passwords  = @(Get-Content "$dataPath\passwords.txt" | ForEach-Object { $_.ToString().Trim() })
$availableGroups = [System.Collections.ArrayList]$groupNames

$numGroups = 10
$groups = @()

for ($i = 0; $i -lt $numGroups; $i++) {
    $newGroup = Get-Random -InputObject $availableGroups
    $groups += $newGroup
    $availableGroups.Remove($newGroup)
}

$numUsers = 20
$users = @()

$availableFirstNames = [System.Collections.ArrayList]$firstNames
$availableLastNames  = [System.Collections.ArrayList]$lastNames

for ($i = 0; $i -lt $numUsers; $i++) {
    $firstName = Get-Random -InputObject $availableFirstNames
    $lastName  = Get-Random -InputObject $availableLastNames
    $password  = Get-Random -InputObject $passwords
    $group     = Get-Random -InputObject $groups

    $newUser = @{
        Name     = "$firstName $lastName"
        Password = $password
        Groups   = @($group)
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