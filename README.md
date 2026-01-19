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
* **GPO Battle:** Spent a lot of time fighting a GPO that wouldn't let standard users log in. Finally fixed it by forcing the policy and using a few group workarounds to verify it.

## What I'm Doing Next
* **Security Groups:** Setting up the AGDLP model so I stop managing users one-by-one.
* **File Shares:** Making departmental folders where users actually have restricted access.
* **Win11 Clients:** Adding workstations so I can actually test the user experience.

## The Big Takeaways (So Far)
* PowerShell is a massive time-saver for bulk tasks.
* DNS is usually the reason why AD is breaking.
* GPOs don't always apply as fast as you want them to.
