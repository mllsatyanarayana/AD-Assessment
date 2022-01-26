Instructions to run the  Script

Open Config.ini file

Update your Domain controller name for the ConnectorDC 

example 

ConnectorDC="dc001"

dc001 is the name of your Domaincontroller Name

save the file


Step2

Edit the AD_SecurityCheck.ps1

you need to update the Email setting in line no 960,1177 and 1187

update To,from and SMtp setting if required..

Note: if you are using gmail to send the report you just update the "To" and "From" address only..




Step3

Once you save the powershell file

Open Powershell ise as an administrator

open the AD_SecurityCheck.ps1 and run it.

Note:When it asked for credentails you need to give your gmail user name and password.

Incase if the email fails you no need to worry. The reports will be saved in the folder and you can download from the folder where the script is running.
 

