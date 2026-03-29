# ZackLab: Windows AD Project Logs

This is where I'm tracking my progress building out a simulated corporate network (ZackLab) to learn Active Directory, Group Policy, and PowerShell.

---

## Phase 1: The Foundation (Host & VM Setup)
- **Host Specs:** AMD Ryzen 9 7900X (12-Core) | 32GB DDR5 RAM.
- **Hypervisor:** VMware Workstation Pro.
- **VM OS:** Windows Server 2022.
- **The Install:** I skipped the "Easy Install" in VMware so I could handle the setup manually. 
- **Networking:** Set the VM to NAT. Assigned a static IP to the DC and pointed DNS to its own loopback address (127.0.0.1). 
- **Promotion:** Promoted to Domain Controller for `zacklab.local`. Verified it was healthy with `nslookup`.

---

## Phase 2: Building the Corporate Identity (ZackLab_Corp)
I wanted the lab to feel like a real company, so I built a `ZackLab_Corp` parent OU and broke it down by departments: `Accounting`, `IT`, `Sales`, and `HR`.

### The Manual Build
I started by manually creating accounts for Accounting (Kevin Malone, Angela Martin, Tara Thompson) and IT (my own `zadmin` account and Ryan Howard). 
- **Focus:** Nailing the naming conventions (`kmalone`, `amartin`) and making sure the Description and Title fields were filled out correctly.

### Scaling with PowerShell
Once I got the hang of the manual process, I used PowerShell ISE to bulk-import the Sales and HR teams (Michael, Dwight, Jim, and Pam). 
- **The Logic:** I wrote a loop that handled the UPN, job titles, and forced a password change on the first login. It’s way faster than clicking through the UI dozens of times once the company starts growing.
  
### Visual Proof
![Active Directory Hierarchy](images/ad-hierarchy-phase2.png)
![PowerShell Script Execution](images/powershell-user-script.png)
![Static IP setting](images/static_ip.png)

---

## Troubleshooting: The Internet & Subnet Headache
While I was verifying the new accounts, I realized the DC was totally offline—no internet, and the DNS forwarders were just timing out.

* **The Problem:** I found a subnet mismatch. I had the DC set to **192.168.10.10**, but VMware’s NAT service was trying to run everything on the `192.168.153.x` range. They weren't even on the same "street."
* **The Fix:** I had to go into the **VMware Virtual Network Editor** and manually force the Subnet IP to `192.168.10.0` so it would actually talk to my VM.
* **The DHCP Trap:** While I was messing with it, Windows "fixed" the connection by enabling DHCP, which immediately wiped out my static IP and broke the domain's brain. I had to go back in, kill DHCP, re-apply **192.168.10.10**, and point the Preferred DNS back to the loopback (`127.0.0.1`).
* **The Result:** It’s finally stable. Pings to `8.8.8.8` are solid, and `nslookup google.com` is resolving perfectly through the forwarders.

---

## Troubleshooting: The "Logon Battle"
I hit a major wall trying to get standard users to log into the DC for testing. Even after editing the "Allow log on locally" policy in the GPO, the server kept kicking me out with a "Method not allowed" error.

**How I fixed it:**
1. **The GPO Fight:** I tried running `gpupdate /force` about a dozen times, but the settings wouldn't "stick." I used `rsop.msc` and saw the local security policy was still winning over my domain changes.
2. **The "Nuclear" Fix:** I went into the GPMC and **Enforced** the Default Domain Controllers Policy, then did a full server restart to clear the cache.
3. **The Workaround:** I used a classic SysAdmin trick to verify the identity was working by adding Kevin Malone to the **Print Operators** group. Since that group has hard-coded rights to log into DCs, it bypassed the GPO hang-up immediately and proved the domain was healthy.

---

## Phase 3: Security Groups & File Shares (AGDLP)

With identity and structure locked in, I moved into what I consider the real core of Active Directory: access control.  
The goal of this phase was to understand (and prove) how Windows decides whether a user should be allowed to access a resource — using groups, not individual users.

I followed the AGDLP model throughout:

- **A**ccounts (users)
- **G**lobal groups (department membership)
- **D**omain **L**ocal groups (resource access)
- **P**ermissions (NTFS + share)


Users never touch permissions directly. Groups do.

