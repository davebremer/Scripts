#requires -version 4.0

# get most current version at https://gist.github.com/jdhitsolutions/3046b3aafcbd89a6d857f7a7a5586e47

Function Test-UporDown {

<#
.Synopsis
Test if a web site is down or if it is just you.

.Description
The function uses the web site DownForEveryoneOrJustme.com to test is a web site or domain is up or down, or if the problem is just you. The command will write a custom object to the pipeline. See examples.
.Parameter Name
The name of a web site or domain such as google.com or powershell.org.

.Parameter UseUniversalTime
Convert the tested date value to universal or GMT time.

.Example
PS C:\> test-upordown pluralsight.com 

Name            IsUp Date                 
----            ---- ----                 
pluralsight.com True 12/22/2016 9:17:00 AM

.Example
PS S:\> test-upordown pluralsight.com -UseUniversalTime

Name            IsUp Date                 
----            ---- ----                 
pluralsight.com True 12/22/2016 2:17:41 PM

.Example
PS S:\> test-upordown foofoo.edu -Verbose
VERBOSE: [BEGIN  ] Starting: Test-UporDown
VERBOSE: [PROCESS] Testing foofoo.edu
VERBOSE: GET http://downforeveryoneorjustme.com/foofoo.edu/ with 0-byte payload
VERBOSE: received 2256-byte response of content type text/html;charset=utf-8
VERBOSE: [PROCESS] It's not just you! http://foofoo.edu looks down from here. 

VERBOSE: [END    ] Ending: Test-UporDown
Name        IsUp Date                 
----        ---- ----                 
foofoo.edu False 12/22/2016 9:19:13 AM

.Notes
version: 1.0

Learn more about PowerShell:
http://jdhitsolutions.com/blog/essential-powershell-resources/

.Link
Invoke-WebRequest

#>

[cmdletbinding()]
Param(
[Parameter(
Position = 0, 
Mandatory, 
HelpMessage = "Enter a web site name, such as google.com.",
ValueFromPipeline
)]
[ValidateNotNullorEmpty()]
[ValidateScript({ $_ -notmatch "^http"})]
[string]$Name,
[Switch]$UseUniversalTime
)

Begin {
    Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.Mycommand)"  
} #begin

Process {
    Write-Verbose "[PROCESS] Testing $Name"
    $response = Invoke-WebRequest -uri "http://downforeveryoneorjustme.com/$Name/" -DisableKeepAlive
    #get the result text from the HTML document
    $text = $response.ParsedHtml.getElementById("container").InnerText

    #the first line has the relevant information that looks like this:
    # It's just you. http://blog.jdhitsolutions.com is up
    $reply = ($text -split "`n" | Select -first 1)
    Write-Verbose "[PROCESS] $reply"

    If ($UseUniversalTime) {
        Write-Verbose "[PROCESS] Using universal time (GMT)"
        $testDate = (Get-Date).ToUniversalTime()
    }
    else {
        $testDate = Get-Date
    }

    #write a result object to the pipeline
    [pscustomObject]@{
        Name = $Name
        IsUp = $reply -match "\bis up\b"
        Date = $TestDate
    }
    
} #process

End {
    Write-Verbose "[END    ] Ending: $($MyInvocation.Mycommand)"
} #end

}

#define an optional alias
Set-Alias -Name tup -Value Test-UporDown