# ZackLab: Windows AD Home Lab

This is my personal lab where I'm building a simulated corporate network (`zacklab.local`) to get hands-on experience with Active Directory, Group Policy, and PowerShell.

## The Setup
* **Physical PC:** Windows 11 Pro desktop (Ryzen 9 7900X / 32GB DDR5).
* **Hypervisor:** VMware Workstation Pro running on the Win 11 host.
* **Domain Controller:** Windows Server 2022 VM acting as the DC.
* **Client VM:** Windows 11 Pro workstation joined to the domain.
* **Networking:** Isolated NAT (intentionally kept off my home LAN for now).

## What's Done
* **The DC:** Got the Domain Controller up and running.
* **The Structure:** Built out the OUs for the "Company" (Accounting, IT, Sales, and HR).
* **Users:** Added several users. Did some manually to learn the attributes, then switched to PowerShell to bulk-add the rest.
* **Security Groups (AGDLP):** Implemented Global and Domain Local groups for each department.
* **File Shares:** Created departmental file shares with proper NTFS + share permissions (RW / RO), assigned only through groups.
* **Workstation Join:** Deployed a Windows 11 client VM and successfully joined it to the domain.
* **Logon Issue:** Hit a “sign-in method not allowed” error for standard users. Traced it back to a User Rights Assignment setting in Default Domain Policy using `rsop.msc`, fixed the GPO, forced an update, and confirmed normal logons.
* **Access Validation:** Logged in as department users from the workstation and confirmed AGDLP works exactly as designed (Accounting can access Accounting, denied elsewhere).
* **Token Test:** Verified that adding a user to a new group requires logoff/logon to refresh the security token.
* **Workstations OU:** Created a dedicated `Workstations` OU and moved the Windows 11 client out of the default `Computers` container.
* **GPO Cleanup:** Broke workstation policy into separate GPOs for baseline settings, user environment, and drive mapping instead of continuing to rely on broad/default policy.
* **Baseline GPO Test:** Deployed a workstation logon banner through `ZL-Workstation-Baseline` and confirmed computer-side GPO application to the Windows 11 client.
* **Drive Mapping GPO:** Used Group Policy Preferences plus item-level targeting to automatically map the Accounting share for Accounting users.
* **User Environment GPO:** Tested desktop wallpaper deployment through Group Policy. The policy applied correctly and was confirmed in the registry, although the unactivated Windows 11 VM displayed a black background instead of the image.

## What I'm Doing Next
* Add my MacBook to the ZackLab network.
* Add my Chromebook/Linux device to the ZackLab network.
* Test what works and what breaks from non-Windows devices.
* Compare DNS, share access, and authentication behavior across Windows, macOS, and Linux.
* Wrap up the project with final documentation and closeout notes.

## The Big Takeaways (So Far)
* PowerShell is a massive time-saver once the logic is clear.
* Group-based access control makes permissions predictable.
* User Rights Assignment in GPO can override local behavior fast.
* Authentication and authorization are not the same thing.
* Group membership changes don’t apply until a new logon.
* DNS and networking mistakes will break *everything* upstream.
* A clean OU/GPO structure matters once the environment starts growing.
* Group Policy can be applying correctly even when the visible result is misleading, so tools like `gpresult`, `rsop.msc`, and the registry matter.
