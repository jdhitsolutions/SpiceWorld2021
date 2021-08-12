Return "This is a demo file you should view in your script editor."

<#
This version follows many poor PowerShell scripting practices
ww is a private alias for Write-Warning
#>
Function MakeHomeFolders {
    Param($p, $n, $server)
    Try {
        [void](Test-WSMan $server -ErrorAction Stop)
        icm {
            $strFold = "Data", "Reports", "Public", "Documents"
            $h = ni $using:p -N $using:n -i Directory
            $strFold | % { ni $h.FullName -N $_ -i Directory }
        } -cn $server
    }
    Catch {
        ww "Unable to create home folders on $server. $($_.exception.message)"
    }
}

# A preferred version, although this is far from a desired PowerShell function

Function New-HomeFolder {
    [cmdletbinding()]
    [alias("Make-HomeFolder")]
    Param($Path, $Name, $Computername)

    Try {
        #suppress the output from Test-WSMan
        [void](Test-WSMan -ComputerName $Computername -ErrorAction Stop)
        Invoke-Command -ScriptBlock {
            $Folders = "Data", "Reports", "Public", "Documents"
            #$Home is a built-in variable so use something different to avoid problems
            $homeFolder = New-Item -Path $using:Path -Name $using:Name -ItemType Directory
            $Folders | ForEach-Object {
                New-Item -Name $_ -Path $homeFolder.FullName -ItemType Directory
            }
        } -ComputerName $Computername
    }
    Catch {
        Write-Warning "Unable to create home folders on $Computername. $($_.exception.message)"
    }
}