<# 

.SYNOPSIS
	Purpose of this script is to report on a particular performance monitor counter --> "Packets Received Discarded" on multiple servers

.DESCRIPTION
	Script was initially created to analyse the Packets Received Discarded on multiple Exchange servers.  This is due to experiencing multiple performance issues
	and one KPI of the underlying issue was the number of discarded packets.  
	
	The script will get a collection of NICs from the specified server, and then loop through them and remove the non-physical ones.
	For example do not want to see Teredo, ISATAP or 6to4 interfaces.  For the purposes of this script we are concerned with the phycical ones, and that includes
	the "physical" NICs that are made visible in virtual guest Operating Systems.  
	
	NIC names are not hardcoded into the script else it would not be portable across physical server types and hypervisors.  
	
	Packets Received Discarded is the performance counter reported to Windows by the NIC which states how many packets were sucessfully received, 
	i.e. not corrupt or failed checksum that were discarded before the NIC could push them up the stack.  This has been documented as a known issue with certain 
	hypervisors when the virtual NIC buffer is not set high enough or there are other issues on the hypervisor host such as a configuration or performance issue.  
	
	Script will report to the screen the number of discarded packets.  

    Version 4 of this script was modified to output to a  CSV using standard methods.  
    In the CSV file there will be one line per selected interface on each server queried.  Thus if a server has two physical NICs then there will be two lines for that
    particular server.  See note above stating that logical interfaces will be filtered out.  


.ASSUMPTIONS
	Script is being executed with sufficient permissions to retrieve perfmon counters on the server(s) targeted. 

	You can live with the Write-Host cmdlets :) 

	You can add your error handling if you need it.  

	

.VERSION
  
	2.0  2-7-2014   -- Initial script released to the scripting gallery 

    3.0  22-10-2014 -- Added additional output so that the server uptime is also displayed.  This is useful to compare numbers, as servers may have been restarted at different times.  
                       Also added server OS install date at customer request, to that build time discrepencies can be noted.
                       
    4.0 14-2-2015   --  Added custom PSObject to hold output.  This allows for easy manipulation and feeding it to Export-CSV 
                        See this post for details on the subject https://gallery.technet.microsoft.com/PowerShell-Template-af07b5a3

                        Fixed a couple of spelling typos. 
                        Added example in for Get-ADComputr cmdlet. 
                        Added in Export to CSV 
                        Changed the install date to be short DateTime.  Do not care at what exact time of day server was installed just the date.  




This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, 
provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
Please note: None of the conditions outlined in the disclaimer above will supercede the terms and conditions contained within the Premier Customer Services Description.
This posting is provided "AS IS" with no warranties, and confers no rights. 

Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm.

#>

# Declare an empty array to hold the output
$Output = @()

# Declare a custom PS object. This is the template that will be copied multiple times. 
$TemplateObject = New-Object PSObject | Select-Object ServerName, DaysUptime, OSInstallDate, InterfaceName, InterfaceDrops 

# Script was intended to look at Exchange servers.  The server input can be altered to suit your particular taste and/or requirements
# For example the below line can be remmed out, and you can use Import-CSV or Get-Content to feed in a list of names.....
#
# An example of Get-Content would be:
# $ExchangeServers = Get-Content  "C:\Scripts\ServerList.txt"
#
# Or you can use an uptodate version of the AD cmdlets.  Then you can use Get-ADComputer.  For example: 
# $ExchangeServers = Get-ADComputer -Filter *  | Sort-Object Name | Select-Object Name | ForEach-Object {$_.Name  } 

# All Exchange servers in the organisation are returned, sorted to meet my OCD personality issues and the Name property is then pipe to the ForEach-Obect to render it to a string
# This allows the input to be easily swapped to a CSV, TXT file or just a list of servers in a string.....
$ExchangeServers = Get-ExchangeServer | Sort-Object Name | Select-Object Name | ForEach-Object {$_.Name  }




