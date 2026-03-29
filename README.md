# ZackLab: Windows AD Home Lab

This is my personal lab where I built out a simulated corporate network (`zacklab.local`) to get hands-on practice with Active Directory, Group Policy, PowerShell, and general Windows administration.

## The Setup
* **Physical PC:** Windows 11 Pro desktop (Ryzen 9 7900X / 32GB DDR5)
* **Hypervisor:** VMware Workstation Pro
* **Domain Controller:** Windows Server 2022 VM
* **Client VM:** Windows 11 Pro workstation joined to the domain
* **Linux VM:** Kali Linux VM used for non-Windows access testing
* **Networking:** Isolated NAT, kept off my home LAN on purpose

## What's Done
* **Built the domain:** Promoted a Windows Server 2022 VM into the domain controller for `zacklab.local`
* **Created the structure:** Built out OUs for `Accounting`, `IT`, `Sales`, `HR`, and later `Workstations`
* **Added users:** Created some accounts manually first to learn the process, then used PowerShell to bulk-add the rest
* **Set up security groups:** Used an AGDLP model with Global and Domain Local groups for each department
* **Built file shares:** Created departmental shares with NTFS and share permissions assigned through groups only
* **Fixed networking issues:** Ran into a VMware NAT subnet mismatch that broke internet access and DNS forwarding, then had to restore the DC’s static IP after DHCP overwrote it
* **Joined a workstation to the domain:** Deployed a Windows 11 client VM and joined it successfully
* **Solved a logon policy issue:** Standard users were getting a “sign-in method not allowed” error, which I traced back to a User Rights Assignment in Default Domain Policy using `rsop.msc`
* **Validated access from a real client:** Logged in as department users from the Windows 11 workstation and confirmed access worked the way it was supposed to
* **Tested token refresh behavior:** Confirmed that adding a user to a new group did not take effect until logoff/logon
* **Cleaned up workstation management:** Created a dedicated `Workstations` OU and moved the Windows 11 client out of the default `Computers` container
* **Separated GPOs by purpose:** Broke workstation policy into separate GPOs for baseline settings, user environment, and drive mapping instead of piling everything into broad/default policy
* **Tested a baseline workstation GPO:** Deployed a logon banner through `ZL-Workstation-Baseline` and confirmed it applied correctly
* **Tested drive mapping through GPO:** Used Group Policy Preferences and item-level targeting to map the Accounting share for Accounting users
* **Tested a user environment policy:** Deployed desktop wallpaper through Group Policy, confirmed it applied in the registry, and learned that the unactivated Windows 11 VM could still make the visible result look broken
* **Tested Linux access:** Connected a Kali VM to the ZackLab subnet, pointed DNS to the DC, resolved `dc-01.zacklab.local`, and authenticated to Windows SMB shares with `ZACKLAB\amartin`
* **Validated cross-platform permissions:** Confirmed `amartin` could access the `Accounting` share from Linux but was denied access to `Sales`
* **Tested a physical Linux device too:** Found that my old Lubuntu Chromebook could not reach the lab from my home network because the VMware NAT design was isolating the lab exactly the way it should

## Final Outcome
This project gave me hands-on experience with:

* Active Directory structure and OU design
* Manual and scripted user creation
* DNS dependencies and basic network troubleshooting
* Group-based access control with AGDLP
* NTFS and share permission troubleshooting
* Group Policy scope, precedence, and User Rights Assignment behavior
* Windows workstation integration and client-side testing
* Security token refresh behavior after group changes
* Drive mapping through Group Policy Preferences
* Accessing Windows-hosted resources from Linux with domain credentials

## Big Takeaways
* PowerShell saves a ton of time once the logic is clear
* Group-based permissions are way easier to manage and troubleshoot than assigning access directly to users
* DNS problems break everything upstream
* Authentication and authorization are two different problems
* User Rights Assignment in GPO can change workstation behavior fast
* Group membership changes do not show up until the user gets a fresh logon token
* A cleaner OU/GPO structure matters once the environment starts growing
* Sometimes Group Policy is working even when the visible result makes it look broken, so tools like `gpresult`, `rsop.msc`, and registry checks matter
* Linux did not need to be domain-joined to authenticate to Windows-hosted resources with domain credentials
* Once I learned how to trace the chain behind a problem, the troubleshooting started making a lot more sense

## Project Status
**Complete**

I’m stopping the lab here on purpose. I could keep adding more to it, but at this point it already did what I wanted it to do: give me a practical project that helped me build real experience with Active Directory, Group Policy, permissions, and client troubleshooting.