---

### Departmental Share Design

I created a central share structure at: C:\Shares


Each department received its own folder:
- Accounting
- HR
- IT
- Sales

For every department, I used the same group pattern:
- `GG_<Dept>_Users` (Global)
- `DL_<Dept>_Files_RW` (Domain Local – Modify)
- `DL_<Dept>_Files_RO` (Domain Local – Read)

Global groups represent *who someone is*.  
Domain Local groups represent *what they can touch*.

---

### Accounting (Manual Build & Validation)

I started with Accounting to fully understand the mechanics before repeating the pattern.

Steps:
- Created Global and Domain Local groups
- Added Accounting users to `GG_Accounting_Users`
- Nested `GG_Accounting_Users` into `DL_Accounting_Files_RW`
- Assigned:
  - **Share permissions:** Change (RW), Read (RO)
  - **NTFS permissions:** Modify (RW), Read & Execute (RO)

I validated everything using **Advanced Security → Effective Access**.  
Once the group nesting and NTFS permissions were wired correctly, Kevin Malone showed Modify access without being granted Full Control — exactly as intended.

### Visual Proof
![Effective Access Screenshot Accounting](images/phase3-effective-access-accounting.png)


---

### HR (Manual Build + Effective Access Quirk)

I repeated the same AGDLP model for HR.

While testing, I hit a confusing situation where Effective Access initially showed no permissions, then showed the correct permissions minutes later — without any configuration changes.

Key takeaway:
- **Effective Access is a diagnostic estimate**, not a live enforcement engine
- It recalculates group nesting on demand
- A failed evaluation can show “deny” even when the ACL is correct

Re-running the test correctly showed Pam Beesly’s access to the HR share.

---

### IT (Manual Implementation)

I manually implemented IT using the same model to confirm it scaled cleanly:
- No direct user permissions
- No cross-department access
- Only IT groups present on the IT folder

By this point, the process was fully repeatable.

---

### Sales (Automated Implementation)

Once the pattern was proven, I automated the Sales department to confirm the design was scalable.

The automation:
- Created Sales Global and Domain Local groups
- Nested groups following AGDLP
- Bulk-added Sales users from the Sales OU
- Created the Sales folder and SMB share
- Applied correct Share and NTFS permissions

The setup completed in seconds and matched the manually created departments exactly.

I intentionally did not include the automation script in the repository to keep the focus on access-control design rather than code.

---


## Troubleshooting: Permissions That Look Right (But Aren’t)

Most of the issues in this phase weren’t caused by things being broken — they were caused by things being *incomplete*.

A few key problems I ran into:

* **Users with zero access despite being “in the right place.”**  
  I initially populated Global groups but forgot that they don’t grant access on their own. Until the Global group was nested into the correct Domain Local group *and* that group was present on the NTFS ACL, access was correctly denied.

* **Share permissions without NTFS permissions (and vice versa).**  
  More than once, I had one side configured correctly and the other missing. Windows requires both to allow access, and Effective Access made it very obvious when one side was missing.

* **Effective Access giving conflicting results.**  
  I saw cases where Effective Access showed no permissions, then showed the correct permissions minutes later without any configuration changes. This reinforced that Effective Access is a diagnostic estimate, not a live enforcement engine, and shouldn’t be trusted blindly.

* **Unexpected cross-department permissions.**  
  I noticed HR groups appearing on Sales and IT folders. The cause was permission inheritance or copied ACLs from the `C:\Shares` parent folder. Cleaning the parent ACL and explicitly defining permissions per department fixed the issue and prevented future leakage.

Once I slowed down and traced access from user → global group → domain local group → NTFS/share, the problems became predictable and easy to fix.


---

### Phase 3 Outcome

At this point, I’m confident I understand how Windows actually evaluates access.

Permissions are working exactly how they should:
- Users never have permissions directly
- All access flows through groups
- NTFS + Share permissions both matter
- Group nesting mistakes immediately break access (and are easy to trace once you know where to look)

I was able to build departments manually, troubleshoot broken access, and then automate the same design once it was proven. Nothing in this phase works by accident anymore — if access is denied, I know where to look and why.

This was easily the most frustrating phase so far, but also the one that made Active Directory finally “click.”


---

## Phase 4: Windows Client Integration