# Loop through the list of servers and do the necessary work per server 
ForEach ($Server In $ExchangeServers)
{
        # Will work out all of the necessary data, and then manipulate it for processing to the Output array, and for exporting to CSV 

		# Currently processing this server: 
                Write-Host "Processing server: $Server" -ForeGroundColor Magenta

		# Retrieve the Packets Received Discarded perfmon counter from the given remote server 
                $ColNetDrops = Get-Counter "\Network Interface(*)\Packets Received Discarded"  -ComputerName $Server 


        # Select the appropriate NICs.  Do not want to see ISATAP, Teredo or 6to4. This will return a collection of Interfaces. 
        # Added as three separate pipes to filter them out one by one using the -notlike operator 
                $Interfaces = $ColNetDrops.CounterSamples | Where-Object {$_.InstanceName -notlike "isatap*"} | Where-Object { $_.InstanceName -notlike "teredo*" } | Where-Object { $_.InstanceName -notlike "6to4*" } | Select-Object InstanceName, CookedValue
        
        # Display collection to screen
                $Interfaces
        
        # Get the PerfMon counter to show the system uptime from the remote computer.  Then select only the data contained in the CookedValue

                $UpTimeRaw =  ( Get-Counter  -counter "\System\System Up Time" -ComputerName $Server).countersamples | Select  CookedValue 

        # Convert the object to an integer as we need to do some arithmatic on it.  Else no workey, workey....
                $UpTimeRaw =[int]$UpTimeRaw.cookedvalue

        # Now that this is an Int, divide  by 60 to get minutes.  Then divide by 60 again to get hours.  Finally divide by 24 to show days.
        # In addition to this, also work out the hours uptime.  We will show that if uptime is less than 1 day.
                $UptimeDays  = ( ( ($UptimeRaw / 60)  /60 ) /24)  # This is Days 
                $UptimeHours = ( ($UptimeRaw / 60)  /60 )         # This is hours
        
        # Use [math] to truncate the fluff and leave us with a nice neat number

                $UptimeDays  = [math]::truncate($UptimeDays)
                $UptimeHours = [math]::truncate($UptimeHours)

        # Choose which one to show.  If the uptime is less than one day, then show hours instead. 
                IF ($UptimeDays -lt 1) 
                    {Write-Host “Uptime In Hours:”  $UptimeHours}
                Else
                    {Write-Host “Uptime In Days:”  $UptimeDays}

        
        # Workout OS Install date.  Pull this in from the remote server using WMI.  Convert the hookey WMI date over to something carbon based life units can understand....
                [datetime]$OSInstallDate = ([WMI]'').ConvertToDateTime((Get-WmiObject Win32_OperatingSystem -ComputerName $Server).InstallDate)
    
        # Use the ToShortDateString() method to remove unwanted datetime fluff.  Just care about the date. 
                Write-Host “Install Date”  $OSInstallDate.ToShortDateString()


     	# Gratuitous blank line 
                Write-Host 

        # Data has been gathered at this point.  Now to add the output to CSV capability.



        # Will add one line to the CSV per selected NIC.  If a server has two NICs that means two lines for that server.
        # This is to allow filtering based on drops and server name in Excel.  A server may have one good NIC and one bad for example.  
        # We then need to look through and process all of the NICs in the $Interfaces collection

        FOREACH ($Interface IN $Interfaces)
        {
            # Make a copy of the TemplateObject.  Then work with the copy...
            $WorkingObject = $TemplateObject | Select-Object * 
            
            # Populate the TemplateObject with the necessary details.
            $WorkingObject.ServerName      = $Server
            $WorkingObject.DaysUptime      = $UptimeDays
            $WorkingObject.OSInstallDate   = $OSInstallDate.ToShortDateString()
            $WorkingObject.InterfaceName   = $Interface.InstanceName 
            $WorkingObject.InterfaceDrops  = $Interface.CookedValue           
         
            # Append  current results to final output array 
            $Output += $WorkingObject
        }
}   

# Script is done looping at this point.  
# We can do something with the contents of $Output as it is finalised now.  

# Echo to screen 
# Not applicable to this script as we have already displayed the data whilst looping through servers.  Included for reference purposes only. 
# $Output 

# Or output to a file.  The below is an example of going to a  CSV file
# The Output.csv file is located in the same folder as the script.  This is the $PWD or Present Working Directory. 
$Output | Export-Csv -Path $PWD\Output.csv -NoTypeInformation 