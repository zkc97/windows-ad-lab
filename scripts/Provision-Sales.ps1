# 1. Define the Department and the Users
$OUPath = "OU=Sales,OU=ZackLab_Corp,DC=zacklab,DC=local"
$Password = ConvertTo-SecureString "Welcome123!" -AsPlainText -Force

# Create the OU first
New-ADOrganizationalUnit -Name "Sales" -Path "OU=ZackLab_Corp,DC=zacklab,DC=local" -ErrorAction SilentlyContinue

$Users = @(
    @{FirstName="Michael"; LastName="Scott";  UserName="mscott";   Title="Regional Manager"; Description="Sales Manager"},
    @{FirstName="Dwight";  LastName="Schrute"; UserName="dschrute"; Title="Assistant Regional Manager"; Description="Sales Rep"},
    @{FirstName="Jim";     LastName="Halpert"; UserName="jhalpert"; Title="Senior Sales Rep"; Description="Sales Rep"}
)

# 2. Loop through and create each user
foreach ($User in $Users) {
    New-ADUser -Name "$($User.FirstName) $($User.LastName)" `
               -GivenName $User.FirstName `
               -Surname $User.LastName `
               -SamAccountName $User.UserName `
               -UserPrincipalName "$($User.UserName)@zacklab.local" `
               -Path $OUPath `
               -AccountPassword $Password `
               -ChangePasswordAtLogon $true `
               -Enabled $true `
               -Title $User.Title `
               -Description $User.Description
               
    Write-Host "Created user: $($User.UserName)" -ForegroundColor Cyan
}