Today I spun up a second VM running **Windows 11 Pro** and joined it to the `zacklab.local` domain to start validating everything from a real client perspective.

### The Build
- Installed Windows 11 Pro manually (no Microsoft account, local admin only).
- Confirmed NAT networking worked.
- Set DNS manually to `192.168.10.10` (DC).
- Verified domain resolution with `nslookup zacklab.local`.
- Successfully joined the domain.

### The Logon Issue (And Why It Broke)

After joining the domain, I tried logging in as `amartin` and got:

> “The sign-in method you're trying to use isn't allowed.”

Domain Admin login worked fine, which told me:
- The trust was good.
- DNS was good.
- Authentication was working.

So the issue had to be authorization.

I used `rsop.msc` on the Windows 11 machine and found that **Default Domain Policy** was defining “Allow log on locally,” and it did NOT include `Users` or `Domain Users`.

At some point earlier, I had modified this setting while troubleshooting DC logon behavior. Because User Rights Assignment is a *replace* setting in GPO, it overwrote the default workstation behavior.

### The Fix
- Opened **Default Domain Policy** in GPMC.
- Navigated to:
  ```
  Computer Configuration → Policies → Windows Settings → Security Settings → Local Policies → User Rights Assignment
  ```
- Added `Users` back to **Allow log on locally**.
- Ran `gpupdate /force` on the Windows 11 machine.
- Rebooted.
- Verified via `rsop.msc` that the winning GPO now included `Users`.

After that, `ZACKLAB\amartin` logged in successfully.

That was a real lesson in:
- GPO scope
- Precedence
- User Rights Assignment behavior
- Authentication vs authorization

### Validating AGDLP From A Real Client

Once logged in as `amartin` (Accounting):

- She could access the **Accounting** share.
- She could NOT access **Sales** (as expected).

Then I tested token behavior:

1. While logged in, I added `amartin` to the Sales Global group.
2. Tried accessing Sales — still denied.
3. Logged out and back in.
4. Access worked.

That confirmed:
- Group membership is stamped into the token at logon.
- Tokens do not dynamically update mid-session.
- Logoff/logon regenerates the token.

Everything from Phase 3 is now validated from a real workstation.

---


## Phase 5: Workstation GPO Cleanup

This phase was about finally cleaning up the Windows side of the lab so it felt less like "everything is happening everywhere" and more like an actual managed environment.

Up to this point, I had already proven the domain join, user logons, AGDLP access, and token behavior from a real Windows 11 client. What was still missing was a cleaner workstation policy structure and some actual user/computer-level Group Policy testing.

### Creating A Real Workstations OU

The first thing I did was stop relying on the default `Computers` container and create a dedicated `Workstations` OU under `ZackLab_Corp`.

Then I moved my Windows 11 client object (`W11-CL01`) into it.

That was a small change, but an important one. It gave me a clean place to scope workstation-specific policies without mixing them into the rest of the domain.

### Building Out The GPO Structure

Once the workstation had its own OU, I created three new GPOs:

- `ZL-Workstation-Baseline`
- `ZL-User-Environment`
- `ZL-Drive-Mapping`

I linked:
- `ZL-Workstation-Baseline` to the `Workstations` OU
- `ZL-User-Environment` to `ZackLab_Corp`
- `ZL-Drive-Mapping` to `ZackLab_Corp`

This was the point where the lab finally started feeling more organized. Instead of continuing to pile settings into broad/default policy, I now had separate GPOs for:
- workstation computer settings
- user environment settings
- mapped drives

That separation alone was a huge improvement over where the lab was at the end of Phase 4.

### Workstation Baseline Test

For the first workstation policy test, I configured an interactive logon message through `ZL-Workstation-Baseline`.

The goal here was simple: prove that a computer-side GPO linked to the new `Workstations` OU was actually applying to the Windows 11 client.

At first, I thought the policy was failing, but this turned out to be a good reminder of how easy it is to test the wrong thing in Active Directory. I initially restarted the wrong machine, then verified with `gpresult /r` that the workstation GPO actually was applying to `W11-CL01`.

The reason the message still was not appearing came down to a small configuration mistake on my end: I had entered the message text, but left the message title blank. Once I corrected that, ran `gpupdate /force`, and restarted the client, the logon banner appeared as expected.

