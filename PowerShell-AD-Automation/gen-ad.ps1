param(
    [Parameter(Mandatory = $true)]
    [string]$JsonFile,

    [switch]$Undo
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned

Import-Module ActiveDirectory

$config = Get-Content $JsonFile -Raw | ConvertFrom-Json

$Domain = $config.domain

function Set-DomainPasswordPolicy { Set-ADDefaultDomainPasswordPolicy -Identity $Domain -MinPasswordLength 1 -ComplexityEnabled $false }

Set-DomainPasswordPolicy

function Create-ADGroup {
    param(
        [Parameter(Mandatory = $true)]
        $Group
    )

    $GroupName = if ($Group -is [string]) { $Group } else { $Group.name }

    if (-not (Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $GroupName -GroupScope Global
        Write-Host "[+] Created group: $GroupName"
    }
}

function New-RandomPassword {
    Add-Type -AssemblyName System.Web
    return [System.Web.Security.Membership]::GeneratePassword(16, 4)
}

function Create-ADUser {
    param(
        [Parameter(Mandatory = $true)]
        $User
    )

    $Name = $User.name
    $Password = New-RandomPassword

    $FirstName, $LastName = $Name -split ' ', 2
    $SamAccountName = ("{0}.{1}" -f $FirstName, $LastName).ToLower()
    $UPN = "$SamAccountName@$Domain"

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue)) {
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

        New-ADUser `
            -Name $Name `
            -GivenName $FirstName `
            -Surname $LastName `
            -SamAccountName $SamAccountName `
            -UserPrincipalName $UPN `
            -AccountPassword $SecurePassword `
            -Enabled $true

        Write-Host "[+] Created user: $SamAccountName"
    }

    foreach ($Group in $User.groups) {
        if (Get-ADGroup -Identity $Group -ErrorAction SilentlyContinue) {
            Add-ADGroupMember -Identity $Group -Members $SamAccountName
            Write-Host "[+] Added $SamAccountName to $Group"
        }
        else {
            Write-Warning "Group '$Group' does not exist; $SamAccountName was not added."
        }
    }
}

if ($Undo) {
    Set-ADDefaultDomainPasswordPolicy -Identity $Domain -MinPasswordLength 7 -ComplexityEnabled $true

    foreach ($User in $config.users) {
        $FirstName, $LastName = $User.name -split ' ', 2
        $SamAccountName = ("{0}.{1}" -f $FirstName, $LastName).ToLower()

        if (Get-ADUser -Identity $SamAccountName -ErrorAction SilentlyContinue) {
            Remove-ADUser -Identity $SamAccountName -Confirm:$false
            Write-Host "[-] Removed user: $SamAccountName"
        }
    }

    foreach ($Group in $config.groups) {
        $GroupName = if ($Group -is [string]) { $Group } else { $Group.name }

        if (Get-ADGroup -Identity $GroupName -ErrorAction SilentlyContinue) {
            Remove-ADGroup -Identity $GroupName -Confirm:$false
            Write-Host "[-] Removed group: $GroupName"
        }
    }

    Write-Host "[+] Active Directory environment reverted."
    return
}

foreach ($Group in $config.groups) {
    Create-ADGroup -Group $Group
}

foreach ($User in $config.users) {
    Create-ADUser -User $User
}

Write-Host ""
Write-Host "[+] Active Directory environment creation complete."