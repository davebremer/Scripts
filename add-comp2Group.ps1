function add-comp2group {

[CmdletBinding(DefaultParametersetName="computername")] 
[OutputType('PSobject')] 


param ( 
    [parameter(
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=1,
        ParameterSetName="computername")] 
    [Alias('CN')] 
    [String[]]$ComputerName=$env:computername,

    
    [Parameter (
        Mandatory=$True,
        Position=1,
        ValueFromPipelineByPropertyName = $False,
        
        ParameterSetName="file"
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-not (Test-Path -LiteralPath $_ -PathType Leaf)) {
                throw "File '${_}' does not exist. Please provide the path to a file (not a directory) and try again."
             } $true
         })]
        [string] $FileName,

        [Parameter (
        Mandatory=$True,
        Position=2,
        ValueFromPipelineByPropertyName = $False
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            Try { get-adGroup $_
                $true
            } Catch {
                throw "Group '${_}' does not exist. A valid group is mandatory"
             }
         })]
        [string] $GroupName
    
) 
 
BEGIN { 
   Set-StrictMode -Version Latest 
 
    ${CmdletName} = $Pscmdlet.MyInvocation.MyCommand.Name 
    
    Write-Verbose -Message "${CmdletName}: Starting Begin Block"

    $set = $PsCmdlet.ParameterSetName
    Write-Verbose ("Set: {0}" -f $Set)
   
    
    if ($set -eq "file") {
        Write-Verbose ("Filename: {0}" -f $FileName)
        $ComputerName = gc $FileName
    } 
     
     
    $tot = ($computername | measure).count   
    Write-Verbose ("Total is {0}" -f $tot)
    Write-Verbose ("Group: {0}" -f $GroupName)
 
} # BEGIN

PROCESS {
        
    foreach ( $Comp in $ComputerName ) {
        $CompResult = @{
            CompName = $Comp;
            Result = $null
            }
    
        Try {
            $ADComp = Get-ADComputer -Identity $comp -properties memberof -ErrorAction Stop
        } Catch {
            Write-Verbose "Error locating '$comp' in AD - $($_.Exception.message)"
            $CompResult.Result = "Missing from AD"           
            continue
        }
    

        if ($ADComp) {
            $compGroups = $ADComp | select -expand memberof

            If ($compGroups -like "*$GroupName*") {
                Write-Verbose ("{0},Already in group" -f $Comp)
                $CompResult.Result = "Already Group Member"
            } else {

                Try {
                    Add-ADGroupMember -Credential $cred -Identity $GroupName -Members $ADComp -Verbose -WhatIf:$WhatIf -ErrorAction Stop
                    Write-Verbose ("{0},Added" -f $Comp)
                    $CompResult.Result = "Added"

                } Catch {
                    Write-Warning "Error adding '$comp' to security group '$GroupName' - $($_.Exception.message)"
                    $CompResult.Result = "Error adding"
                }

            
            }#END If ($compGroups -like "*$GroupName*")
        
        } else {     
            Write-Verbose ("{0},Not in AD" -f $Comp)
            $CompResult.Result = "Not in AD"

        }#END if ($ADComp)

        $obj = New-Object -TypeName PSObject -Property $CompResult
        $obj.psobject.typenames.insert(0, 'daveb.Add2Group')
        Write-Output $obj
    } # foreach comp

} # PROCESS

END {
Write-Verbose "Function Get-AVProduct finished." 
} #END

} #function