That was a good lesson in two things:
- GPO scope only matters on the correct target
- when a policy "isn't working," it may actually be applying correctly and just be configured wrong

### Visual Proof
![Phase 5 Workstation Logon Banner](images/phase5-workstation-gpo-logon-message.png)

---

### Drive Mapping Through Group Policy Preferences

After that, I moved on to drive mapping, which was one of the main goals for this phase.

Using the `ZL-Drive-Mapping` GPO, I created a mapped drive for the Accounting share:

- `A:` → `\\DC-01\Accounting`

I scoped it using **Item-level Targeting** so it only applied if the logged-in user was a member of:

- `GG_Accounting_Users`

Before setting up the policy, I manually confirmed that `amartin` could reach `\\DC-01\Accounting` from the Windows 11 client. I had to reset her password first because I had forgotten it, which honestly felt pretty realistic for help desk work.

Once the path was confirmed, I signed in as `amartin`, forced policy refresh, signed back in, and the mapped `A:` drive appeared successfully.

That was probably the most practical GPO in the whole phase because it tied together:
- user-side policy processing
- security group targeting
- share access
- real client validation

### Visual Proof
![Phase 5 Accounting Drive Mapping](images/phase5-drive-mapping-accounting-share.png)

---

### User Environment Wallpaper Test

For the user environment GPO, I wanted something visual and easy to verify, so I tested desktop wallpaper deployment.

I created a shared folder on the domain controller to host the image and used a Milwaukee Brewers March 2026 wallpaper as the test file. I framed it like a simple internal seasonal desktop deployment just to make the lab feel a little less generic.

The wallpaper policy was configured through `ZL-User-Environment` using the UNC path to the shared image.

Visually, the result on the Windows 11 client was a black background instead of the image itself. At first that looked like a failure, but after checking the registry I confirmed the wallpaper policy had actually applied correctly and was pointing to the expected shared JPG.

So the GPO itself worked. The issue was the visible result on the lab workstation, most likely because the Windows 11 VM is not activated and has personalization limitations.

That ended up being useful in its own way because it showed that:
- policy application and visible user experience are not always the same thing
- registry validation can prove a policy is applying even when the screen result looks wrong

### Visual Proof
![Phase 5 Wallpaper Policy Registry Proof](images/phase5-user-environment-wallpaper-registry-proof.png)



### Phase 5 Outcome

This phase cleaned up the Windows side of the lab a lot.

At the end of it, I now have:
- a dedicated `Workstations` OU
- a domain-joined Windows 11 client properly scoped for workstation policy
- a working computer-side baseline GPO
- a working drive mapping GPO targeted by security group
- a user-environment wallpaper GPO that applied successfully even though the client displayed a black background

This was a much more "real world" phase than I expected. It was less about building something flashy and more about understanding where policy lives, who it targets, how it applies, and how to prove whether it worked.

---


## Phase 6: Linux Client (Non-Windows Access)

At this point, I wanted to wrap up the lab by testing how ZackLab behaved from a non-Windows machine.

Originally, I planned to use my old Lubuntu Chromebook for this phase. That test turned out to be useful, but not in the way I expected. The Chromebook connected to my normal home network and could not reach the ZackLab subnet at all. Since ZackLab is still running inside VMware NAT, the physical Chromebook had no direct path to the `192.168.10.0/24` lab network.

That ended up being a useful finding on its own:

- the Chromebook was working normally
- the issue was not Linux authentication
- the real limitation was network topology
- VMware NAT was isolating the lab from external physical devices, exactly like it was supposed to

Rather than rework the whole lab around bridged networking just to force one device into it, I used a **Kali Linux VM** instead so I could stay on the same ZackLab NAT subnet and focus on the actual mixed-client testing.

### Connecting The Linux VM To ZackLab

Once the Kali VM was connected to the same VMware NAT network, it pulled an IP on the ZackLab subnet and was able to reach the domain controller successfully.

I confirmed:

- Kali had an address in the `192.168.10.0/24` range
- it could ping `192.168.10.10`
- routing to the DC was working

At first, DNS on the Kali VM was still pointing to the VMware NAT gateway instead of the domain controller. That meant direct IP connectivity worked, but normal ZackLab name resolution did not.

