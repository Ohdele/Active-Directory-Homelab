param(
    [Parameter(Mandatory = $true)]
    [string]$JsonFile,

    [switch]$Undo
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned

Import-Module ActiveDirectory

$config = Get-Content $JsonFile -Raw | ConvertFrom-Json

$Domain = $config.domain

function Set-DomainPasswordPolicy {
    Set-ADDefaultDomainPasswordPolicy -Identity $Domain -MinPasswordLength 1 -ComplexityEnabled $false
}

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

function Write-AuditLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [string]$User,

        [Parameter(Mandatory = $true)]
        [string]$Details
    )

    $AuditDirectory = "C:\AD-Automation\audit"

    if (-not (Test-Path $AuditDirectory)) {
        New-Item -ItemType Directory -Path $AuditDirectory -Force | Out-Null
    }

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Add-Content -Path "$AuditDirectory\jml-audit.log" `
        -Value "$Timestamp | $Action | $User | $Details"

    Write-Host "[AUDIT] $Timestamp | $Action | $User | $Details"
}

function Process-Leaver {
    param(
        [Parameter(Mandatory = $true)]
        $User
    )

    if ($User.status -ne "Terminated") {
        return $false
    }

    $Name = $User.name
    $FirstName, $LastName = $Name -split ' ', 2
    $SamAccountName = ("{0}.{1}" -f $FirstName, $LastName).ToLower()

    $ADUser = Get-ADUser -Identity $SamAccountName -Properties Enabled -ErrorAction SilentlyContinue

    if (-not $ADUser) {
        Write-Warning "Leaver '$SamAccountName' was not found in Active Directory."
        Write-AuditLog `
            -Action "LEAVER_NOT_FOUND" `
            -User $SamAccountName `
            -Details "HR status Terminated but AD account was not found."
        return $true
    }

    Disable-ADAccount -Identity $SamAccountName

    Write-Host "[-] Disabled AD account: $SamAccountName"

    Write-AuditLog `
        -Action "ACCOUNT_DISABLED" `
        -User $SamAccountName `
        -Details "Account disabled because HR status is Terminated."

    foreach ($Group in $User.groups) {
        if (Get-ADGroup -Identity $Group -ErrorAction SilentlyContinue) {
            Remove-ADGroupMember `
                -Identity $Group `
                -Members $SamAccountName `
                -Confirm:$false `
                -ErrorAction SilentlyContinue

            Write-Host "[-] Removed $SamAccountName from $Group"

            Write-AuditLog `
                -Action "ACCESS_REVOKED" `
                -User $SamAccountName `
                -Details "Removed from group $Group."
        }
    }

    return $true
}

function Create-ADUser {
    param(
        [Parameter(Mandatory = $true)]
        $User
    )

    if ($User.status -eq "Terminated") {
        return
    }

    $Name = $User.name
    $Password = New-RandomPassword

    $FirstName, $LastName = $Name -split ' ', 2
    $SamAccountName = ("{0}.{1}" -f $FirstName, $LastName).ToLower()
    $UPN = "$SamAccountName@$Domain"

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue)) {
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

        $Description = if ($User.description) {
            $User.description
        }
        else {
            ""
        }

        if ($User.showPassword) {
            $Description = $Password
        }

        New-ADUser `
            -Name $Name `
            -GivenName $FirstName `
            -Surname $LastName `
            -SamAccountName $SamAccountName `
            -UserPrincipalName $UPN `
            -AccountPassword $SecurePassword `
            -Description $Description `
            -Enabled $true `
            -PasswordNeverExpires $true

        Write-Host "Description: [$Description]"
        Write-Host "[+] Created user: $SamAccountName"

        if ($User.employeeId) {
            Set-ADUser -Identity $SamAccountName -EmployeeID $User.employeeId
            Write-Host "[+] Employee ID: $($User.employeeId)"
        }

        if ($User.department) {
            Set-ADUser -Identity $SamAccountName -Department $User.department
            Write-Host "[+] Department: $($User.department)"
        }

        if ($User.role) {
            Set-ADUser -Identity $SamAccountName -Title $User.role
            Write-Host "[+] Role: $($User.role)"
        }

        if ($User.startDate) {
            Write-Host "[+] Start Date: $($User.startDate)"
        }
    }

    foreach ($Group in $User.groups) {
        if (Get-ADGroup -Identity $Group -ErrorAction SilentlyContinue) {
            Add-ADGroupMember `
                -Identity $Group `
                -Members $SamAccountName `
                -ErrorAction SilentlyContinue

            Write-Host "[+] Added $SamAccountName to $Group"
        }
        else {
            Write-Warning "Group '$Group' does not exist; $SamAccountName was not added."
        }
    }

    if ($User.LocalAdmin -eq $true) {
        net localgroup administrators "$Domain\$SamAccountName" /add
        Write-Host "[+] Added $SamAccountName to local Administrators"
    }

    Write-AuditLog `
        -Action "ACCOUNT_PROVISIONED" `
        -User $SamAccountName `
        -Details "Provisioned from HR source record."
}

if ($Undo) {
    Set-ADDefaultDomainPasswordPolicy `
        -Identity $Domain `
        -MinPasswordLength 7 `
        -ComplexityEnabled $true

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
    if (-not (Process-Leaver -User $User)) {
        Create-ADUser -User $User
    }
}

Write-Host ""
Write-Host "[+] Active Directory JML workflow complete."