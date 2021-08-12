Return "This is a demo file you should view in your script editor."

#region Bad examples
Function Get-Server {
Param($Computername = $env:COMPUTERNAME)

$os = Get-CimInstance win32_Operatingsystem -CimSession $Computername
Write-Host ($Computername + " [" + $os.Caption + "]")
$t = Get-Process -ComputerName $Computername | sort workingset -Descending | select -First 5
Write-Host "Top processes"
$t
$c = Get-Volume -DriveLetter C -CimSession $Computername
Write-Host ("Free space on C: " + $c.SizeRemaining)
Write-Host ("Free memory: " + $os.FreePhysicalMemory)
}
Function Get-FolderReport {
    Param($Folder)

    dir $folder -file | group extension |
    select Count, Name,
    @{N = "Size"; E = { $_.group | measure length -Sum | select -expand sum } } |
    sort Size -Descending | ft -auto
}
#endregion

#region Better examples

Function Get-Server {
    [cmdletbinding()]
    [OutputType("companyServerInfo")]
    Param($Computername = $env:COMPUTERNAME)

    Write-Host "Getting server info for $Computername" -ForegroundColor Green
    $os = Get-CimInstance win32_Operatingsystem -CimSession $Computername
    $t = Get-Process -ComputerName $Computername |
    Sort-Object workingset -Descending | Select-Object -First 5
    $c = Get-Volume -DriveLetter C -CimSession $Computername
    [pscustomobject]@{
        PSTypename      = "companyServerInfo"
        Computername    = $Computername.ToUpper()
        OperatingSystem = $os.caption
        TopProcesses    = $t
        FreeDiskGB      = $c.SizeRemaining / 1GB
        FreeMemoryGB    = $os.FreePhysicalMemory / 1mb
        ReportDate      = Get-Date
    }
}
#load the custom format file
Update-FormatData .\CompanyServerinfo.format.ps1xml

Function Get-FolderReport {
    [cmdletbinding()]
    [alias("gfr")]
    [outputtype("companyFolderReport")]
    Param(
        [Parameter(Position = 0, HelpMessage = "Enter the folder path")]
        [ValidateScript( { Test-Path $_ })]
        [string]$Path = "."
    )

    $groups = Get-ChildItem -Path $Path -File |
    Where-Object { $_.Extension } | Group-Object -Property extension
    foreach ($item in $Groups) {
        $size = $item.Group | Measure-Object -Property length -Sum
        [pscustomobject]@{
            PSTypename = "companyFolderReport"
            Path       = (Convert-Path $Path)
            Extension  = $item.Name.substring(1)
            Count      = $item.Count
            Size       = $size.sum
            AuditDate  = Get-Date
        }
    }
}

Update-FormatData .\companyFolderReport.format.ps1xml
#endregion