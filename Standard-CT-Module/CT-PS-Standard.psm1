
trap {
    write-host "Terminating error $_"
    Write-Host "Script $((Get-ChildItem $MyInvocation.PSCommandPath | Select-Object -Expand Name)) ended with exit code $($exiterror)."
    Write-Host "Output log            : $($Output_log)"
    Write-Host "Transcript log        : $($Transcript_log)"
    Write-Host "API log               : $($API_log)"
    Write-Host "Install log (if used) : $($Install_log)"
    Write-Host "**********************"
    Write-Host ""
    Remove-Module "$(Get-ChildItem $PSScriptRoot)\CT-PS-Standard.psm1" -Force
    Remove-Item "$(Get-ChildItem $PSScriptRoot)\CT-PS-Standard.psm1" -Force
    exit $exiterror
}

function Initialize-Script {
    [CmdletBinding()]
    param()
    <# 
    ---- STANDARD SCRIPT BLOCK ----
    This block is standard script settings used across all scripts and enables some consistency.
    It sets up some standard variables and starts transcript so any errors are caught and can be viewed.
    If installations are taking place via MSIEXEC, it also establishes the log file.  
    If you are installing more than one installation, make sure you setup multiple Install_Log variables for each installation and name the end of the log file accordingly
    It starts transcript to the transcript log file so the history can be accessed anytime in the future
    The script then tests for the CT_DEST folder and creates it if its not there.
    
    This needs to be imported to a script by using the following two commands:

    Invoke-WebRequest -uri "https://raw.githubusercontent.com/alexisspencer/ct_store/main/Standard-CT-Module/CT-PS-Standard.psm1" -OutFile "$($PSScriptRoot)\CT-PS-Standard.psm1" -Verbose:$VerbosePreference -Debug:$DebugPreference
    Import-Module -Name "$($PSScriptRoot)\CT-PS-Standard.psm1" -Force -Verbose:$VerbosePreference -Debug:$DebugPreference

    Then trigger the function "Initialize-Script" at the start of your script
    
    #>

    $global:ErrorActionPreference = "Stop"
    $global:CT_DEST="C:\CT"  # Where the files are downloaded to
    $global:DateStamp = get-date -Format yyyyMMddTHHmmss # A formatted date strong
    $global:ScriptName = (Get-ChildItem $MyInvocation.PSCommandPath | Select-Object -Expand Name).Substring(0,(Get-ChildItem $MyInvocation.PSCommandPath | Select-Object -Expand Name).Length-4)
    $global:Output_log = "$CT_DEST\logs\$($ScriptName)\$($DateStamp)_output.log"  # The output
    $global:Transcript_log = "$CT_DEST\logs\$($ScriptName)\$($DateStamp)_transcript.log"  # The powershell transcript file
    $global:API_log = "$($CT_DEST)\logs\$($ScriptName)\$($DateStamp)_API.log"
    $global:Install_log = "$CT_DEST\logs\$($ScriptName)\$($DateStamp)_install.log"  # The powershell installation file


    #Transcript-Log "-------$('-' * $MyInvocation.MyCommand.Name.Length)----------"
    Start-Transcript -Path $Transcript_log -Append -verbose:$VerbosePreference
    Write-Host "**********************"
    Write-Host "Output log            : $($Output_log)"
    Write-Host "Transcript log        : $($Transcript_log)"
    Write-Host "API log               : $($API_log)"
    Write-Host "Install log (if used) : $($Install_log)"
    Write-Host "Script $($ScriptName) starting."

    #Transcript-Log "-------$('-' * $MyInvocation.MyCommand.Name.Length)----------"

    # Check for a CT folder on the C: and if not, create it, however that location should already exist as part of the Start-Transcript command.
    if(-not( Test-Path -Path $CT_DEST )) {
        try{
            mkdir $CT_DEST > $null
            #Transcript-Log "New folder created at $CT_DEST."
        }catch{
            #Can't create the folder, therefore cannot continue
            Write-Error "Cannot create folder $CT_DEST. $($Error[0].Exception.Message)"
            Write-Error $_ -verbose:$VerbosePreference
            #Stop-Transcript
            exit 1
        }
    }

    if(-not( Test-Path -Path "$($CT_DEST)\logs" )) {
        try{
            mkdir "$($CT_DEST)\logs" > $null
            #Transcript-Log "New logs folder created at $CT_DEST."
        }catch{
            #Can't create the folder, therefore cannot continue
            Write-Error "Cannot create logs folder in $CT_DEST. $($Error[0].Exception.Message)"
            Write-Error $_ -verbose:$VerbosePreference
            #Stop-Transcript
            exit 3
        }
    }

    if(-not( Test-Path -Path "$($CT_DEST)\logs\$($ScriptName)" )) {
        try{
            mkdir "$($CT_DEST)\logs\$($ScriptName)" > $null
            #Transcript-Log "New logs folder for $($ScriptName) created at $CT_DEST."
        }catch{
            #Can't create the folder, therefore cannot continue
            Write-Error "Cannot create logs folder for $($ScriptName) in $CT_DEST. $($Error[0].Exception.Message)"
            Write-Error $_
            #Stop-Transcript
            exit 4
        }
    }

    $global:CT_Reg_Path = "HKLM:\Software\CT\Monitoring"
    $global:CT_Reg_Key = "$($CT_Reg_Path)\$($ScriptName)"
    if(-not( Test-Path -Path $CT_Reg_Key )) {
        try{
            $CTMonitoringReg = New-Item -Path $CT_Reg_Path -Name $ScriptName -Force
            Set-ItemProperty -Path "HKLM:\Software\CT" -Name "CustomerNo" -Value $customer
        }catch{
            #Can't create the regkey, therefore cannot continue
            Write-Error "Cannot create registry key at $($CT_Reg_Key). $($Error[0].Exception.Message)"
            Write-Error "$($CTMonitoringReg)"
            Write-Error $_
            #Stop-Transcript
            exit 5
        }
    }

    # Create Transcript header
    Write-Log "**********************"
    Write-Log "Script: $($PSCmdlet.MyInvocation.ScriptName)."
    Write-Log "Start time: $($DateStamp)"
    Write-Log "Username: $($env:USERDOMAIN)\$($env:USERNAME)"
    Write-Log "Execution Policy Preference: $($env:PSExecutionPolicyPreference)"
    Write-Log "Machine: $($env:COMPUTERNAME) ($($env:OS))"
    Write-Log "Process ID: $($PID))"
    Write-Log "PSVersion: $($PSVersionTable.PSVersion)"
    Write-Log "PSEdition: $($PSVersionTable.PSEdition)"
    Write-Log "PSCompatibleVersions: $($PSVersionTable.PSCompatibleVersions)"
    Write-Log "BuildVersion: $($PSVersionTable.BuildVersion)"
    Write-Log "CLRVersion: $($PSVersionTable.CLRVersion)"
    Write-Log "WSManStackVersion: $($PSVersionTable.WSManStackVersion)"
    Write-Log "PSRemotingProtocolVersion: $($PSVersionTable.PSRemotingProtocolVersion)"
    Write-Log "SerializationVersion: $($PSVersionTable.SerializationVersion)"
    Write-Log "**********************"


    <#
    ---- END STANDARD SCRIPT BLOCK---- 
    #>

}

