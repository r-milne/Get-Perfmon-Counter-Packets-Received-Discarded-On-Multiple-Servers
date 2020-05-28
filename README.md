# Get Perfmon Counter Packets Received Discarded On Multiple Servers
 Get Perfmon Counter Packets Received Discarded On Multiple Servers

.SYNOPSIS
Purpose of this script is to report on a particular performance monitor counter --> "Packets Received Discarded" on multiple servers.

 

Please review this blog post for the background, and further discussion. 

 

.DESCRIPTION
Script was initially created to analyse the Packets Received Discarded on multiple Exchange servers.  This is due to experiencing multiple performance issues and one KPI of the underlying issue was the number of discarded packets.  
 
The script will get a collection of NICs from the specified server, and then loop through them and remove the non-physical ones.
For example do not want to see Teredo, ISATAP or 6to4 interfaces.  For the purposes of this script we are concerned with the physical ones, and that includes the "physical" NICs that are made visible in virtual guest Operating Systems.  
 
NIC names are not hardcoded into the script else it would not be portable across physical server types and hypervisors.  
 
Packets Received Discarded is the performance counter reported to Windows by the NIC which states how many packets were sucessfully received, i.e. not corrupt or failed checksum that were discarded before the NIC could push them up the stack.  This has been documented as a known issue with certain hypervisors when the virtual NIC buffer is not set high enough or there are other issues on the hypervisor host such as a configuration or performance issue.  
 
Script will report to the screen the number of discarded packets.  If required you can modify to output to a  CSV using standard methods. 

Version 4 of this script was modified to output to a  CSV using standard methods.  
In the CSV file there will be one line per selected interface on each server queried.  Thus if a server has two physical NICs then there will be two lines for that
particular server.  See note above stating that logical interfaces will be filtered out. 

 

.ASSUMPTIONS
Script is being executed with sufficient permissions to retrieve perfmon counters on the server(s) targeted.

You can live with the Write-Host cmdlets :)

You can add your error handling if you need it. 

 

.VERSION
2.0  2-7-2014   -- Initial version

 

3.0 22-10-2014 -- Added additional output so that the server uptime is also displayed.  This is useful to compare numbers, as servers may have been restarted at different times.  Also added OS install date at customer request, so that build time discrepencies can be noted. 

 

4.0 14-2-2015   --  Added custom PSObject to hold output.  This allows for easy manipulation and feeding it to Export-CSV
                        See this post for details on the subject https://gallery.technet.microsoft.com/PowerShell-Template-af07b5a3

                        Fixed a couple of spelling typos.
                        Added example in for Get-ADComputr cmdlet.
                        Added in Export to CSV
                        Changed the install date to be short DateTime.  Do not care at what exact time of day server was installed just the date. 

 

 

.Author
Rhoderick Milne https://blog.rmilne.ca 

Disclaimer
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