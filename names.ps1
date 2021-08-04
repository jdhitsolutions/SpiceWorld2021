Return "This is a demo file, not a script to run"

#Bad
<#
ww is a private alias for Write-Warning
This version follows many bad practices
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

#Preferred
Function New-HomeFolder {
    [cmdletbinding()]
    [alias("Make-HomeFolder")]
    Param($Path, $Name, $Computername)

    Try {
        [void](Test-WSMan -ComputerName $Computername -ErrorAction Stop)
        Invoke-Command -ScriptBlock {
            $Folders = "Data", "Reports", "Public", "Documents"
            #$Home is a built-in variable so don't use that
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