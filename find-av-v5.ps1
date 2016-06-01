function Get-AVProduct { 
<# 
.SYNOPSIS 
    Get the status of Antivirus Product(s) on local and Remote Computers. 
 
.DESCRIPTION 
    Works with MS Security Center and detects the status for most AV products. If there are multiple AV installed for in a computer, 
    a seperate output object is created for each product

    Note: There are different calls for XP,Win2000 etc vs Vista, Win7, Server 2008 etc. They report slightly differently. Where possible the output has
    been converted to the modern field names. It is possible that future OS may break this
 
.PARAMETER ComputerName 
    The computer name(s) to retrieve the info from.  
  
.EXAMPLE 
    Get-AVProduct 
    Returns the details of te current computer

    gc 'f:\reports\CCL Reports\2016-05-13\blank-av.txt' | Get-AVProduct | select ComputerName,OS,CountProdsInstalled,AVProductName,ProductExecutable,versionNumber,DefinitionStatus,RealTimeProtectionStatus,QueryStatus | Export-Csv 'f:\reports\CCL Reports\2016-05-13\av-2016-05-13-redone-05-23.csv' -NoTypeInformation

    for 26/5 hunt win8 k6
    Import-Csv 'f:\docs\tickets\Trend rollout\kaspersky7.txt' | select computername | Get-AVProduct -verbose| select ComputerName,OS,CountProdsInstalled,AVProductName,ProductExecutable,versionNumber,DefinitionStatus,RealTimeProtectionStatus,QueryStatus |Export-Csv 'f:\docs\tickets\Trend rollout\kasperskycheck.csv' -NoTypeInformation
 
 
.EXAMPLE 
    Get-AVProduct 
 
.EXAMPLE 
    get-content PClist.txt | Get-AVProduct 

.INPUTS 
    System.String, you can pipe ComputerNames to this Function 
 
.OUTPUTS 
    psobject: daveb.av
    ComputerName:             The name of the computer being queried
    OS:                       The name of the OS
    CountProdsInstalled:      Number of AV products installed
    QueryStatus               Success / No Ping / WMI Error
    AVProductName:            The display name of the AV product. Could be an array of objects unless converted to string with -stringout
    DefinitionStatus:         Up to date/Out of date
    ProductExecutable:        Path to the executable - could be an array of objects unless converted to string with -stringout
    RealTimeProtectionStatus: Is real time protection active?
    versionNumber:            Version number if legacy OS
 
.NOTES 
    WMI query to get anti-virus infor­ma­tion has been changed. 
    Pre-Vista clients used the root/SecurityCenter name­space,  
    while Post-Vista clients use the root/SecurityCenter2 name­space. 
    But not only the name­space has been changed, The properties too.  
 
 
    code drawn from:
        http://neophob.com/2010/03/wmi-query-windows-securitycenter2/ 
        http://blogs.msdn.com/b/alejacma/archive/2008/05/12/how-to-get-antivirus-information-with-wmi-vbscript.aspx 
        https://soykablog.wordpress.com/2012/08/26/get-info-about-antivirus-from-windows-security-centre-using-powershell-and-wmi/ 
        https://gallery.technet.microsoft.com/scriptcenter/Get-the-status-of-4b748f25
 
    AUTHOR: Dave Bremer (mostly copying from the above)  
    LASTEDIT:  2016-05-25
    KEYWORDS:  
 
.LINK 
 
 
#Requires -Version 2.0 
#> 
 
 
[CmdletBinding()] 
[OutputType('PSobject')] 
 
param ( 
    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)] 
    [Alias('CN')] 
    [String[]]$ComputerName=$env:computername
    
) 
 
BEGIN { 
 
    Set-StrictMode -Version Latest 
 
    ${CmdletName} = $Pscmdlet.MyInvocation.MyCommand.Name 
    
    Write-Debug -Message "${CmdletName}: Starting Begin Block"
    #$tot = ($computername | measure).count   
    #Write-Verbose ("Total is {0}" -f $tot)
 
} # end BEGIN 
 
