function Get-SystemDEPPolicy {
<# 
.SYNOPSIS 
    Get the DEP policy for a computer
 
.DESCRIPTION 
    Makes a WMI call to -Class Win32_OperatingSystem -Property DataExecutionPrevention_SupportPolicy to retrieve the DEP policy
 
.PARAMETER ComputerName 
    The computer name(s) to retrieve the info from.  
 
.EXAMPLE 
    Get-SystemDEPPolicy 
    Returns DEP policy for local machine
 
.EXAMPLE 
    get-content PClist.txt | Get-SystemDEPPolicy 


.INPUTS 
    System.String, you can pipe ComputerNames to this Function 
 
.OUTPUTS 
    ComputerName - Name of the computer
    DepPolicy   - Text description of DEP Policy
    PolicyCode  - WMI DataExecutionPrevention_SupportPolicy code
 
.NOTES 
    
    AUTHOR: Dave Bremer 
    LASTEDIT:  2016-05-26
    KEYWORDS:  
 
.LINK 
 
 
 
#> 
param ( 
    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)] 
    [Alias('CN')] 
    [String[]]$ComputerName=$env:computername
    
) 
BEGIN { 
 
    Set-StrictMode -Version Latest 
 
    ${CmdletName} = $Pscmdlet.MyInvocation.MyCommand.Name 
    
    Write-Debug -Message "${CmdletName}: Starting Begin Block"
    
 
} # end BEGIN 
 
PROCESS { 
 ForEach ($Computer in $computerName) {  
    IF (Test-Connection -ComputerName $Computer -count 2 -quiet) {
        Try {
               $policyCode = (Get-WmiObject -computer $computer -Class Win32_OperatingSystem -Property DataExecutionPrevention_SupportPolicy).DataExecutionPrevention_SupportPolicy 

              switch ($policyCode) {
                    0 {$deppolicy =  'AlwaysOff'}
                    1 {$deppolicy =  'AlwaysOn'}
                    2 {$deppolicy =  'OptIn'}
                    3 {$deppolicy =  'OptOut'}
               } #switch

           } catch {
            $policycode = $null
            $depPolicy = "WMI Error"
           }
        } else {
        $policycode = $null
            $depPolicy = "No Ping"
        }
        $prop =  @{ ComputerName = $Computer; 
                    DepPolicy = $deppolicy;
                    PolicyCode = $policyCode
                } 

       $obj = New-Object -TypeName PSObject -Property $prop
       $obj.psobject.typenames.insert(0, 'daveb.av')
       Write-Output $obj
    }
} #PROCESS

END { Write-Verbose "${CmdletName}: Finished" }  
}