Function Write-Log {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $output
    )
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose'] -eq $true) {
        Write-Verbose "($(Get-CurrentLineNumber)) $($output)"
    }
    $output | Out-File -FilePath "$($Output_log)" -Append
}


# Writes to the API log and optionally console if -Verbose flag is set at script level
Function Write-APILog {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $output
    )
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose'] -eq $true) {
        Write-Verbose "($(Get-CurrentLineNumber)) $($output)"
    }
    $output | Out-File -FilePath "$($API_log)" -Append
}


Function Request-Download {
    # Downloads a file using BITS if possible, and if BITS is not available, downloads directly from URL
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Mandatory = $true)]
        [string[]] $FILE_URL,
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Mandatory = $true)]
        [string[]] $FILE_LOCAL,
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [switch] $NoBITS # This is for when BITS should not be used
    )

    
    # Test for existing file and remove if it exists
    if(Test-Path -Path $MSIfFILE_LOCALile70 -PathType Leaf ) {
        try {
            Remove-Item $FILE_LOCAL -Force
        } catch {
            #Can't remove the MSI, therefore cannot continue
            Write-Log "Cannot remove $FILE_LOCAL. Unable to continue. $($Error[0].Exception.Message)"
            return $Error
        }
    }


    if (!(Get-Module -ListAvailable -Name "BitsTransfer") -and !($NoBITS)) {
        try{
            Import-Module BitsTransfer -Force
        } catch {
            $NoBITS = $true
        }
    }


    
    
    if (!($NoBITS)) {
        # Check if BranchCache Distributed Mode is enabled, and if not, enable it so BITS uses computers on the subnet to download where available
        $BCStatus = Get-BCStatus
        if ($BCStatus.ClientConfiguration.CurrentClientMode -ne "DistributedCache") {
            try {
                Enable-BCDistributed -Verbose -Force
                Write-Log "BranchCache Distributed Mode is now enabled" -Verbose:$VerbosePreference
            } catch {
                #BranchCache cannot be enabled to work with BITS. BITS will download over the internet connection instead of cached copies on the local subnet
                Write-Log "Cannot enable BranchCache Distributed Mode. $($Error[0].ErrorDetails).  The installation files will download over the internet connection instead of cached copies on the local subnet" -Verbose:$VerbosePreference
            }
        } else {
            Write-Log "BranchCache Distributed Mode is already enabled in distributed mode on this computer" -Verbose:$VerbosePreference
        }
        $DownloadJob = Start-BitsTransfer -Priority Normal -DisplayName "$($DateStamp) $($FILE_LOCAL)" -Source $FILE_URL -Destination $FILE_LOCAL
    } else {
        try {
            $DownloadJob = Invoke-WebRequest -Uri $FILE_URL -OutFile $FILE_LOCAL -SkipCertificateCheck -PassThru
        } catch {
            Write-Log "Cannot download $($FILE_URL). $_" -Verbose:$VerbosePreference
            return $_
        }
    }
    return $DownloadJob
}


function Get-CurrentLineNumber {
    return "$(Get-ChildItem $MyInvocation.ScriptLineNumber)"
}

