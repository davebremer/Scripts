 #quick and dirty - pipe script to csv file for output (not elegant)

#needs _a creds
$cred = Get-Credential


[string[]]$CompList = Get-Content c:\temp\comp2add.txt

#[string[]]$CompList = 'pgw-006674'
[string]$GroupName = "CCL - Trend OfficeScan"
[bool]$WhatIf = $false  # set this to false to go live

foreach ($comp in $CompList) {
    
    Try {
        $ADComp = Get-ADComputer -Identity $comp -properties memberof -ErrorAction Stop
    } Catch {
        Write-Warning "Error locating '$comp' in AD - $($_.Exception.message)"

        # Continue with the next item in the list
        continue
    }
    

    if ($ADComp) {
        $compGroups = $ADComp | select -expand memberof

        If ($compGroups -like "*$GroupName*") {
            Write-Output ("{0},Already in group" -f $Comp)
        } else {

            Try {
                Add-ADGroupMember -Credential $cred -Identity $GroupName -Members $ADComp -Verbose -WhatIf:$WhatIf -ErrorAction Stop
                Write-Output ("{0},Added" -f $Comp)

            } Catch {
                Write-Warning "Error adding '$comp' to security group '$GroupName' - $($_.Exception.message)"
            }

            
        }#END If ($compGroups -like "*$GroupName*")
        
    } else {     
        Write-Output ("{0},Not in AD" -f $Comp)

    }#END if ($ADComp)

    $ADComp = $null
} 

