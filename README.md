# ZackLab: Windows AD Home Lab

This is my personal lab where I'm building a simulated corporate network (`zacklab.local`) to get hands-on experience with Active Directory and PowerShell.

## The Setup
* **Physical PC:** My main Windows 11 Pro desktop (Ryzen 9 7900X / 32GB DDR5).
* **Hypervisor:** VMware Workstation Pro running on the Win 11 host.
* **The VM:** A single Windows Server 2022 instance acting as the Domain Controller.
* **Networking:** Isolated NAT for now (so I don't mess with my home internet).

## What's Done
* **The DC:** Got the Domain Controller up and running.
* **The Structure:** Built out the OUs for the "Company" (Accounting, IT, Sales, and HR).
* **Users:** Added several users. I did some manually to learn the attributes, then switched to PowerShell to bulk-add the rest.
* **GPO Battle:** Spent a lot of time fighting a GPO that wouldn't let standard users log in. Finally fixed it by forcing the policy and using group-based workarounds to verify identity and access.
* **Security Groups (AGDLP):** Implemented the AGDLP model using Global and Domain Local groups for each department.
* **File Shares:** Created departmental file shares with proper NTFS + share permissions (RW / RO), assigned only through groups.
* **Access Validation:** Verified permissions using Effective Access to confirm users can only see and modify what they should.

## What I'm Doing Next
* **Windows 11 Clients:** Join a Windows workstation to the domain and test real user logons.
* **Drive Mapping:** Use Group Policy to map departmental shares automatically.
* **User Experience:** Validate that permissions, access, and policies behave correctly from a client machine.
* **Networking (Later):** Transition from NAT to bridged networking once the environment is stable.

## The Big Takeaways (So Far)
* PowerShell is a massive time-saver once the logic is clear.
* AD access control makes way more sense when permissions are group-based, not user-based.
* DNS and networking mistakes will break *everything* upstream.
* GPOs don’t always apply instantly — validation tools matter.
