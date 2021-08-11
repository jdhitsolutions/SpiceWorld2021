#requires -version 5.1
#requires -module CIMCmdlets

<#
an example of an advanced function based on earlier work

 - parameter sets
 - pipeline input
 - Verbose output
 - Comment-based help
 - function alias
 - Type update
 - formatting views
#>

Function Get-Server {
    <#
    .Synopsis
    Get company server information
    .Description
    This command will get information about company servers using WMI and the CIM
    cmdlets. You must have admin rights on the remote server. If you need to use
    alternate credentials, create a CIM session and use that with this command.
    .Parameter Computername
    Enter the name of a remote company computer.
    .Parameter CimSession
    Specify an existing CIMSession. You will need this if you need to use
    alternate credentials.
    .Parameter ProcessCount
    Specify the total number of top processes by working set size. You can enter
    a value between 1 and 50.
    .Example
    PS C:\> Get-Server dom1

   Computername: DOM1

OperatingSystem           TopProcesses                                        FreeDiskGB FreeMemGB
---------------           ------------                                        ---------- ---------
Microsoft Windows Server  WmiPrvSE.exe,MsMpEng.exe,svchost.exe,dns.exe,lsass.   115.9884         1
2019 Standard             exe
    .Example
    PS C:\> Get-CimSession | Get-Server | Select Computername,Free*

Computername       FreeDiskGB      FreeMemoryGB
------------       ----------      ------------
DOM2         117.592987060547 0.710628509521484
SRV2         118.196933746338 0.531368255615234
SRV1         111.824684143066 0.406295776367188

    Pipe existing CIMSessions to Get-Server and select specific properties.
    .Example
   PS C:\> gs dom1,dom2,srv1,srv2 -ProcessCount 1 | ft -view process


   Computername: DOM1

ProcessID Name         HandleCount WorkingSetSize CreationDate
--------- ----         ----------- -------------- ------------
     4108 WmiPrvSE.exe         822      383057920 8/4/2021 4:19:47 AM


   Computername: DOM2

ProcessID Name        HandleCount WorkingSetSize CreationDate
--------- ----        ----------- -------------- ------------
     1184 svchost.exe        3264      265658368 7/6/2021 3:44:46 PM


   Computername: SRV1

ProcessID Name        HandleCount WorkingSetSize CreationDate
--------- ----        ----------- -------------- ------------
     1420 MsMpEng.exe         435      123600896 7/6/2021 3:42:04 PM


   Computername: SRV2

ProcessID Name        HandleCount WorkingSetSize CreationDate
--------- ----        ----------- -------------- ------------
     1588 MsMpEng.exe         434      153194496 7/6/2021 3:42:03 PM


     Use the custom table view to expand processes. This example uses the command
     alias for Get-Server.
     .Example
     PS C:\> $c | Get-Server| sort os | Format-Table -view os


   OperatingSystem: Microsoft Windows 10 Enterprise

Computername       FreeMemGB ReportDate
------------       --------- ----------
WIN10                 3.0774 8/10/2021


   OperatingSystem: Microsoft Windows 10 Pro

Computername       FreeMemGB ReportDate
------------       --------- ----------
PROSPERO             34.9595 8/10/2021


   OperatingSystem: [38;5;86mMicrosoft Windows 11 Pro[0m

Computername       FreeMemGB ReportDate
------------       --------- ----------
THINKP1              18.7802 8/10/2021


   OperatingSystem: [38;5;47mMicrosoft Windows Server 2016 Standard[0m

Computername       FreeMemGB ReportDate
------------       --------- ----------
SRV2                  0.5325 8/10/2021
SRV1                  0.2766 8/10/2021


   OperatingSystem: [38;5;200mMicrosoft Windows Server 2019 Standard[0m

Computername       FreeMemGB ReportDate
------------       --------- ----------
DOM1                   0.501 8/10/2021
DOM2                  0.7004 8/10/2021

    Process a list of computer names and display the result using the custom table
    view for operating system. Operating system information will be displayed with
    ANSI formatting.

    .Inputs
    System.String
    Microsoft.Management.Infrastructure.CimSession
    .Link
    Get-CimInstance
    .Notes
    Learn more about PowerShell: http://jdhitsolutions.com/blog/essential-powershell-resources/
    #>
    [cmdletbinding(DefaultParameterSetName = "computer")]
    [alias("gs")]
    [OutputType("companyServerInfo")]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Enter the name of a server to query",
            ParameterSetName = "computer"
        )]
        [Alias("cn")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Computername = $env:COMPUTERNAME,

        [Parameter(ParameterSetName = "session", ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,

        [ValidateRange(1, 50)]
        [int]$ProcessCount = 5
    )
    Begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
        #define a hashtable of parameter values to splat for Get-CimInstance
        $splat = @{
            ErrorAction = "Stop"
            Classname   = $null
            CimSession  = $null
        }
        #initialize an array to hold cimsessions
        $sessions = @()
        Write-Verbose "Retrieving $ProcessCount top processes"
    } #begin
    Process {
        Write-Verbose "Using parameter set $($pscmdlet.ParameterSetName)"
        if ($pscmdlet.ParameterSetName -eq 'computer') {
            #create a temporary cimsession
            foreach ($computer in $computername) {
                Try {
                    Write-Verbose "Creating a temporary CIMSession to $($computer.toUpper())"
                    $sessions += New-CimSession -ComputerName $computer -ErrorAction stop
                    $tempCS = $True
                }
                Catch {
                    Write-Warning "Failed to connect to $($computer.toupper()). $($_.Exception.message)"
                }
            } #foreach computer
        }
        Else {
            $sessions += $CimSession
        }
    } #process
    End {
        foreach ($session in $sessions) {
            #update the hashtable
            $splat.Cimsession = $session
            $splat.Classname = "win32_operatingsystem"
            Write-Verbose "Getting server info for $($session.computername.toUpper())"
            #get the data 
            $os = Get-CimInstance @splat
            Write-Verbose "Getting process information"
            $splat.classname = "win32_Process"
            $processes = Get-CimInstance @splat
            Write-Verbose "Found $($processes.count) total processes"
            $cdrive = Get-Volume -DriveLetter C -CimSession $session
            #Yes, I could have built this around a PowerShell class
            [pscustomobject]@{
                PSTypename      = "companyServerInfo"
                Computername    = $os.csname
                OperatingSystem = $os.caption
                TopProcesses    = $processes | Sort-Object WorkingsetSize -Descending | Select-Object -First $ProcessCount
                FreeDiskGB      = $cdrive.SizeRemaining / 1GB
                FreeMemoryGB    = $os.FreePhysicalMemory / 1mb
                ReportDate      = Get-Date
            }
        } #foreach session

        #clear temporary sessions
        if ($tempCS) {
            Write-Verbose "Removing temporary CIMSessions"
            $sessions | Remove-CimSession
        }
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    } #end
} #close Get-Server

#region extensions

#add a type extension
#create an alias property
$td = @{
    TypeName   = "companyServerInfo"
    MemberType = "AliasProperty"
    MemberName = "os"
    Value      = "OperatingSystem"
    force      = $True
}
Update-TypeData @td

#load the custom format file
Update-FormatData $PSScriptRoot\companyserverinfo.format.ps1xml

#endregion

