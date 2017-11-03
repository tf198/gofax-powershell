## GoFax Powershell ##

A few powershell functions and a SendTo script for the Australian
GoFax service using their v1 API.
Obviously you need an account with GoFax for this to work...

The following powershell functions are currently included:

```PowerShell
. C:\pathto\gofax-powershell\gofax.ps1

Send-GoFax -Token $token -FaxNumber 50123456 -Email me@myplace.net C:\file1.pdf C:\file2.pdf

Create-GoFaxToken $username

Check-GoFaxAccess -Token $token
```

Have a look at the help for more options.

### SendTo Action ###

After cloning the repo, create a shortcut in `shell:sendto`. Leave the window style as `Run=Normal` as we are hiding the powershell in the command.

	%windir%\System32\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -file C:\pathto\gofax-powershell\SendTo-Fax.ps1

You then need to create a user specific settings file in `%APPDATA%\GoFax\settings.xml`

```xml
<?xml version="1.0">
<config>
	<token>XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX</token>
	<email>me@example.com</email>
	<processed>C:\Users\Me\Documents\Faxes\Sent</processed>
</config>
```

The `<processed>` setting is optional - if present it will give you the option
of moving the files sent to the given folder with a date based name.

Then you should be good to go.  Any issues, switch the link to `-windowstyle normal`.

### Limitations ###

There are multiple methods available to submit faxes in the v1 GoFax API. 
Unfortunately the one that allows you to submit multiple files, `SendFax()` 
doesn't return the job ID assigned so you are reliant on email notification. 
Hopefully this will be resolved in the upcoming REST API...
