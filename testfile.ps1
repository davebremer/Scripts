function testfilevalid {

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
                throw "File '${_}' does not exist. Please provide the path to a file (not a directory) on your local computer and try again."
             } $true
         })]
        [string] $FileName
    
) 

BEGIN {
     Set-StrictMode -Version Latest 
 
    ${CmdletName} = $Pscmdlet.MyInvocation.MyCommand.Name 
    
    Write-Debug -Message "${CmdletName}: Starting Begin Block"

    $set = $PsCmdlet.ParameterSetName
    Write-Verbose ("Set: {0}" -f $Set)
   
    
    if ($set -eq "file") {
          Write-Verbose ("Filename: {0}" -f $FileName)
          try {
            #import the non-blank computernames
            $ComputerName = ((Import-Csv $FileName | Select computername).computername) -notmatch '^\s*$'
          } catch {
             throw ("File '{0}' is either empty or has no field headed 'ComputerName'" -f $filename)
            exit
          }

          if (!($ComputerName[0]) ) {
            throw ("File '{0}' appears to have no computernames" -f $filename)
            exit
            }
         } 
     
     
    $tot = ($computername | measure).count   
    Write-Verbose ("Total is {0}" -f $tot)

} #BEGIN
PROCESS {
    write-output ("Computername: {0}" -f $ComputerName.count)te
    Write-Output ("filename: {0}" -f $filename)
    foreach ($computer in $computername){
        write-host ("Computer: {0}" -f $computer)
    }
}

END{}

}