After updating the Linux VM to use the DC (`192.168.10.10`) as its DNS server, I was able to successfully resolve:

- `dc-01.zacklab.local`
- `zacklab.local`

I also confirmed that `ping dc-01.zacklab.local` worked normally once DNS was corrected.

That was an important reminder that the same rule still applied on Linux as it did everywhere else in this project:

**if DNS is wrong, Active Directory breaks upstream.**

### Visual Proof
![Phase 6 Kali DNS and DC Connectivity](images/phase6-dc-connection.png)

### Testing SMB Access With Domain Credentials

Once name resolution was working, I moved on to the real goal of the phase: testing access to Windows-hosted shares from Linux using a ZackLab domain user.

Using `smbclient`, I authenticated from Kali with:

- `ZACKLAB\amartin`

That successfully returned the list of available shares on `DC-01`, including:

- `Accounting`
- `Sales`
- `NETLOGON`
- `SYSVOL`
- `Wallpapers`

From there, I tested actual share access.

Results:

- `amartin` could access the **Accounting** share successfully
- `amartin` could **not** access the **Sales** share

That was the exact result I wanted.

It proved that the same access-control model I built earlier in the lab was still working correctly from a non-Windows client:

- Linux did not need to be domain-joined
- AD DNS still mattered
- Windows SMB shares were reachable cross-platform
- domain credentials were accepted from Linux
- departmental permissions were still enforced correctly

### Visual Proof
![Phase 6 Linux SMB Access to Accounting Share](images/phase6-fromlinux.png)

### Phase 6 Outcome

This phase ended up being a really strong final validation step because it showed the lab worked beyond a single Windows workstation.

At the end of it, I had confirmed:

- a physical Linux Chromebook on the home LAN could not reach the isolated VMware NAT lab without additional routing
- a Linux VM on the ZackLab subnet could reach the DC normally
- Linux name resolution worked once the VM used the domain controller for DNS
- a domain user could authenticate from Linux to Windows SMB shares
- Accounting access worked
- Sales access was denied

That gave me exactly what I wanted out of this phase: proof that ZackLab could support realistic mixed-client access testing without turning into an endless networking side quest.

---

## Final Project Outcome

At this point, ZackLab feels complete.

What started as “spin up a domain controller and make some users” turned into a much more useful hands-on lab than I expected. I ended up getting practical experience with:

- Active Directory structure and OU design
- manual and scripted user creation
- DNS dependencies
- NAT troubleshooting
- Group Policy scope and precedence
- User Rights Assignment behavior
- AGDLP permissions design
- NTFS and share permission troubleshooting
- Windows client integration
- token behavior after group changes
- workstation GPO structure
- drive mapping through Group Policy Preferences
- non-Windows access to Windows-hosted resources

The biggest takeaway from the whole project is that most AD problems are not random once you understand the chain behind them.

Almost everything I ran into eventually traced back to one of a few things:

- DNS
- scope
- group nesting
- NTFS/share mismatch
- token refresh timing
- testing the wrong target

That probably sounds obvious now, but it definitely did not feel obvious when I was in the middle of breaking and fixing it.

More than anything, this lab helped me get past the point of just “knowing what Active Directory is” and into actually understanding how it behaves when something goes wrong.

---

## Final Notes

I’m intentionally stopping the project here.

There is always more I *could* add — more devices, more policies, more services, deeper Linux integration, deeper automation — but at this point I think the lab already did what I needed it to do.

It gave me a practical hands-on project that helped me build real troubleshooting experience in:

- Windows administration
- identity and access control
- Group Policy
- client behavior
- mixed-environment support

That was the goal from the beginning, and I feel like ZackLab accomplished it.

---

## Final Status

- Domain controller built and stabilized
- `zacklab.local` functioning correctly
- DNS working properly
- departmental OU structure built
- users created manually and with PowerShell
- AGDLP permissions model implemented and validated
- departmental shares working with correct access control
- Windows 11 client domain-joined and tested
- workstation GPO structure cleaned up
- logon banner deployed successfully
- Accounting drive mapping deployed successfully
- wallpaper GPO applied and verified in registry
- Linux client validated against ZackLab
- domain-based SMB access confirmed from Linux
- cross-department denial confirmed from Linux
- project complete
