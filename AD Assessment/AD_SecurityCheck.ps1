# First Clear any variables
Remove-Variable * -ErrorAction SilentlyContinue


# Start script execution time calculation
$ScrptStartTime = (Get-Date).ToString('dd-MM-yyyy hh:mm:ss')
$sw = [Diagnostics.Stopwatch]::StartNew()

# Get Script Directory
$Scriptpath = $($MyInvocation.MyCommand.Path)
$Dir = $(Split-Path $Scriptpath);

# Report
$runntime= (get-date -format dd_MM_yyyy-HH_mm_ss)-as [string]
$HealthReport = "$dir\Reports" + "$runntime" + ".htm"

# Logfile 
$Logfile = "$dir\Log" + "$runntime" + ".log"

#---------------------------------------------------------------------------------------------------------------------------------------------
# Functions Section
#---------------------------------------------------------------------------------------------------------------------------------------------
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
 
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information'
    )
    $LogContent = (Get-Date -f g)+" " + $Severity +"  "+$Message
    Add-Content -Path $logFile -Value $LogContent -PassThru | Write-Host

 }

 function Get-IniContent ($filePath)
{
    $ini = @{}
    switch -regex -file $FilePath
    {
        “^\[(.+)\]” # Section
        {
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        “^(;.*)$” # Comment
        {
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = “Comment” + $CommentCount
            $ini[$section][$name] = $value
        }
        “(.+?)\s*=(.*)” # Key
        {
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}

#import AD Module

try {
 Import-Module ActiveDirectory   
}

catch [System.Management.Automation.ParameterBindingException] {
     Write-Log -Message "Failed Importing Active Directory Module..!" -Severity Error
      Break;
}

#Import Configuration Params

$params = Get-IniContent -filePath "$dir\Config.ini"

#E-mail report details
$SendEmail     = $params.SMTPSettings.SendEmail.Trim()
#$emailFrom     = $params.SMTPSettings.EmailFrom.Trim()
#$emailTo       = $params.SMTPSettings.EmailTo.Trim()
#$smtpServer    = $params.SMTPSettings.SmtpServer.Trim()
$emailSubject  = $params.SMTPSettings.EmailSubject.Trim()


$DCtoConnect = $params.Config.ConnectorDC.Trim()
[string]$date = Get-Date

$DCList = @()

#---------------------------------------------------------------------------------------------------------------------------
# Setting the header for the Report
#---------------------------------------------------------------------------------------------------------------------------

[DateTime]$DisplayDate = ((get-date).ToUniversalTime())

$header = "
      <!DOCTYPE html>
		<html>
		<head>
        <link rel='shortcut icon' href='favicon.png' type='image/x-icon'>
        <meta charset='utf-8'>
		<meta name='viewport' content='width=device-width, initial-scale=1.0'>		
		<title>AD Security Check</title>
		<script type=""text/javascript"">
		  function Powershellparamater(htmlTable)
		  {
			 var myWindow = window.open('', '_blank');
			 myWindow.document.write(htmlTable);
		  }
		  window.onscroll = function (){
			 if (window.pageYOffset == 0) {
				document.getElementById(""toolbar"").style.display = ""none"";
			 }
			 else {
				if (window.pageYOffset > 150) {
				   document.getElementById(""toolbar"").style.display = ""block"";
				}
			 }
		  }
		  function HideTopButton() {
			 document.getElementById(""toolbar"").style.display = ""none"";
		  }
		</script>
		<style>
        <style>
		    #toolbar  
            {
				position: fixed;
				width: 100%;
				height: 25px;
				top: 0;
				left: 0;
				/**/
				text-align: right;
				display: none;
			}
			#backToTop  
            {
				font-family: Segoe UI;
				font-weight: bold;
				font-size: 20px;
				color: #9A2701;
				background-color: #ffffff;
			}
			#Reportrer  
            {
				width: 95%;
				margin: 0 auto;
			}
			body 
            {
				color: #333333;
				font-family: Calibri,Tahoma;
				font-size: 10pt;
				background-color: #616060;
			}
			.odd  
            {
				background-color: #ffffff;
			}
			.even  
            {
				background-color: #dddddd;
			}
			
			table
			{
				background-color: #616060;
				width: 100%;
				color: #fff;
				margin: auto;
				border: 1px groove #000000;
				border-collapse: collapse;
			}
			
			caption
			{
				background-color: #D9D7D7;
				color: #000000;
			}
			.bold_class
			{
				background-color: #ffffff;
				color: #000000;
				font-weight: 550;
			}
            td  
            {
				text-align: left;
				font-size: 14px;
				color: #000000;
				background-color: #F5F5F5;
				border: 1px groove #000000;
				
				-webkit-box-shadow: 0px 10px 10px -10px #979696;
				-moz-box-shadow: 0px 10px 10px -10px #979696;
				box-shadow: 0px 2px 2px 2px #979696;
            }
			
			td a
			{
				text-decoration: none;
				color:blue;
				word-wrap: Break-word;
			}
			
			th 
			{
				background-color: #7D7D7D;
				text-align: center;
				font-size: 14px;
				border: 1px groove #000000;
				word-wrap: Break-word;
				
				-webkit-box-shadow: 0px 10px 10px -10px #979696;
				-moz-box-shadow: 0px 10px 10px -10px #979696;
				box-shadow: 0px 2px 2px 2px #979696;
			}
			
			
			
			#container
			{
				width: 98%;
				background-color: #616060;
                margin: 0px auto;
				overflow-x:auto;
				margin-bottom: 20px;
			}
            
            #scriptexecutioncontainer
            {
				width: 80%;
				background-color: #616060;
				overflow-x:auto;
				margin-bottom: 30px;
				margin: auto;
			}
            
            #discovercontainer
            {
				width: 80%;
				background-color: #616060;
				overflow-x:auto;
				padding-top: 30px;
				margin-bottom: 30px;
				margin: auto;
			}
			#portsubcontainer
			{
				float: left;
				width: 48%;
				height: 250px;
				overflow-x:auto;
				overflow-y:auto;
			}
			#DomainUserssubcontainer
			{
				float: right;
				width: 48%;
				height: 250px;
				overflow-x:auto;
				overflow-y:auto;
			}
			#pwdplysubcontainer
			{
				float: left;
				width: 48%;
				height: 200px;
				overflow-x:auto;
				overflow-y:auto;
			}
            #delegationsubcontainer
			{
				float: left;
				width: 48%;
				height: 120px;
				overflow-x:auto;
				overflow-y:auto;
			}
            #gpppwdsubcontainer
            {
				float: right;
				width: 48%;
				height: 120px;
				overflow-x:auto;
				overflow-y:auto;
			}
            #TLBkbsubcontainer
			{
				float: right;
				width: 48%;
				height: 200px;
				overflow-x:auto;
				overflow-y:auto;
			}
			
			#krbtgtcontainer{
				width: 100%;
				overflow-y: auto;
				overflow-x:auto;
				height: 100px;
				
			}
            #groupsubcontainer
			{
				float: left;
				width: 48%;
				height: 200px;
				overflow-x:auto;
				overflow-y:auto;
			}
			.error  
			{
				text-color: #FE5959;
				text-align: left;
			}
			#titleblock
			{
				display: block;
				float: center;
				margin-left: 25%;
				margin-right: 25%;
				width: 100%;
				position: relative;
				text-align: center
				background-image:
			}
			
			#header img {
			  float: left;
			  width: 190px;
			  height: 130px;
			  /*background-color: #fff;*/
			}
			.title_class 
			{
				color: #3B1400;
				text-shadow: 0 0 1px #F42121, 0 0 1px #0A8504, 0 0 2px white;
				font-size:58px;
				text-align: center;
			}
			.passed
			{
				background-color: #6CCB19;
                text-align: left;
                color: #000000;
			}
			.failed
			{
				background-color: #FA6E59;
				text-align: left;
                color: #000000;
				text-decoration: none;
			}
			#headingbutton
			{
				display: inline-block;
				padding-top: 8px;
				padding-bottom: 8px;
				background-color: #D9D7D7;
				font-size: 16px
				font-family: 'Trebuchet MS', Arial, Helvetica, sans-serif;
				font-weight: bold;
				color: #000;
				
				width: 12%;
				text-align: center;
				
				-webkit-box-shadow: 0px 1px 1px 1px #979696;
				-moz-box-shadow: 0px 1px 1px 1px #979696;
				box-shadow: 0px 1px 1px 1px #979696;
			}
			
			#headingtabsection
			{
				width: 96%;
				margin-right: 50px;
				margin-left: 55px;
				margin-bottom: 30px;
				margin-bottom: 50px;
			}
			
			#headingbutton:active
			{
				background-color: #7C2020;
			}
			#headingbutton:hover
			{
				background-color: #7C2020;
				color: #ffffff;
			}
			
			#headingbutton:hover
			{
				background-color: #ffffff;
				color: #000000;
			}
			 #headingbutton a
			{
				color: #000000;
				font-size: 16px;
				text-decoration: none;
				
			}
			 
			#header
			{
				width: 100%
				padding: 10px;
				text-align: center;
				color: #3B1400;
				color: white;
				text-shadow: 8px 8px 12px #000000;
				font-size:50px;
				background-color: #616060;
			}
			#headerdate
			{
				color: #ffffff;
				font-size:16px;
				font-weight: bold;
				margin-bottom: 5px;
                text-align: right;	
			}
			/* Tooltip container */
			.tooltip {
			  position: relative;
			  display: inline-block;
			  border-bottom: 1px dotted black; /* If you want dots under the hoverable text */
			}
			/* Tooltip text */
			.tooltip .tooltiptext {
			  visibility: hidden;
			  width: 180px;
			  background-color: black;
			  color: #fff;
			  text-align: center;
			  padding: 5px 0;
			  border-radius: 6px;
			 
			  /* Position the tooltip text - see examples below! */
			  position: absolute;
			  z-index: 1;
			}
			/* Show the tooltip text when you mouse over the tooltip container */
			.tooltip:hover .tooltiptext {
			  visibility: visible;
			  right: 105%; 
			}
		</style>
	</head>
	<body>
	    <div id=header>
            AD Security Check Report
        </div> 
        	    <div id=headerdate>
            $DisplayDate
        </div>
   
   "
Add-Content $HealthReport $header



#---------------------------------------------------------------------------------------------------------------------------
# FSMO Roles - Domain INfo
#---------------------------------------------------------------------------------------------------------------------------

try 
{ 
      $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()  
} 
catch 
{ 
      Write-Log "Cannot connect to current Domain."
      Break;
} 
 
$Domain.DomainControllers | ForEach-Object {
$DCList += $_.Name
}

if(!$DCList)
{
   Write-Log "No Domain Controller found. Run this solution on AD server. Please try again."
   Break;
}

                                   
Write-Log "List of Domain Controllers Discovered"

# List out all machines discovered in Log File and Console
foreach ($D in $DCList) 
{
Write-Log "$D"
}

Add-Content $HealthReport $dataRow

# Check if any domain controllers left
if($DCList.Count -eq 0) {
    Write-Log -Message "As no machines left script won't continue further" -Severity Error
    Break
}

# Start Container Div and Sub container div
$dataRow = "<div id=container><div id=portsubcontainer>"
$dataRow += "<table border=1px>
<caption><h2><a name='Domain Info'>FSMO Info</h2></caption>"

$forestinfo = Get-ADForest -Server $DCtoConnect
$domaininfo = Get-ADDomain -Server $DCtoConnect

$dataRow += "<tr>
<td class=bold_class>ForestName</td>
<td >$($($forestinfo.Name).ToUpper())</td>
</tr>"
$dataRow += "<tr>
<td class=bold_class>DomainName</td>
<td >$($($domaininfo.Name).ToUpper())</td>
</tr>"
$dataRow += "<tr>
<td class=bold_class>ForestMode(FFL)</td>
<td >$($forestinfo.ForestMode)</td>
</tr>"
$dataRow += "<tr>
<td class=bold_class>DomainMode(DFL)</td>
<td >$($domaininfo.RIDMaster)</td>
</tr>"
$dataRow += "<tr>
<td class=bold_class>SchemaMaster</td>
<td >$($forestinfo.SchemaMaster)</td>
</tr>"
$dataRow += "<tr>
<td class=bold_class>DomainNamingMaster</td>
<td >$($forestinfo.DomainNamingMaster)</td>
</tr>"
$dataRow += "<tr>
<td class=bold_class>PDCEmulator</td>
<td >$($domaininfo.PDCEmulator)</td>
</tr>"
$dataRow += "<tr>
<td class=bold_class>RIDMaster</td>
<td >$($domaininfo.DomainMode)</td>
</tr>"
$dataRow += "<tr>
<td class=bold_class>InfrastructureMaster</td>
<td >$($domaininfo.InfrastructureMaster)</td>
</tr>"

Add-Content $HealthReport $dataRow
Add-Content $HealthReport "</table></div>" # End Sub Container Div

#---------------------------------------------------------------------------
# Domain Users Validation
#---------------------------------------------------------------------------
Write-Log -Message "Performing Domain Users Validation..............."
# Start Sub Container
$DomainUsers= "<Div id=DomainUserssubcontainer><table border=1px>
   <caption><h2><a name='DomainUsers'>Domain Users</h2></caption>
        "
Add-Content $HealthReport $DomainUsers

## Get Domain User Information
$LastLoggedOnDate = $(Get-Date) - $(New-TimeSpan -days $params.Config.UserLogonAge)  
$PasswordStaleDate = $(Get-Date) - $(New-TimeSpan -days $params.Config.UserPasswordAge)
$ADLimitedProperties = @("Name","Enabled","SAMAccountname","DisplayName","Enabled","LastLogonDate","PasswordLastSet","PasswordNeverExpires","PasswordNotRequired","PasswordExpired","SmartcardLogonRequired","AccountExpirationDate","AdminCount","Created","Modified","LastBadPasswordAttempt","badpwdcount","mail","CanonicalName","DistinguishedName","ServicePrincipalName","SIDHistory","PrimaryGroupID","UserAccountControl")

[array]$DomainUsers = Get-ADUser -Filter * -Property $ADLimitedProperties -Server $DCtoConnect 
[array]$DomainEnabledUsers = $DomainUsers | Where {$_.Enabled -eq $True }
[array]$DomainDisabledUsers = $DomainUsers | Where {$_.Enabled -eq $false }
[array]$DomainEnabledInactiveUsers = $DomainEnabledUsers | Where { ($_.LastLogonDate -le $LastLoggedOnDate) -AND ($_.PasswordLastSet -le $PasswordStaleDate) }

[array]$DomainUsersWithReversibleEncryptionPasswordArray = $DomainUsers | Where { $_.UserAccountControl -band 0x0080 } 
[array]$DomainUserPasswordNotRequiredArray = $DomainUsers | Where {$_.PasswordNotRequired -eq $True}
[array]$DomainUserPasswordNeverExpiresArray = $DomainUsers | Where {$_.PasswordNeverExpires -eq $True}
[array]$DomainKerberosDESUsersArray = $DomainUsers | Where { $_.UserAccountControl -band 0x200000 }
[array]$DomainUserDoesNotRequirePreAuthArray = $DomainUsers | Where {$_.DoesNotRequirePreAuth -eq $True}
[array]$DomainUsersWithSIDHistoryArray = $DomainUsers | Where {$_.SIDHistory -like "*"}

$domainusersrow = "<thead><tbody><tr>
<td class=bold_class>Total Users</td>
<td width='40%' style= 'text-align: center'>$($DomainUsers.Count)</td>
</tr>"
$domainusersrow += "<tr>
<td class=bold_class>Enabled Users</td>
<td width='40%' style= 'text-align: center'>$($DomainEnabledUsers.Count)</td>
</tr>"
$domainusersrow += "<tr>
<td class=bold_class>Disabled Users</td>
<td width='40%' style= 'text-align: center'>$($DomainDisabledUsers.Count)</td>
</tr>"
$domainusersrow += "<tr>
<td class=bold_class>Inactive Users</td>
<td width='40%' style= 'text-align: center'>$($DomainEnabledInactiveUsers.Count)</td>
</tr>"
$domainusersrow += "<tr>
<td class=bold_class>Users With Password Never Expires</td>
<td width='40%' style= 'text-align: center'>$($DomainUserPasswordNeverExpiresArray.Count)</td>
</tr>"

$domainusersrow += "<tr>
<td class=bold_class>Users With SID History</td>
<td width='40%' style= 'text-align: center'>$($DomainUsersWithSIDHistoryArray.Count)</td>
</tr>"
If($($DomainUsersWithReversibleEncryptionPasswordArray.Count) -gt 0){
    $temp = @()
    $DomainUsersWithReversibleEncryptionPasswordArray | ForEach-Object { $temp = $temp + $_.SamAccountName + "<br>" }
    $domainusersrow += "<tr>
    <td class=bold_class>Users With ReversibleEncryptionPasswordArray</td>
    <td class=failed width='40%' style= 'text-align: center'><a href='javascript:void(0)' onclick=""Powershellparamater('"+ $temp +"')"">$($DomainUsersWithReversibleEncryptionPasswordArray.Count)</a></td>
    </tr>" 
}
else{
    $domainusersrow += "<tr>
    <td class=bold_class>Users With ReversibleEncryptionPasswordArray</td>
    <td class=passed width='40%' style= 'text-align: center'>$($DomainUsersWithReversibleEncryptionPasswordArray.Count)</td>
    </tr>" 
}
If($($DomainUserPasswordNotRequiredArray.Count) -gt 0){
    $temp = @()
    $DomainUserPasswordNotRequiredArray | ForEach-Object { $temp = $temp + $_.SamAccountName + "<br>" }
    $domainusersrow += "<tr>
    <td class=bold_class>Users With Password Not Required</td>
    <td class=failed width='40%' style= 'text-align: center'><a href='javascript:void(0)' onclick=""Powershellparamater('"+ $temp +"')"">$($DomainUserPasswordNotRequiredArray.Count)</a></td>
    </tr>" 
}
else{
    $domainusersrow += "<tr>
    <td class=bold_class>Users With Password Not Required</td>
    <td class=passed width='40%' style= 'text-align: center'>$($DomainUserPasswordNotRequiredArray.Count)</td>
    </tr>" 
}

If($($DomainKerberosDESUsersArray.Count) -gt 0){
    $temp = @()
    $DomainKerberosDESUsersArray | ForEach-Object { $temp = $temp + $_.SamAccountName + "<br>" }
    $domainusersrow += "<tr>
    <td class=bold_class>Users With Kerberos DES</td>
    <td class=failed width='40%' style= 'text-align: center'><a href='javascript:void(0)' onclick=""Powershellparamater('"+ $temp +"')"">$($DomainKerberosDESUsersArray.Count)</a></td>
    </tr>" 
}
else{
    $domainusersrow += "<tr>
    <td class=bold_class>Users With Kerberos DES</td>
    <td class=passed width='40%' style= 'text-align: center'>$($DomainKerberosDESUsersArray.Count)</td>
    </tr>" 
}

If($($DomainUserDoesNotRequirePreAuthArray.Count) -gt 0){
    $temp = @()
    $DomainUserDoesNotRequirePreAuthArray | ForEach-Object { $temp = $temp + $_.SamAccountName + "<br>" }
    $domainusersrow += "<tr>
    <td class=bold_class>Users That Do Not Require Kerberos Pre-Authentication</td>
    <td class=failed width='40%' style= 'text-align: center'><a href='javascript:void(0)' onclick=""Powershellparamater('"+ $temp +"')"">$($DomainUserDoesNotRequirePreAuthArray.Count)</a></td>
    </tr>" 
}
else{
    $domainusersrow += "<tr>
    <td class=bold_class>Users That Do Not Require Kerberos Pre-Authentication</td>
    <td class=passed width='40%' style= 'text-align: center'>$($DomainUserDoesNotRequirePreAuthArray.Count)</td>
    </tr>" 
}

Add-Content $HealthReport $domainusersrow

Add-Content $HealthReport "</tbody></table></div></div>" # End Sub Container Div and Container Div
#-----------------------
# Domain Password Policy 
#-----------------------
Write-Log -Message "Determining Domain Password Policy........... "
#Start Container and Sub Container Div
$Pwdpoly = "<div id=container><div id=pwdplysubcontainer><table border=1px>
            <caption><h2><a name='Pwd Policy'>Domain Password Policy</h2></caption>
            "
Add-Content $HealthReport $Pwdpoly

[array]$DomainPasswordPolicy = Get-ADDefaultDomainPasswordPolicy -Server $DCtoConnect
$props = @("ComplexityEnabled","DistinguishedName","LockoutDuration","LockoutObservationWindow","LockoutThreshold","MaxPasswordAge","MinPasswordAge","MinPasswordLength","PasswordHistoryCount","ReversibleEncryptionEnabled")
foreach($item in $props){
    $flag= 'passed'
    If(($item -eq 'ComplexityEnabled') -and ($DomainPasswordPolicy.ComplexityEnabled -ne 'True')) { $flag = "failed" }
    If(($item -eq 'LockoutDuration') -and $DomainPasswordPolicy.LockoutDuration -lt 15) { $flag = "failed" }
    If(($item -eq 'MaxPasswordAge') -and $DomainPasswordPolicy.MaxPasswordAge -gt 60) { $flag = "failed" }
    If(($item -eq 'MinPasswordAge') -and $DomainPasswordPolicy.MinPasswordAge -lt 1) { $flag = "failed" }
    If(($item -eq 'PasswordHistoryCount') -and $DomainPasswordPolicy.PasswordHistoryCount -le '24') { $flag = "failed" }
    If(($item -eq 'ReversibleEncryptionEnabled') -and $DomainPasswordPolicy.ReversibleEncryptionEnabled -eq 'True') { $flag = "failed" }
    If(($item -eq 'MinPasswordLength') -and $DomainPasswordPolicy.MinPasswordLength -le 14) { $flag = "failed" }
    If(($item -eq 'LockoutDuration') -and $DomainPasswordPolicy.LockoutDuration -le 15) { $flag = "failed" }
    If(($item -eq 'LockoutThreshold') -and ($DomainPasswordPolicy.LockoutThreshold -gt 10 -or $DomainPasswordPolicy.LockoutThreshold -eq 0)) { $flag = "failed" }
    If(($item -eq 'LockoutObservationWindow') -and $DomainPasswordPolicy.LockoutObservationWindow -le 15) { $flag = "failed" }

    $Pwdpolyrow += "<tr>
    <td class=bold_class>$item</td>
    <td class=$flag width='40%' style= 'text-align: center'>$($DomainPasswordPolicy.$item)</td>
    </tr>"

}
Add-Content $HealthReport $Pwdpolyrow

Add-Content $HealthReport "</table></Div>" #End Sub Container

#---------------------------------------------------------------------------------------------------------------------------------------------
# Tombstone and Backup Information
#---------------------------------------------------------------------------------------------------------------------------------------------
Write-Log -Message "Checking Tombstone and Backup Information........"
# Start Sub Container
$tsbkp = "<Div id=TLBkbsubcontainer><table border=1px>
   <caption><h2><a name='tsbkp'>Tombstone & Partitions Backup</h2></caption>
         "
Add-Content $HealthReport $tsbkp

$ADRootDSE = get-adrootdse  -Server $DCtoConnect
$ADConfigurationNamingContext = $ADRootDSE.configurationNamingContext
$TombstoneObjectInfo = Get-ADObject -Identity "CN=Directory Service,CN=Windows NT,CN=Services,$ADConfigurationNamingContext" `
-Partition "$ADConfigurationNamingContext" -Properties * 
[int]$TombstoneLifetime = $TombstoneObjectInfo.tombstoneLifetime
IF ($TombstoneLifetime -eq 0) { $TombstoneLifetime = 60 }

$tsbkprow += "<tr>
<td class=bold_class>TombstoneLifetime</td>
<td width='30%' style= 'text-align: center'>$TombstoneLifetime</td>
</tr>"

[string[]]$Partitions = (Get-ADRootDSE -Server $DCtoConnect).namingContexts
$contextType = [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain
$context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext($contextType,$($domaininfo.DNSRoot))
$domainController = [System.DirectoryServices.ActiveDirectory.DomainController]::findOne($context)
ForEach($partition in $partitions)
{
   $domainControllerMetadata = $domainController.GetReplicationMetadata($partition)
   $dsaSignature = $domainControllerMetadata.Item(“dsaSignature”)
   Write-Log “$partition was backed up $($dsaSignature.LastOriginatingChangeTime.DateTime)"
    $tsbkprow += "<tr>
    <td class=bold_class>Last backup of '$partition'</td>
    <td width='30%' style= 'text-align: center'>$($dsaSignature.LastOriginatingChangeTime.ToShortDateString())</td>
    </tr>"
}

Add-Content $HealthReport $tsbkprow

Add-Content $HealthReport "</table></Div></Div>" # End Sub Container and Container Div
#---------------------------------------------------------------------------------------------------------------------------------------------
# Kerberos delegation Info
#---------------------------------------------------------------------------------------------------------------------------------------------
Write-Log -Message "Checking Kerberos delegation Info........"
# Start Sub Container
$krbtgtdel = "<div id=container><Div id=delegationsubcontainer><table border=1px>
   <caption><h2><a name='krbtgtdel'>Kerberos Delegation (Unconstrained)</h2></caption>
         <thead>
		<th>ObjectClass</th>
		<th>Count</th>
        </thead>
	       "
Add-Content $HealthReport $krbtgtdel

## Identify Accounts with Kerberos Delegation
$KerberosDelegationArray = @()
[array]$KerberosDelegationObjects =  Get-ADObject -filter { (UserAccountControl -BAND 0x0080000) -AND (PrimaryGroupID -ne '516') -AND (PrimaryGroupID -ne '521') } -Server $DCtoConnect -prop Name,ObjectClass,PrimaryGroupID,UserAccountControl,ServicePrincipalName

ForEach ($KerberosDelegationObjectItem in $KerberosDelegationObjects)
 {
    IF ($KerberosDelegationObjectItem.UserAccountControl -BAND 0x0080000)
     { $KerberosDelegationServices = 'All Services' ; $KerberosType = 'Unconstrained' }
    ELSE 
     { $KerberosDelegationServices = 'Specific Services' ; $KerberosType = 'Constrained' } 
     $KerberosDelegationObjectItem | Add-Member -MemberType NoteProperty -Name KerberosDelegationServices -Value $KerberosDelegationServices -Force
     [array]$KerberosDelegationArray += $KerberosDelegationObjectItem
 }

$Requiredpros = $KerberosDelegationArray | Select Name,ObjectClass
$Groupedresult = $Requiredpros |  Group ObjectClass -AsHashTable

$Groupedresult.Keys | ForEach-Object {
    $objs = ""
    $($Groupedresult.$PSItem.Name) | foreach { $objs = $objs + $_ + "<br>" }
    $krbtgtdelrow += "<tr>
    <td class=bold_class>$($PSItem)</td>
    <td class=failed style= 'text-align: center'><a href='javascript:void(0)' onclick=""Powershellparamater('"+ $objs +"')"">$($Groupedresult.$PSItem.Name.count)</a></td>
    </tr>"
}

Add-Content $HealthReport $krbtgtdelrow

Add-Content $HealthReport "</table></Div>" # End Sub Container 

#---------------------------------------------------------------------------------------------------------------------------------------------
# Scan SYSVOL for Group Policy Preference Passwords
#---------------------------------------------------------------------------------------------------------------------------------------------
Write-Log -Message "Scan SYSVOL for Group Policy Preference Passwords......."
# Start Sub Container
$gpppwd = "<Div id=gpppwdsubcontainer><table border=1px>
          <caption><h2><a name='krbtgtdel'>Scan SYSVOL for Group Policy Preference Passwords</h2></caption>
	       "
Add-Content $HealthReport $gpppwd

$domainname = ($domaininfo.DistinguishedName.Replace("DC=","")).replace(",",".")
$DomainSYSVOLShareScan = "\\$domainname\SYSVOL\$domainname\Policies\"
[int]$Count = 0
$Passfoundfiles = ""
$flag = "passed"
Get-ChildItem $DomainSYSVOLShareScan -Filter *.xml -Recurse |  % {
If(Select-String -Path $_.FullName -Pattern "Cpassword"){ $Passfoundfiles += $_.FullName + "</br>" ; $Count += 1; $flag= "failed" }
}
    $gpppwdrow += "<tr>
    <td class=bold_class>Items Found</td>
    <td class=$flag style= 'text-align: center'><a href='javascript:void(0)' onclick=""Powershellparamater('"+ $Passfoundfiles +"')"">$Count</a></td>
    </tr>"

Add-Content $HealthReport $gpppwdrow

Add-Content $HealthReport "</table></Div></Div>" # End Sub Container and Container Div
#-------------------------------------
# KRBTGT account info
#-------------------------------------
Write-Log -Message "Checking KRBTGT account info........"
$krbtgt = "<div id=container><div id=krbtgtcontainer><table border=1px>
   <caption><h2><a name='krbtgt'>KRBTGT Account Info</h2></caption>
         <thead>
		<th>DistinguishedName</th>
		<th>Enabled</th>
        <th>msds-keyversionnumber</th>
        <th>PasswordLastSet</th>
        <th>Created</th>
        </thead>
	        <tr>"

Add-Content $HealthReport $krbtgt

$DomainKRBTGTAccount = Get-ADUser 'krbtgt' -Server $DCtoConnect -Properties 'msds-keyversionnumber',Created,PasswordLastSet

If($(New-TimeSpan -Start ($DomainKRBTGTAccount.PasswordLastSet) -End $(Get-Date)).Days -gt 180) { $flag = "failed"
}
else { $flag = "passed" }

$SelectedPros = @("DistinguishedName","Enabled","msds-keyversionnumber","PasswordLastSet","Created")

$SelectedPros | % {

$krbtgtrow += "
    <td class=$flag style= 'text-align: center'>$($DomainKRBTGTAccount.$PSItem)</td>" 
 }

 Add-Content $HealthReport $krbtgtrow
Add-Content $HealthReport "</tr></table></div></div>"
#-----------------------
# Privileged AD Group Report
#-----------------------
Write-Log -Message "Performing Privileged AD Group Report......."
#Start Container and Sub Container Div
$group = "<div id=container><div id=groupsubcontainer><table border=1px>
            <caption><h2>Privileged AD Group Info</h2></caption>
            <thead>
		<th>Privileged Group Name</th>
		<th>Members Count</th>
        </thead>
            "
Add-Content $HealthReport $group
$ADPrivGroupArray = @(
 'Administrators',
 'Domain Admins',
 'Enterprise Admins',
 'Schema Admins',
 'Account Operators',
 'Server Operators',
 'Group Policy Creator Owners',
 'DNSAdmins',
 'Enterprise Key Admins',
 'Exchange Domain Servers',
 'Exchange Enterprise Servers',
 'Exchange Admins',
 'Organization Management',
 'Exchange Windows Permissions'
)
foreach($group in $ADPrivGroupArray){
    try
    {
    $GrpProps = Get-ADGroupMember -Identity $group -Recursive -Server $DCtoConnect -ErrorAction SilentlyContinue | select SamAccountName,distinguishedName
    $tempobj = ""
        $GrpProps | % {
            $tempobj = $tempobj + $_.SamAccountName +"(" + $_.distinguishedName + ")" + "</br>"
        }
        $grouprow += "<tr>
        <td class=bold_class>$group</td>   
        <td style= 'text-align: center'><a href='javascript:void(0)' onclick=""Powershellparamater('"+ $tempobj +"')"">$($GrpProps.SamAccountName.count)</a></td>
        </tr>"
    }
    catch{
        $grouprow += "<tr>
        <td class=bold_class>$group</td>   
        <td style= 'text-align: center'>NA</td>
        </tr>"
    }
}

Add-Content $HealthReport $grouprow

Add-Content $HealthReport "</table></Div></div>" #End Container

#---------------------------------------------------------------------------------------------------------------------------------------------
# Script Execution Time
#---------------------------------------------------------------------------------------------------------------------------------------------
$myhost = $env:COMPUTERNAME

$ScriptExecutionRow = "<div id=scriptexecutioncontainer><table>
   <caption><h2><a name='Script Execution Time'>Execution Details</h2></caption>
      <th>Start Time</th>
      <th>Stop Time</th>
		<th>Days</th>
      <th>Hours</th>
      <th>Minutes</th>
      <th>Seconds</th>
      <th>Milliseconds</th>
      <th>Script Executed on</th>
	</th>"

# Stop script execution time calculation
$sw.Stop()
$Days = $sw.Elapsed.Days
$Hours = $sw.Elapsed.Hours
$Minutes = $sw.Elapsed.Minutes
$Seconds = $sw.Elapsed.Seconds
$Milliseconds = $sw.Elapsed.Milliseconds
$ScriptStopTime = (Get-Date).ToString('dd-MM-yyyy hh:mm:ss')
$Elapsed = "<tr>
               <td>$ScrptStartTime</td>
               <td>$ScriptStopTime</td>
               <td>$Days</td>
               <td>$Hours</td>
               <td>$Minutes</td>
               <td>$Seconds</td>
               <td>$Milliseconds</td>
               <td>$myhost</td>
               
            </tr>
         "
$ScriptExecutionRow += $Elapsed
Add-Content $HealthReport $ScriptExecutionRow
Add-Content $HealthReport "</table></div>"


#---------------------------------------------------------------------------------------------------------------------------------------------
# Sending Mail
#---------------------------------------------------------------------------------------------------------------------------------------------
$c= Get-Credential
if($SendEmail -eq 'Yes' ) {

    # Send ADHealthCheck Report
    if(Test-Path $HealthReport) 
   {
        try {
            $body = "Please find AD Health Check report attached."
            $port = "25"
           Send-MailMessage -Priority High -Attachments $HealthReport -To "Enter the Receipent  email address" -From "Enter the From  email address" -SmtpServer "smtp.gmail.com" -Body $Body -Subject $emailSubject -Credential $c  -UseSsl -Port 587 -ErrorAction Stop
        } catch {       
            Write-Log 'Error in sending AD Health Check Report'
        }
    }

    
    #Send an ERROR mail if Report is not found 
    if(!(Test-Path $HealthReport)) 
    {

        try {
            $body = "ERROR: NO AD Health Check report"
            $port = "25"
            Send-MailMessage -Priority High -To $emailTo -From $emailFrom -SmtpServer $smtpServer -Body $Body -Subject $emailSubject -Port $port -ErrorAction Stop
        } catch {
            Write-Log 'Unable to send Error mail.'
        }
    }

}
else
{
    Write-Log "As Send Email is NO so report through mail is not being sent. Please find the report in Script directory."
}



###########################

Write-Host "Please wait now Fethcing the Group polcy info" -ForegroundColor Yellow

# Import the module goodness
# Requires RSAT installed and features enabled
Import-Module GroupPolicy
Import-Module ActiveDirectory

# Pick a DC to target
$Server = Get-ADDomainController -Discover | Select-Object -ExpandProperty HostName

# Grab a list of all GPOs
$GPOs = Get-GPO -All -Server $Server | Select-Object ID, Path, DisplayName, GPOStatus, WMIFilter, CreationTime, ModificationTime, User, Computer

# Create a hash table for fast GPO lookups later in the report.
# Hash table key is the policy path which will match the gPLink attribute later.
# Hash table value is the GPO object with properties for reporting.
$GPOsHash = @{}
ForEach ($GPO in $GPOs) {
    $GPOsHash.Add($GPO.Path,$GPO)
}

# Empty array to hold all possible GPO link SOMs
$gPLinks = @()

# GPOs linked to the root of the domain
# !!! Get-ADDomain does not return the gPLink attribute
$gPLinks += `
 Get-ADObject -Server $Server -Identity (Get-ADDomain).distinguishedName -Properties name, distinguishedName, gPLink, gPOptions, CanonicalName |
 Select-Object name, distinguishedName, gPLink, gPOptions, CanonicalName, @{name='Depth';expression={0}}, @{name='IsSite';expression={$false}}

# GPOs linked to OUs
# !!! Get-GPO does not return the gPLink attribute
# Calculate OU depth for graphical representation in final report
$gPLinks += `
 Get-ADOrganizationalUnit -Server $Server -Filter * -Properties name, distinguishedName, gPLink, gPOptions, CanonicalName |
 Select-Object name, distinguishedName, gPLink, gPOptions, CanonicalName, @{name='Depth';expression={($_.distinguishedName -split 'OU=').count - 1}}, @{name='IsSite';expression={$false}}

# GPOs linked to sites
$gPLinks += `
 Get-ADObject -Server $Server -LDAPFilter '(objectClass=site)' -SearchBase "CN=Sites,$((Get-ADRootDSE).configurationNamingContext)" -SearchScope OneLevel -Properties name, distinguishedName, gPLink, gPOptions, CanonicalName |
 Select-Object name, distinguishedName, gPLink, gPOptions, CanonicalName, @{name='Depth';expression={0}}, @{name='IsSite';expression={$true}}

# Empty report array
$report = @()

# Loop through all possible GPO link SOMs collected
ForEach ($SOM in $gPLinks) {
    # Filter out policy SOMs that have a policy linked
    If ($SOM.gPLink) {

        # Retrieve the replication metadata for gPLink
        $gPLinkMetadata = Get-ADReplicationAttributeMetadata -Server $Server -Object $SOM.distinguishedName -Properties gPLink
        <# 
         AttributeName : gPLink 
         AttributeValue : [LDAP://cn={4152322F-D1AD-4A46-8A48-CCBB585DDEDB},cn=policies,cn=system,DC=cohovineyard,DC=com;0] 
         FirstOriginatingCreateTime : 
         IsLinkValue : False 
        *LastOriginatingChangeDirectoryServerIdentity : CN=NTDS Settings,CN=CVDCR2,CN=Servers,CN=Ohio,CN=Sites,CN=Configuration,DC=CohoVineyard,DC=com 
        *LastOriginatingChangeDirectoryServerInvocationId : 4eab0674-680c-4036-851a-1ba76275ca01 
        *LastOriginatingChangeTime : 11/20/2014 12:39:58 PM 
         LastOriginatingChangeUsn : 533407 
         LastOriginatingDeleteTime : 
         LocalChangeUsn : 533407 
         Object : OU=Legal,DC=CohoVineyard,DC=com 
         Server : CVDCR2.CohoVineyard.com 
        *Version : 23 
        #>

        # If an OU has 'Block Inheritance' set (gPOptions=1) and no GPOs linked,
        # then the gPLink attribute is no longer null but a single space.
        # There will be no gPLinks to parse, but we need to list it with BlockInheritance.
        If ($SOM.gPLink.length -gt 1) {
            # Use @() for force an array in case only one object is returned (limitation in PS v2)
            # Example gPLink value:
            # [LDAP://cn={7BE35F55-E3DF-4D1C-8C3A-38F81F451D86},cn=policies,cn=system,DC=wingtiptoys,DC=local;2][LDAP://cn={046584E4-F1CD-457E-8366-F48B7492FBA2},cn=policies,cn=system,DC=wingtiptoys,DC=local;0][LDAP://cn={12845926-AE1B-49C4-A33A-756FF72DCC6B},cn=policies,cn=system,DC=wingtiptoys,DC=local;1]
            # Split out the links enclosed in square brackets, then filter out
            # the null result between the closing and opening brackets ][
            $links = @($SOM.gPLink -split {$_ -eq '[' -or $_ -eq ']'} | Where-Object {$_})
            # Use a for loop with a counter so that we can calculate the precedence value
            For ( $i = $links.count - 1 ; $i -ge 0 ; $i-- ) {
                # Example gPLink individual value (note the end of the string):
                # LDAP://cn={7BE35F55-E3DF-4D1C-8C3A-38F81F451D86},cn=policies,cn=system,DC=wingtiptoys,DC=local;2
                # Splitting on '/' and ';' gives us an array every time like this:
                # 0: LDAP:
                # 1: (null value between the two //)
                # 2: distinguishedName of policy
                # 3: numeric value representing gPLinkOptions (LinkEnabled and Enforced)
                $GPOData = $links[$i] -split {$_ -eq '/' -or $_ -eq ';'}
                # Add a new report row for each GPO link
                $report += New-Object -TypeName PSCustomObject -Property @{
                    IsSite            = $SOM.IsSite;
                    Depth             = $SOM.Depth;
                    Name              = $SOM.Name;
                    CanonicalName     = $SOM.CanonicalName;
                    DistinguishedName = $SOM.distinguishedName;
                    Path              = $GPOData[2];
                    Precedence        = $links.count - $i
                    GUID              = $GPOsHash[$GPOData[2]].ID;
                    DisplayName       = $GPOsHash[$GPOData[2]].DisplayName;
                    GPOStatus         = $GPOsHash[$GPOData[2]].GPOStatus;
                    WMIFilter         = $GPOsHash[$GPOData[2]].WMIFilter.Name;
                    CreationTime      = $GPOsHash[$GPOData[2]].CreationTime;
                    ModificationTime  = $GPOsHash[$GPOData[2]].ModificationTime;
                    UserVersionDS     = $GPOsHash[$GPOData[2]].User.DSVersion;
                    UserVersionSysvol = $GPOsHash[$GPOData[2]].User.SysvolVersion;
                    UserMatch         = ($GPOsHash[$GPOData[2]].User.DSVersion -eq $GPOsHash[$GPOData[2]].User.SysvolVersion);
                    ComputerVersionDS = $GPOsHash[$GPOData[2]].Computer.DSVersion;
                    ComputerVersionSysvol = $GPOsHash[$GPOData[2]].Computer.SysvolVersion;
                    ComputerMatch     = ($GPOsHash[$GPOData[2]].Computer.DSVersion -eq $GPOsHash[$GPOData[2]].Computer.SysvolVersion);
                    Config            = $GPOData[3];
                    LinkEnabled       = [bool](!([int]$GPOData[3] -band 1));
                    Enforced          = [bool]([int]$GPOData[3] -band 2);
                    BlockInheritance  = [bool]($SOM.gPOptions -band 1)
                    gPLinkVersion     = $gPLinkMetadata.Version
                    gPLinkLastOrigChgTime = $gPLinkMetadata.LastOriginatingChangeTime
                    gPLinkLastOrigChgDirServerId = $gPLinkMetadata.LastOriginatingChangeDirectoryServerIdentity
                    gPLinkLastOrigChgDirServerInvocId = $gPLinkMetadata.LastOriginatingChangeDirectoryServerInvocationId
                } # End Property hash table
            } # End For
        } Else {
            # BlockInheritance but no gPLink
            $report += New-Object -TypeName PSCustomObject -Property @{
                IsSite            = $SOM.IsSite;
                Depth             = $SOM.Depth;
                Name              = $SOM.Name;
                CanonicalName     = $SOM.CanonicalName;
                DistinguishedName = $SOM.distinguishedName;
                BlockInheritance  = [bool]($SOM.gPOptions -band 1)
                gPLinkVersion     = $gPLinkMetadata.Version
                gPLinkLastOrigChgTime = $gPLinkMetadata.LastOriginatingChangeTime
                gPLinkLastOrigChgDirServerId = $gPLinkMetadata.LastOriginatingChangeDirectoryServerIdentity
                gPLinkLastOrigChgDirServerInvocId = $gPLinkMetadata.LastOriginatingChangeDirectoryServerInvocationId
            }
        } # End If
    } Else {
        # No gPLink at this SOM
        $report += New-Object -TypeName PSCustomObject -Property @{
            IsSite            = $SOM.IsSite;
            Depth             = $SOM.Depth;
            Name              = $SOM.Name;
            CanonicalName     = $SOM.CanonicalName;
            DistinguishedName = $SOM.distinguishedName;
            BlockInheritance  = [bool]($SOM.gPOptions -band 1)
        }
    } # End If
} # End ForEach

# Tag on any unlinked GPOs to the report
ForEach ($GPO in $GPOsHash.Values) {
    If ($report.GUID -notcontains $GPO.Id) {
        $report += New-Object -TypeName PSCustomObject -Property @{
            IsSite            = $false;
            CanonicalName     = '_GPO_NOT_LINKED_';
            Path              = $GPO.Path;
            GUID              = $GPO.Id
            DisplayName       = $GPO.DisplayName;
            GPOStatus         = $GPO.GPOStatus;
            WMIFilter         = $GPO.WMIFilter.Name;
            CreationTime      = $GPO.CreationTime;
            ModificationTime  = $GPO.ModificationTime;
            UserVersionDS     = $GPO.User.DSVersion;
            UserVersionSysvol = $GPO.User.SysvolVersion;
            UserMatch         = ($GPO.User.DSVersion -eq $GPO.User.SysvolVersion);
            ComputerVersionDS = $GPO.Computer.DSVersion;
            ComputerVersionSysvol = $GPO.Computer.SysvolVersion;
            ComputerMatch     = ($GPO.Computer.DSVersion -eq $GPO.Computer.SysvolVersion);
        }
    }
}




# Output the results. User can pipe to CSV file for viewing in Excel or Out-Gridview
$report |
 Sort-Object IsSite, CanonicalName, Precedence, SOM |
 Select-Object CanonicalName, `
  @{name='SOM';expression={$_.name.PadLeft($_.name.length + ($_.depth * 5),'_')}}, `
  DistinguishedName, BlockInheritance, LinkEnabled, Enforced, Precedence, `
  DisplayName, GPOStatus, WMIFilter, GUID, CreationTime, ModificationTime, `
  UserVersionDS, UserVersionSysvol, UserMatch, ComputerVersionDS, ComputerVersionSysvol, ComputerMatch, Path, `
  gPLinkVersion, gPLinkLastOrigChgTime, gPLinkLastOrigChgDirServerId, gPLinkLastOrigChgDirServerInvocId

.\GroupPolicy.ps1 | Export-Csv .\GroupPolicy.csv -NoTypeInformation
Write-Host "Exporting GP Links Please wait" -ForegroundColor Yellow
Start-Sleep 100
$gpa = ".\GroupPolicy.csv"
Send-MailMessage -Priority High -Attachments $gpa -To "Enter the Receipent  email address" -From "Enter the From  email address" -SmtpServer "smtp.gmail.com" -Body "Please find the GPO Links" -Subject "GpLink info" -Credential $c  -UseSsl -Port 587 -ErrorAction Stop
Write-Host "Exporting of GP info completed" -ForegroundColor Green

Write-Host "Exporing Total users Please wait" -ForegroundColor Yellow
Start-Sleep 10

csvde -f userslist.csv
Write-Host "copying the file Please wait" -ForegroundColor Yellow
Start-Sleep 100
$Userlist= ".\userslist.csv"
Send-MailMessage -Priority High -Attachments $Userlist -To "Enter the Receipent  email address" -From "Enter the From  email address" -SmtpServer "smtp.gmail.com" -Body "Please find the attached Total Objects\Users List" -Subject "TotalUsersList" -Credential $c  -UseSsl -Port 587 -ErrorAction Stop
Write-Host "Exporing Total users Completed" -ForegroundColor Green