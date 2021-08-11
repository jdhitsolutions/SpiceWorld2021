Return "This is a demo file you should view in your script editor."

Function New-HomeFolder {
    [cmdletbinding()]
    Param(
        [Parameter(Position = 0, HelpMessage = "Specify the username")]
        [ValidatePattern("^\w{2,15}$")]
        [string]$Name,
        [Parameter(HelpMessage = "Specify the top-level path")]
        [ValidateNotNullorEmpty()]
        [string]$Path = "D:\Users",
        [Parameter(HelpMessage = "Enter the server name")]
        [alias("server", "cn")]
        [ValidateSet("SRV1", "SRV2", "SRV3")]
        [string]$Computername = "SRV1",
        [Parameter(Mandatory, HelpMessage = "Enter an alternate credential")]
        [alias("RunAs")]
        [PSCredential]$Credential
    )

    Try {
        [void](Test-WSMan -ComputerName $Computername -Credential $Credential -ErrorAction Stop)
        Invoke-Command -ScriptBlock {
            $Folders = "Data", "Reports", "Public", "Documents"
            #$Home is a built-in variable so don't use that
            $homeFolder = New-Item -Path $using:Path -Name $using:Name -ItemType Directory
            $Folders | ForEach-Object {
                New-Item -Name $_ -Path $homeFolder.FullName -ItemType Directory
            }
        } -ComputerName $Computername -Credential $Credential
    }
    Catch {
        Write-Warning "Unable to create home folders on $Computername. $($_.exception.message)"
    }
}