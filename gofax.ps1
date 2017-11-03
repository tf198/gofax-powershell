$wsdl = "https://sendfax-api.gofax.com.au/fax/sendfaxapi.asmx?WSDL"

function Validate-PhoneNumber {
    Param([string]$number)
    if (-not ($number -match "^\+?[0-9]{8,20}$")) {
        throw "Phone number should be 8-20 digits, optionally prefixed with a +"
    }
    $true
}

function Validate-GoFaxAcceptedFiles {
    Param([string]$filePath)
    if (-not (Test-Path $filePath)) {
        throw "No such file: $filePath"
    }
    if (-not ($filePath.toLower() -match "\.(pdf|tiff?)$")) {
        throw "Can only send PDF or TIFF files"
    }
    $true
}

function Validate-Email {
    Param([string]$address)
    if (-not ([bool]($address -as [Net.Mail.MailAddress]))) {
        throw "'$address' is not a valid email address"
    }
    $true
}

<#
.Synopsis
   Connect to the GoFax API
.DESCRIPTION
   Returns a webservice instance for the GoFax API
.EXAMPLE
   Send-GoFax -Token <GUID> -FaxNumber 50123456 -Email me@myplace.net C:\file1.pdf C:\file2.pdf
#>
function Connect-GoFax
{
    Param
    (
        [ValidatePattern("\w{8}-\w{4}\-\w{4}-\w{4}-\w{12}")]
        [string]$Token
    )

    Write-Verbose "Connecting to api..."
    $webservice = New-WebServiceProxy -Uri $wsdl -Namespace WebServiceProxy -Class SendFaxAPISoap -ErrorAction Stop

    if ($Token)
    {
        Write-Verbose "Checking access..."
        if (-not $webservice.CheckHaveAccess($Token)) {
            throw "Bad GoFax API token"
        }
    }

    $webservice
}

<#
.Synopsis
   Send a fax using the GoFax API
.DESCRIPTION
   Connects to webservice and executes the SendFax() method.
   Notification of delivery will be sent to the specified email.
.EXAMPLE
   Send-GoFax -Token <GUID> -FaxNumber 50123456 -Email me@myplace.net C:\file1.pdf C:\file2.pdf
#>
function Send-Fax
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Token,

        [Parameter(Mandatory=$true)]
        [ValidateScript({Validate-PhoneNumber $_})]
        [string]$FaxNumber,

        [Parameter(Mandatory=$true)]
        [ValidateScript({Validate-Email $_})]
        [string]$Email,

        [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
        [ValidateScript({Validate-GoFaxAcceptedFiles $_})]
        [string[]]$Files
    )

    try {
        $names = [string[]] @()
        $data = [byte[][]] @()

        Write-Verbose "Reading data for $($Files.Count) files"
        foreach ($f in $Files)
        {
            $d = Get-Content $f -Encoding Byte -ReadCount 0
            Write-Verbose "`t$($f): $($d.Length) bytes"
            $names += (Get-Item $f).Name
            $data += ,$d
        }

        $webservice = Connect-GoFax $token
        
        Write-Verbose "Submitting job for $FaxNumber"

        if ([int]$FaxNumber -ne 0) { # for easy testing
            Write-Verbose "Sending to GoFax service"
            $webservice.SendFax($data, $names, $FaxNumber, $Email, $token)
            Write-Verbose "Dispatched"
        } else {
            Write-Verbose "Test number - skipping dispatch"
            Write-Verbose "SendFax(<$($data.length) blobs>, [$names], $FaxNumber, $Email, $token)"
        }

        Write-Verbose "Finished communication"
    } catch {
        throw $_
    }

}

<#
.Synopsis
   Create a token for the GoFax API
.EXAMPLE
   Create-GoFaxToken <username>
#>
function Create-GoFaxToken
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Username,

        [string]$MachineName
    )

    if ($MachineName -eq "")
    {
        $MachineName = $env:COMPUTERNAME
    }

    $spwd = Read-Host -AsSecureString -Prompt Password
    $credentials = (New-Object pscredential $Username, $spwd).GetNetworkCredential()

    $webservice = Connect-GoFax
    $result = $webservice.CreateLoginToken($MachineName, $credentials.UserName, $credentials.Password, $null)

    $result.guid
}

<#
.Synopsis
   Check a given token has access to the GoFax API
.EXAMPLE
   Check-GoFaxAccess -Token <GUID>
#>
function Check-GoFaxAccess
{
    
    [CmdletBinding()]
    [Alias()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Token
    )

    try {
        $webservice = Connect-GoFax $Token
        Write-Host "Everything looks good"
        $true
    } catch {
        Write-Error $_
        $false
    }
}