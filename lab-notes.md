# Windows Active Directory Lab Notes

This document tracks the work performed on the Windows Active Directory home lab over time.  
It is updated incrementally as changes are made.

---

## Initial Setup

### Host Environment
- Host OS: Windows
- CPU: AMD Ryzen 9
- RAM: 32GB
- Hypervisor: VMware Workstation Pro

### Virtualization
- Created a Windows Server 2022 virtual machine using VMware Workstation Pro
- Chose manual installation (Install OS Later) to retain full control over setup
- Installed VMware Tools to improve performance and responsiveness

### Networking
- Configured VM network adapter to use NAT
- Assigned a static IP address to the domain controller
- Configured DNS to point to the domain controller itself

### Active Directory
- Installed Active Directory Domain Services (AD DS)
- Promoted the server to a domain controller
- Created a new domain: `zacklab.local`
- Verified domain creation using Active Directory tools

### Verification
- Confirmed AD DS role is installed and running
- Verified DNS resolution using `nslookup`
- Confirmed the domain controller is operational and stable

---

## Notes
- Lab is intentionally isolated from the physical home network
- This document will be updated as organizational units, users, clients, and policies are added
