# ACTIVE DIRECTORY

## Overview

Set up an Active Directory environment in a home local lab as a framework for simulating red-team attacks and blue-team defenses and showcasing realistic security scenarios.

# PART 1 — Creating Server + Workstation Virtual Environment + Active Directory Join

## Objective

Create and configure a Windows Server 2022 and Windows 10 workstation environment, deploy the Active Directory domain, and successfully join the workstation to the domain as the foundation for subsequent SOC security operations.

## Scope & Assumptions

This is Part 1 of a local VirtualBox lab containing a Windows Server 2022 Domain Controller (`DC1`), Windows 10 workstation (`WS01`), Host-Only networking, and the `DeleDFIR.local` Active Directory domain.

## Skills

Active Directory Administration, Windows Server Administration, DNS Configuration, Network Configuration, PowerShell, WinRM, Domain Management, Virtual Machine Administration, Troubleshooting.

## Tools

VirtualBox provided the isolated lab infrastructure; Windows Server 2022 hosted Active Directory Domain Services and DNS; Windows 10 served as the domain workstation; PowerShell and WinRM supported remote administration and configuration.

## Steps

![WinRM connectivity](./01_Screenshots/1-wsman-connectivity.png)

Configured and validated WinRM connectivity between the Windows 10 workstation and Windows Server to support remote administration of the Domain Controller.

![Remote PowerShell hostname verification](./01_Screenshots/1-remote-PS-hostname.png)

Established a remote PowerShell session and configured the Windows Server hostname as `DC1`.

![Static IP configuration](./01_Screenshots/2-static-ip-config.png)

Assigned `DC1` the persistent Host-Only IP address `192.168.56.110` to provide reliable communication for domain services.

![Active Directory forest deployment](./01_Screenshots/1-AD-Forest.png)

Installed Active Directory Domain Services and promoted `DC1` to the Domain Controller for the `DeleDFIR.local` forest.

![Active Directory network configuration](./01_Screenshots/2-AD-Network-Config.png)

Verified the Domain Controller network interfaces and confirmed DNS was configured to point to `DC1`.

![WS01 domain join](./01_Screenshots/1-WS01-Domain-Join.png)

Configured `WS01` to use the Domain Controller for DNS and successfully joined it to the `DeleDFIR.local` domain.

## Challenges & Troubleshooting

WS01 initially could not discover the domain because its DNS configuration was incorrect and the cloned workstation remained associated with the unavailable `DFIR.local` domain. The issue was identified through network and domain configuration checks, after which WS01 was moved to `WORKGROUP`, configured to use `192.168.56.110` for DNS, and successfully joined to `DeleDFIR.local`.

## Summary

**Investigation Findings:** Configuration evidence confirmed successful `DC1` promotion, DNS configuration, network connectivity, and `WS01` reporting `PartOfDomain: True` for `DeleDFIR.local`.

**Security Decision:** A dedicated Host-Only network and static Domain Controller IP were used to provide predictable and controlled communication between the Active Directory systems.

**Validation:** WinRM connectivity, hostname configuration, static IP configuration, AD DS deployment, DNS configuration, and the final domain-join status were validated through PowerShell and Windows configuration evidence.

## Impact

This provides a realistic Windows identity environment where SOC teams can monitor and investigate authentication, account, endpoint, DNS, and Active Directory security events.

---


# Part 2 — Automating Domain Users (Active Directory #02)

## Objective
Automate Active Directory user and group provisioning to reduce manual account-creation errors and provide a repeatable, controlled method for building domain-user environments.

## Scope & Assumptions
This lab simulates a Windows domain environment using `DC1` as the Domain Controller and `WS01` as the Windows 10 workstation, with PowerShell and JSON used for repeatable account provisioning and authentication testing.

## Skills
- Active Directory Administration
- PowerShell Automation
- Identity & Access Management
- User and Group Provisioning
- Domain Authentication
- Troubleshooting & Incident Analysis
- Security Validation
- Windows Administration

## Tools
- **Windows Server 2022 / Active Directory** — Domain Controller and identity management.
- **Windows 10 / WS01** — Domain workstation used for authentication testing.
- **PowerShell** — Automated user/group creation, remote administration, and validation.
- **VS Code** — Developed and maintained the PowerShell automation script and JSON configuration.
- **JSON** — Structured configuration for repeatable user and group provisioning.
- **WinRM** — Transferred automation files and enabled remote administration of `DC1`.
- **Active Directory Users and Computers** — Verified provisioned users and groups.

## Steps

### 1. JSON-Based AD Configuration
<img src="02_Screenshots/ad-users-grps-auto.png">

Defined users, groups, and memberships in a JSON schema and used PowerShell automation to provision the configured Active Directory environment consistently.

### 2. Automated User & Group Creation
<img src="02_Screenshots/ad-user-creation-auto.png">

Implemented `gen-ad.ps1` to create enabled domain users, generate secure random passwords, create groups, validate group existence, and assign users to their configured groups.

### 3. Domain Authentication & Validation
<img src="02_Screenshots/domain-user-auth-validation.png">

Rejoined `WS01` to `DeleDFIR.local` and validated successful domain authentication and `Employees` group membership using `whoami` and `whoami /groups`.

## Summary

**Investigation Findings:** Evidence from PowerShell execution, Active Directory Users and Computers, and workstation authentication confirmed that the JSON-driven automation successfully created enabled domain users and assigned them to the `Employees` group.

**Security Decision:** PowerShell automation with structured JSON configuration and secure random password generation was selected to reduce manual provisioning errors and avoid the intentionally weak credentials used in the reference vulnerable workflow; a known password was temporarily set for John Smith solely to validate domain authentication.

**Validation:** The workflow was validated through successful JSON parsing and WinRM file transfer, creation of the `Employees` group and configured AD users, confirmation that Michael Adeyemi was enabled and assigned to `Employees`, and successful `john.smith` authentication on `WS01` verified with `whoami` and `whoami /groups`.

## Impact

Repeatable identity provisioning and validation reduces manual administrative effort, improves consistency, and gives SOC teams clearer evidence of domain-account configuration during investigations.