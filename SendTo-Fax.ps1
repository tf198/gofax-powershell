<#
.Synopsis
    Create a shortcut to this file from the `shell:sendto` directory
    Requires a user specific %APPDATA%\GoFax\settings.xml file.
#>
[string]$app = "SendTo GoFax"
[string]$settingsFile = "$($env:APPDATA)\GoFax\settings.xml"

. $PSScriptRoot\gofax.ps1

Add-Type -AssemblyName Microsoft.VisualBasic

try {

    [Xml]$settings = Get-Content $settingsFile -ErrorAction Stop
    if (-not $settings.config.token) { throw "No token in settings" }
    if (-not $settings.config.email) { throw "No email in settings" }
 
    if ($args.Length -lt 1) {
        throw "No files selected"
    }

    $message = "$($args.Length) files selected for faxing`nEnter fax number (8-20 digits)"
    $additional = ""

    while ($true) {
        $faxNumber = [Microsoft.VisualBasic.Interaction]::InputBox($message + $additional, $app, $faxNumber)
        if ($faxNumber -eq "") {
            throw "User cancelled sending of fax"
        }
        try {
            $_ = Validate-PhoneNumber $faxNumber
            break
        } catch {
            Write-Error $_
            $additional = "`n`n'$faxNumber' doesn't look valid!"
        }
    }
    Send-Fax -Token $settings.config.token -Email $settings.config.email -FaxNumber $faxNumber -Verbose -Files $args
    $message = "Fax has been submitted for $faxNumber.`nNotifications will be sent to $($settings.config.email)."
    
    if ($settings.config.processed) {

        if (-not (Test-Path $settings.config.processed)) {
           New-Item -ItemType Directory $settings.config.processed -ErrorAction Stop
        }

        $message += "`n`nDo you want to move these files to the processed folder?"
        $btn = [Microsoft.VisualBasic.Interaction]::MsgBox($message, "YesNo,Information", $app)
    
        if ($btn -eq "Yes") {
            $base = "$($settings.config.processed)\$(Get-Date -UFormat "%Y%m%d_%H%M%S")"
            for ($i=0; $i -lt $args.Length; $i++) {
                $a = "$($base)_part_$($i+1)$([IO.Path]::GetExtension($args[$i]))"
                Move-Item $args[$i] $a -ErrorAction Stop
            }
        }
    } else {
        $btn = [Microsoft.VisualBasic.Interaction]::MsgBox($message, "OKOnly,Information", $app)
    }

} catch {
    # Dump some extra stuff to the console
    $_.Exception | Format-List -Force
    # Present a friendly error
    $btn = [Microsoft.VisualBasic.Interaction]::MsgBox($_.toString(), "OKOnly,ApplicationModal,Exclamation,DefaultButton2", $app)
}