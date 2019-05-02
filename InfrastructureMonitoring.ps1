$User=[Environment]::UserName
function Send-Mail ($Body,$subject) {
  $param = @{
    #SmtpServer = add smpt server of your Org and uncommnet this line.
    #From = Add the recepinet mail IDs and uncommnet this line.
    #To = Add the sender mail ID 
    Subject = $subject
    Body = $Body

  }

  Send-MailMessage @param
}


$Head = @"
<style>
  body {
    font-family: "Arial";
    font-size: 8pt;
    color: #4C607B;
    }
  th, td { 
    border: 1px solid #e57300;
    border-collapse: collapse;
    padding: 5px;
    }
  th {
    font-size: 1.2em;
    text-align: left;
    background-color: #003366;
    color: #ffffff;
    }
  td {
    color: #000000;
    }
  .even { background-color: #ffffff; }
  .odd { background-color: #bfbfbf; }
</style>
"@




#Function to check Disk status

function Check-Disk($Diskdetails){

    foreach($Diskdetail in $Diskdetails){

    $TotalSpace = [math]::Round(($Diskdetail.Size / 1GB),2)
    $FreeSpace = [math]::Round(($Diskdetail.FreeSpace / 1GB),2)
    $PercentFreeSpace = [Math]::Round((($FreeSpace/$TotalSpace)*100),2)

    #Check if Free space in Drive is less than 15 GB
    if($PercentFreeSpace -le 15){

    $global:LowDiskSpace = $true
        
    }
    

    }

}

#Function to check  service status
function Check-service ($servicestatus) {

  #Loop through each service
  foreach ($service in $ServiceStatus) {
    #Check if the service is not running

    if ($service.status -ne "Running") {
      
        $global:isStopped = $true
        
      }

    }

  }


#Take servers form the list

$serverlist = Import-Csv '.\serverslist.csv'

#Loop through each server

foreach ($serv in $serverlist) {


if($serv.UnderMaintenace -eq "NO")
{
$server = $serv.ComputerName
try {
    	
    #Collect  Drive details

    $Diskdetails = Get-WmiObject win32_logicaldisk -ComputerName $server  -Filter "DriveType = '3'"  -ErrorAction Stop
    
    $global:LowDiskSpace = $false

    #Call function to check if server is having low space in Drive
    Check-Disk $Diskdetails        

    #Collect SQL service details

    $ServiceStatus = Get-Service -ComputerName $server -Name *SQL* -ErrorAction Stop

    #Set $isStopped=$false which we will use to valdiate if the service is in failed state

    $global:isStopped = $false   

    #Call function to check if service is in stopped state and try to start and check if failed to start.

    Check-service $ServiceStatus

    #Check if the service failed to start or if the disk space is below 15% and send mail to team

    if ($global:isStopped -eq $true -or $global:LowDiskSpace -eq $false) {

        

        $subject = "Attention required on server $server "

        
        

        $ServiceName = $ServiceStatus | Select-Object @{n='Service Name';e={$_.name}},status | ConvertTo-Html -Fragment -PreContent "<h2>Service Status</h2>" | Out-String          
        
        $Disksatus = $Diskdetails | Select-Object DeviceID,@{N='Total Space (GB)';E= {$_.Size/1GB -as [INT]}},@{N='Free Space (GB)';E= {$_.FreeSpace/1GB -as [INT]}},@{N='Free Space Percentage';E= {(($_.FreeSpace/1GB -as [Int])/($_.Size/1GB -as [INT]))*100 -as [INT]}} | ConvertTo-Html -Fragment -PreContent "<h2>Disk Status</h2>"|  Out-String          
      
        $Description = ConvertTo-HTML -head $head -PostContent $ServiceName,$Disksatus,"<p style='font-family:arial;font-size:16px;color:#4C607B'>Please investigae the issue</p>" -PreContent “<p style='font-family:arial;font-size:16px;color:#4C607B'><br><br>SQL service(s) failed to start or Disk space is below 15 percentage on server $server</p>”
                
        #Send mail to team
        Send-Mail -Body $Description -Subject $subject
      
    }

  }


  #Catch errors and send mail to team

  catch {
  
      $subject = "Attention required on server $server "

      $Body = ConvertTo-HTML -head $head -PreContent “<p style='font-family:arial;font-size:12px;color:#4C607B'><br><br>Disk and SQL service check failed on server $server</p><p style='font-family:arial; color:#FF0000;'><u>Error</u>:</p><p style='font-family:arial; color:#FF0000;'>$_</p><p style='font-family:arial;font-size:12px;color:#4C607B'>Please investigae the issue</p>”

      #Send Mail

      Send-Mail -Body $Body -Subject $subject
    
  }
}
}