PROCESS { 
    
    Write-Debug ("PROCESS:`n{0}" -f ($PSBoundParameters | Out-String)) 

    #$counter=0 #for progress bar 
    #$tot = ($computername | measure).count
    ForEach ($Computer in $computerName) { 
     #   $counter+=1
      #  $prog=[system.math]::round($counter/$tot*100,2)
       # write-progress -activity ("Checking {0}. {1} computers left to check" -f $computer,($tot-$counter)) -status "$prog% Complete:" -percentcomplete $prog;
        
        
        Write-verbose ("Computer: {0}" -f $Computer)
        
                
        IF (Test-Connection -ComputerName $Computer -count 2 -quiet) {  
            Try {
            $OSDetails = Get-WmiObject –Class Win32_OperatingSystem –ComputerName $Computer -ErrorAction Stop 
            $OSVersion = $OSDetails.version
            $OS = $OSVersion.split(".") 
            Write-Debug "`$OS[0]: $($OS[0])" 
            $OSName = $OSDetails.Caption
            } catch {
                $OSVersion = "WMI Error getting OS Details"
                $OS = "9999" 
                Write-Verbose "`$OS not found" 
                Write-verbose "WMI Error getting OS"
                Write-verbose $_ 
                $OSName = "WMI Error getting OS Details"
                $prop =  @{ 
                        ComputerName = $Computer; 
                        OS = $Null;
                        CountProdsInstalled = $null;
                        QueryStatus = ("Unknown OS or Error querying OS - Query Skipped" ); 
                        AVProductName = $null; 
                        versionNumber = $null; 
                        ProductExecutable = $null;  
                        DefinitionStatus = $null;
                        RealTimeProtectionStatus = $null
                        } 
                
                $obj = New-Object -TypeName PSObject -Property $prop
                $obj.psobject.typenames.insert(0, 'daveb.av')
                Write-Output $obj
                Continue
            }

            IF ($OS[0] -eq "5") { 
                Write-Verbose "Windows 2000, 2003, XP"  
                Try { 
                    $AntiVirusProducts = Get-WmiObject -Namespace root\SecurityCenter -Class AntiVirusProduct  -ComputerName $Computer -ErrorAction Stop 
                    $ProdCount = ($AntiVirusProducts | measure-object).count
                    if ($ProdCount -eq 0 ) {
                        Write-Warning "\\$computer MISSING!!!!!!!!!!!!!!!!!!!!!!!!!!!" 
                        $prop =  @{ 
                                        ComputerName = $Computer; 
                                        OS = $OSName;
                                        #CountProdsInstalled = $AntiVirusProduct.count;
                                         CountProdsInstalled = $ProdCount
                                        QueryStatus = "Success"; 
                                        AVProductName = "MISSING"; 
                                        versionNumber = $nullr; 
                                        ProductExecutable = $null;  
                                        DefinitionStatus = $null;
                                        RealTimeProtectionStatus = $null
                                    }
                            $obj = New-Object -TypeName PSObject -Property $prop
                            $obj.psobject.typenames.insert(0, 'daveb.av')
                            Write-Output $obj
                    } else {
                        foreach ($AVProd in $AntiVirusProducts) {
                            $prop =  @{ 
                                        ComputerName = $Computer; 
                                        OS = $OSName;
                                        #CountProdsInstalled = $AntiVirusProduct.count;
                                         CountProdsInstalled = $ProdCount
                                        QueryStatus = "Success"; 
                                        AVProductName = $AVProd.displayName; 
                                        versionNumber = $AVProd.versionNumber; 
                                        ProductExecutable = $null;  
                                        DefinitionStatus = $AVProd.productUptoDate;
                                        RealTimeProtectionStatus = $AVProd.onAccessScanningEnabled
                                            
                            }
                            $obj = New-Object -TypeName PSObject -Property $prop
                            $obj.psobject.typenames.insert(0, 'daveb.av')
                            Write-Output $obj
                        
                        }#foreach AV
                        
                       
                     }  #if AV prod
                    } Catch { 
                        $Errordetails = $_
                        Write-Error "$Computer : WMI Error" 
                        Write-Error $_
                        
                        $prop =  @{ 
                                    ComputerName = $Computer; 
                                    OS = $OSName;
                                    CountProdsInstalled = $null;
                                    QueryStatus = ("WMI ERROR: {0}" -f $Errordetails); 
                                    AVProductName = $null; 
                                    versionNumber = $null; 
                                    ProductExecutable = $null;  
                                    DefinitionStatus = $null;
                                    RealTimeProtectionStatus = $null
                        } 
                        
                        $obj = New-Object -TypeName PSObject -Property $prop
                        $obj.psobject.typenames.insert(0, 'daveb.av')
                        Write-Output $obj
                        Continue 
                }     

            } ElseIF ($OS[0] -eq "6") { 
                Write-Verbose "Windows Vista, 7, 2008, 2008R2" 
                Try { 
                    $AntiVirusProducts = Get-WmiObject -Namespace root\SecurityCenter2 -Class AntiVirusProduct  -ComputerName $Computer -ErrorAction Stop 
                    $ProdCount = ($AntiVirusProducts | measure-object).count
                    if ($ProdCount -eq 0 ) {
                        Write-Warning "\\$computer MISSING!!!!!!!!!!!!!!!!!!!!!!!!!!!" 
                        $prop =  @{ 
                                        ComputerName = $Computer; 
                                        OS = $OSName;
                                        #CountProdsInstalled = $AntiVirusProduct.count;
                                         CountProdsInstalled = $ProdCount
                                        QueryStatus = "Success"; 
                                        AVProductName = "MISSING"; 
                                        versionNumber = $null; 
                                        ProductExecutable = $null;  
                                        DefinitionStatus = $null;
                                        RealTimeProtectionStatus = $null
                                    }
                           $obj = New-Object -TypeName PSObject -Property $prop
                           $obj.psobject.typenames.insert(0, 'daveb.av')
                           Write-Output $obj  
                    } else {
                        ForEach ($AVProd in $AntiVirusProducts) {
                        
                            $ProductState=$AVProd.ProductState
                    
                            #$ProductState
                            $HexProductState="{0:x6}" -f $ProductState
                            #Write-Verbose "HexProductState=$HexProductState"
 
                            #$FirstByte = Join-String -Strings "0x", $HexProductState.Substring(0,2)
                            $FirstByte = -join (“0x”, $HexProductState.Substring(0,2))
 
                            #Write-Verbose "FirstByte=$FirstByte"
                            $SecondByte = $HexProductState.Substring(2,2)
                            #Write-Verbose "SecondByte=$SecondByte"
                            $ThirdByte = $HexProductState.Substring(4,2)
                            #Write-Verbose "ThirdByte=$ThirdByte"      

                            <#
                            ## Decided not to use this
                             switch ($FirstByte) {
                                {($_ -band 1) -gt 0} {$Prop.ThirdPartyFirewallPresent=$true}
                                {($_ -band 2) -gt 0} {$Prop.AutoUpdate=$true}
                                {($_ -band 4) -gt 0} {$Prop.AntivirusPresent=$true}
                            }
                            #>

                            #this is as dodgy as hell. No documentation exists on this!!!!
                    
                            if ($SecondByte -eq "10") {
                                $rtstatus = "Enabled"
                            } else {
                                $rtstatus = "Disabled"
                            }
 
                            if ($ThirdByte -eq "00") {
                                $defstatus = "Up to Date"
                            } else {
                                $defstatus = "Out of Date"
                    
                           }
                           $prop =  @{ 
                                ComputerName = $Computer; 
                                OS = $OSDetails.Caption;
                               # CountProdsInstalled = $AntiVirusProducts.count;
                               CountProdsInstalled = $ProdCount;
                                QueryStatus = "Success"; 
                                AVProductName = $AVProd.displayName;
                                versionNumber = $null; 
                                ProductExecutable = $AVProd.pathToSignedProductExe;;  
                                DefinitionStatus = $defstatus;
                                RealTimeProtectionStatus = $rtstatus
                                }
                        $obj = New-Object -TypeName PSObject -Property $prop
                        $obj.psobject.typenames.insert(0, 'daveb.av')
                        Write-Output $obj  
                        }
                                
                     }           
                     
                              
                 } Catch { 
                    $Errordetails = $_
                    Write-Error "$Computer : WMI Error" 
                    Write-Error $Errordetails 
                    $prop =  @{ 
                            ComputerName = $Computer; 
                            OS = $OSName;
                            CountProdsInstalled = $null;
                            QueryStatus = ("WMI ERROR: {0}" -f $Errordetails); 
                            AVProductName = $null; 
                            versionNumber = $null; 
                            ProductExecutable = $null;  
                            DefinitionStatus = $null;
                            RealTimeProtectionStatus = $null
                        }
                    $obj = New-Object -TypeName PSObject -Property $prop
                    $obj.psobject.typenames.insert(0, 'daveb.av')
                    Write-Output $obj         
                }  
 
            } Else { 
                Write-Error "\\$Computer : Unknown OS Version"
                $prop =  @{ 
                        ComputerName = $Computer; 
                        OS = $Null;
                        CountProdsInstalled = $null;
                        QueryStatus = ("Unknown OS or Error querying OS - Query Skipped" ); 
                        AVProductName = $null; 
                        versionNumber = $null; 
                        ProductExecutable = $null;  
                        DefinitionStatus = $null;
                        RealTimeProtectionStatus = $null
                        } 
                
                $obj = New-Object -TypeName PSObject -Property $prop
                $obj.psobject.typenames.insert(0, 'daveb.av')
                Write-Output $obj
            } # end If $OS 
             
             
        } Else { 
            Write-verbose "\\$computer No ping" 
            $prop =  @{ 
                    ComputerName = $Computer; 
                    OS = $null;
                    CountProdsInstalled = $null;
                    QueryStatus = ("No Ping"); 
                    AVProductName = $null; 
                    versionNumber = $null; 
                    ProductExecutable = $null;  
                    DefinitionStatus = $null;
                    RealTimeProtectionStatus = $null
                 }
             
                            
                $obj = New-Object -TypeName PSObject -Property $prop
                $obj.psobject.typenames.insert(0, 'daveb.av')
                Write-Output $obj
                 
        } # end IF (Test-Connection -ComputerName $Computer -count 2 -quiet)      
        
    } # end ForEach ($Computer in $computerName) 
 
} # end PROCESS 
 
END { Write-Verbose "Function Get-AVProduct finished." }  
} # end function Get-AVProduct
