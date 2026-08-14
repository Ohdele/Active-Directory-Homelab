**# ACTIVE DIRECTORY** 



**- Overview: Set up an Active Directory environment in a home local lab as a framework for simulating red-team attacks and blue-team defenses and showcasing realistic security scenarios.**



**PART 1 — Creating Server + Workstation Virtual Environment**



**- Objective:** 

**Create and configure a Windows Server 2022 and Windows 10 workstation environment, deploy the Active Directory domain, and successfully join the workstation to the domain as the foundation for subsequent SOC security operations.**



**- Scope \& Assumptions:** 

**This is Part 1 of a local VirtualBox lab containing a Windows Server 2022 Domain Controller (`DC1`), Windows 10 workstation (`WS01`), Host-Only networking, and the `DeleDFIR.local` Active Directory domain.**



**- Skills:** 

**Active Directory Administration, Windows Server Administration, DNS Configuration, Network Configuration, PowerShell, WinRM, Domain Management, Virtual Machine Administration, Troubleshooting.**



**- Tools:** 

**VirtualBox provided the isolated lab infrastructure; Windows Server 2022 hosted Active Directory Domain Services and DNS; Windows 10 served as the domain workstation; PowerShell and WinRM supported remote administration and configuration.**



**- Steps:**

&#x20; **<img src="01\_Screenshots/1-wsman-connectivity.png">**

&#x20; **Configured and validated WinRM connectivity between the Windows 10 workstation and Windows Server to support remote administration of the Domain Controller.**



&#x20; **<img src="01\_Screenshots/1-remote-PS-hostname.png">**

&#x20; **Established a remote PowerShell session and configured the Windows Server hostname as `DC1`.**



&#x20; **<img src="01\_Screenshots/2-static-ip-config.png">**

&#x20; **Assigned `DC1` the persistent Host-Only IP address `192.168.56.110` to provide reliable communication for domain services.**



&#x20; **<img src="01\_Screenshots/1-AD-Forest.png">**

&#x20; **Installed Active Directory Domain Services and promoted `DC1` to the Domain Controller for the `DeleDFIR.local` forest.**



&#x20; **<img src="01\_Screenshots/2-AD-Network-Config.png">**

&#x20; **Verified the Domain Controller network interfaces and confirmed DNS was configured to point to `DC1`.**



&#x20; **<img src="01\_Screenshots/1-WS01-Domain-Join.png">**

&#x20; **Configured `WS01` to use the Domain Controller for DNS and successfully joined it to the `DeleDFIR.local` domain.**



**- Challenges \& Troubleshooting: WS01 initially could not discover the domain because its DNS configuration was incorrect and the cloned workstation remained associated with the unavailable `DFIR.local` domain. The issue was identified through network and domain configuration checks, after which WS01 was moved to `WORKGROUP`, configured to use `192.168.56.110` for DNS, and successfully joined to `DeleDFIR.local`.**



**- Summary:**

&#x20; **Investigation Findings: Configuration evidence confirmed successful `DC1` promotion, DNS configuration, network connectivity, and `WS01` reporting `PartOfDomain: True` for `DeleDFIR.local`.**



&#x20; **Security Decision: A dedicated Host-Only network and static Domain Controller IP were used to provide predictable and controlled communication between the Active Directory systems.**



&#x20; **Validation: WinRM connectivity, hostname configuration, static IP configuration, AD DS deployment, DNS configuration, and the final domain-join status were validated through PowerShell and Windows configuration evidence.**



**- Impact:**

&#x20; **This provides a realistic Windows identity environment where SOC teams can monitor and investigate authentication, account, endpoint, DNS, and Active Directory security events.**

