Return "This is a demo file, not a script to run"

#an example of an advanced function

Function Get-Server {
    [cmdletbinding(DefaultParameterSetName = "computer")]
    [outputtype("companyServerInfo")]
    Param(
        [Parameter(Position = 0, ValueFromPipeline,
            ValueFromPipelineByPropertyName, HelpMessage = "Enter the name of a server to query",
            ParameterSetName = "computer")]
        [string[]]$Computername = $env:COMPUTERNAME,
        [Parameter(ParameterSetName = "session", ValueFromPipeline)]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession
    )
    Begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
        $splat = @{
            ErrorAction = "Stop"
            Classname   = $null
            CimSession  = $null
        }
        #initialize an array to hold cimsessions
        $sessions = @()
    } #begin
    Process {
        Write-Verbose "Using parameter set $($pscmdlet.ParameterSetName)"
        if ($pscmdlet.ParameterSetName -eq 'computer') {
            #create a cimsession
            foreach ($computer in $computername) {
                Try {
                    Write-Verbose "Creating a temporary CIMSession to $($computer.toUpper())"
                    $sessions += New-CimSession -ComputerName $computer -ErrorAction stop
                    $tempCS = $True
                }
                Catch {
                    Write-Warning "Failed to connect to ($computer.toupper()). $($_.Exception.message)"
                }
            } #foreach computer
        }
        Else {
            $sessions += $CimSession
        }
    } #process
    End {
        foreach ($session in $sessions) {
            $splat.Cimsession = $session
            $splat.Classname = "win32_operatingsystem"
            Write-Verbose "Getting server info for $($session.computername.toUpper())"
            $os = Get-CimInstance @splat
            Write-Verbose "Getting process information"
            $splat.classname = "win32_Process"
            $processes = Get-CimInstance @splat
            Write-Verbose "Found $($processes.count) total processes"
            $cdrive = Get-Volume -DriveLetter C -CimSession $session
            [pscustomobject]@{
                PSTypename      = "companyServerInfo"
                Computername    = $os.csname
                OperatingSystem = $os.caption
                TopProcesses    = $processes | Sort-Object WorkingsetSize -Descending | Select-Object -First 5
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
    }
}