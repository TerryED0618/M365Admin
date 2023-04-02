#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8
#  Execution Examples.
#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8
# . .\New-OutFilePathBase.ps1; New-OutFilePathBase 

Function New-OutFilePathBase {
	<#
		.SYNOPSIS
			Build a output folder path and file name base without an extension.

		.DESCRIPTION
			Build a output folder path and file name base without an extension.  The default output file name is in the form of "YYYYMMDDTHHMMSSZZZ-<OrganizatioName>-<CallingScriptName>[-<OutFileNameTag>]".  The calling solution is free to add a file name extension(s) (e.g. .TXT, .LOG, .CSV) as appropriate.  
			The file name consistency leverages a series of outfiles that can be systematically filtered.  The output folder path and file name is not guaranteed to be unique, but should be unique per second.  
			The date format is sortable date/time stamp in ISO-8601:2004 basic format with no invalid file name characters (such as colon ':').  The executing computer's time zone is included in the date time stamp to support this solution's use globally.
			The -DateOffsetDays parameter can be used to reference another date relative to now.  For example, when processing yesterday's log files today, use -DateOffsetDays -1.  
			The -OrganizationName parameter is either the M365 tenant name (default), Microsoft Exchange organization, forest, domain, computer name, or arbitrary string to support multi-client/customer use, without requiring hard coding outfile file names.
			The calling script name is included in the outfile file name so this solution can be used by other solutions, or solution series, without requiring hard coding outfile file names.
			OutFileNameTag is an optional comment added to the outfile file name.
			Each of the folder file path name components is provided as output so that calling solution can reuse them (i.e. DateTimeStamp string).  

		.COMPONENT
			System.DirectoryServices
			System.IO.Path
			CIM CIM_ComputerSystem CIM_Directory

		.PARAMETER DateOffsetDays [Int]
			Optionally specify the number of days added or subtracted from the current date.  Default is 0 days. 
			If -DateTimeLocal is specified, this offset is applied to that date as well.  
		
		.PARAMETER DateTimeLocal [String]
			Optionally specify a date time stamp string in a format that is standard for the system locale. The default (if not specified) is to use the workstation's current date and time.  
			To determine this workstation's culture enter '(Get-Culture).Name'.
			To determine this workstation's date time format enter '(Get-Culture).DateTimeFormat.ShortDatePattern' and '(Get-Culture).DateTimeFormat.ShortTimePattern'.
			If the date time string is not recognized as a valid date, the current date and time will be used.  
		
		.Parameter DateTimeStampFormat [String]
			Optionally specify a date time stamp format.  Default is sortable date/time stamp in ISO-8601:2004 basic format 'yyyyMMdd\THHmmsszzz'.  
			If the date time string format is not recognized as a valid, the default format will be used.  
			https://docs.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings
		
		.Parameter DateTimeStampLocation [string]
			Optionally specify a date time stamp string location in the file name to be at the "Start" (default), "End", or "None".  $NULL or empty string "" defaults to Start.  

		.PARAMETER OrganizationName [String]
			Specify the script's executing environment organization name.  Must be either: "TenantName", "msExchOrganizationName", "ForestName", "DomainName", "ComputerName", or an arbitrary string including empty string "" or $NULL.
			If TenantName is requested, but there is no Microsoft 365 connection, msExchOrganizationName will be tried.
			If msExchOrganizationName is requested, but there is no Microsoft Exchange organization, ForestName will be tried.
			If ForestName is requested, but there is no forest, DomainName will be tried.  The forest name is of the executing computer's domain membership.  
			If the DomainName is requested, but the computer is not a domain member, ComputerName is used.  The domain name is of the executing computer's domain membership.  
			An arbitrary string can be used in the case where the Microsoft Exchange organization name, forest name or domain name is too generic (e.g. 'CORP', 'GLOBAL' or 'ROOT').
			Default is TenantName.
			If TenantName is specified, before calling this solution connect to M365 via Connect-MsolService (MSOnline), Connect-AzureAD (AzureAD), Connect-AzAccount (Az.Accounts), or Connect-MgGraph (Microsoft.Graph).
		
		.PARAMETER FileNameComponentDelimiter [String]
			Optional file name component delimiter.  The substitute character cannot itself be an folder or file name invalid character.  Default is hyphen '-'.

		.PARAMETER InvalidFilePathCharsSubstitute [String]
			Optionally specify which character to use to replace invalid folder and file name characters.  The substitute character cannot itself be an folder or file name invalid character.  Default is underscore '_'.

		.PARAMETER OutFileNameTag [String]
			Optional string added to the end of the output file name proper (disregarding date time stamp location).

		.PARAMETER OutFolderPath [String]
			Specify which folder path to write the outfile.  Supports UNC and relative reference to the current script folder.  Except for UNC paths, this function will attempt to create and compress the output folder if it doesn't exist.  The default is .\Reports subfolder.  

		.OUTPUTS
			A string with six custom properties:
				Value: A string containing the output file path name which contains a folder path and file name without extension.  If the folder path does exist and is not a UNC path an attempt is made to create the folder and mark it as compressed.
				FolderPath: Full outfile folder path name.
				DateTime: The DateTime object used to create the DateTimeStamp string.
				DateTimeStamp: The date/time stamp string used in the outFile file name.  The sortable ISO-8601:2004 basic format includes the time zone offset from the executing computer.
				OrganizationName: The executing environment's organization name provided or retrieved.
				ScriptFileName: Calling script file name.
				FileName: OutFile file base name without an extension.

		.EXAMPLE
			To change the folder location where the outFile files are written to, with a relative path, use the -OutFolderPath parameter.
			To add a comment to the file name use the -OutFileNameTag parameter.

			$outFilePathBase = New-OutFilePathBase -OutFolderPath '.\Logs' -OutFileNameTag 'TestRun#7'
			$outFilePathName = "$outFilePathBase.csv"
			$logFilePathName = "$outFilePathBase.log"

			$outFilePathName
			<CurrentLocation>\Logs\19991231T235959+1200-<MyExchangeOrgName>-<CallingScriptName>-TestRun#7.csv

			$logFilePathName
			<CurrentLocation>\Logs\19991231T235959+1200-<MyExchangeOrgName>-<CallingScriptName>-TestRun#7.log

			$outFilePathBase.FolderPath
			<CurrentLocation>\Logs\

			$outFilePathBase.DateTimeStamp
			19991231T235959+1200

			$outFilePathBase.OrganizatioName
			<MyExchangeOrgName>

			$outFilePathBase.ScriptFileName
			<CallingScriptName>

			$outFilePathBase.FileName
			19991231T235959+1200-<MyExchangeOrgName>-<CallingScriptName>-TestRun#7

		
		.EXAMPLE
			To change the location where the output files are written to an absolute path use the -OutFolderPath argument.
			To change the execution environment source to the domain name use the -OrganizationName argument.

			$outFilePathBase = New-OutFilePathBase -OrganizationName ForestName -OutFolderPath C:\Reports\

			$outFilePathBase
			C:\Reports\19991231T235959+1200-<MyForestName>-<CallingScriptName>

			$outFilePathBase.FolderPath
			C:\Reports\

			$outFilePathBase.OrganizationName
			<MyForestName>

			$outFilePathBase.FileName
			19991231T235959+1200-<MyForestName>-<CallingScriptName>

		
		.EXAMPLE
			To change the location where the output files are written to an absolute path use the -OutFolderPath argument.
			To change the execution environment source to the domain name use the -OrganizationName argument.

			$outFilePathBase = New-OutFilePathBase -OrganizationName DomainName -OutFolderPath C:\Reports\

			$outFilePathBase
			C:\Reports\19991231T235959+1200-<MyDomainName>-<CallingScriptName>

			$outFilePathBase.FolderPath
			C:\Reports\

			$outFilePathBase.OrganizationName
			<MyDomainName>

			$outFilePathBase.FileName
			19991231T235959+1200-<MyDomainName>-<CallingScriptName>

		
		.EXAMPLE
			To change the location where the output files are written to a UNC path use the -OutFolderPath argument.
			To change the execution environment source to the computer name use the -OrganizationName argument.

			$outFilePathBase = New-OutFilePathBase -OrganizationName ComputerName -OutFolderPath \\Server1\C$\Reports\

			$outFilePathBase
			\\Server1\C$\Reports\19991231T235959+1200-<MyComputerName>-<CallingScriptName>

			$outFilePathBase.FolderPath
			\\Server1\C$\Reports\

			$outFilePathBase.OrganizationName
			<MyComputerName>

			$outFilePathBase.FileName
			19991231T235959-0600-<MyComputerName>-<CallingScriptName>

		
		.EXAMPLE
			To change the execution environment source to an arbitrary string use the -OrganizationName argument.

			$outFilePathBase = New-OutFilePathBase -OrganizationName 'MyOrganization'

			$outFilePathBase
			<CurrentLocation>\Reports\19991231T235959+1200-MyOrganization-<CallingScriptName>
				
			$outFilePathBase.OrganizationName
			MyOrganization

			$outFilePathBase.FileName
			19991231T235959+1200-MyOrganization-<CallingScriptName>

		
		.EXAMPLE
			To change the date/time stamp to the yesterday's date, as when collecting information from yesterday's data use the -DateOffsetDays argument.

			$outFilePathBase = New-OutFilePathBase -DateOffsetDays -1

			$outFilePathBase
			<CurrentLocation>\Reports\<yesterday's date>T<current time>+1200-<MyExchangeOrgName>-<CallingScriptName>

			$outFilePathBase.DateTimeStamp
			<yesterday's date>T<current time>

			$outFilePathBase.FileName
			<yesterday's date>T<current time>+1200-<MyExchangeOrgName>-<CallingScriptName>


		.EXAMPLE
			To change the date/time stamp to a arbitrary date string and include a date offset.  

			$outFilePathBase = New-OutFilePathBase -DateTimeLocal '1/1/2001 00:00'

			$outFilePathBase
			<CurrentLocation>\Reports\01012001T000000+1200-<MyExchangeOrgName>-<CallingScriptName>

			$outFilePathBase.DateTimeStamp
			01012001T000000

			$outFilePathBase.FileName
			01012001T000000+1200-<MyExchangeOrgName>-<CallingScriptName>
					
		
		.EXAMPLE
			To change which character is used to join the file name components together use the -FileNameComponentDelimiter argument.  Note the date/time stamp time zone offset component is prefixed with a plus '+' or minus '-' and is not affected by the argument.

			$outFilePathBase = New-OutFilePathBase -FileNameComponentDelimiter '_'

			$outFilePathBase
			<CurrentLocation>\Reports\19991231T235959T235959+1200_<MyExchangeOrgName>_<CallingScriptName>

			$outFilePathBase.FileName
			19991231T235959+1200_<MyExchangeOrgName>_<CallingScriptName>
		
		
		.EXAMPLE
			To change the character used to replace invalid folder and file name characters use the -InvalidFilePathCharsSubstitute argument.

			$outFilePathBase = New-OutFilePathBase -InvalidFilePathCharsSubstitute '#' -OutFileNameTag 'From:LocalPart@domain.com'

			$outFilePathBase
			<CurrentLocation>\Reports\19991231T235959+1200-<MyExchangeOrgName>-<CallingScriptName>-From#LocalPart@domain.com

			$outFilePathBase.FileName
			19991231T235959+1200-<MyExchangeOrgName>-<CallingScriptName>-From#LocalPart@domain.com


		.EXAMPLE
			To change the date time stamp to an arbitrary date string.

			$outFilePathBase = New-OutFilePathBase -DateTimeLocal '1/1/2001 00:00'

			$outFilePathBase
			<CurrentLocation>\Reports\20000101T000000+1200-<MyExchangeOrgName>-<CallingScriptName>

			$outFilePathBase.FileName
			20000101T000000+1200-<MyExchangeOrgName>-<CallingScriptName>


		.EXAMPLE
			To change the date time stamp format.

			$outFilePathBase = New-OutFilePathBase -DateTimeFormat 'yyyyMMdd'

			$outFilePathBase
			<CurrentLocation>\Reports\19991231-<MyExchangeOrgName>-<CallingScriptName>

			$outFilePathBase.FileName
			19991231-<MyExchangeOrgName>-<CallingScriptName>


		.EXAMPLE
			To change the date time stamp location to end of file name.  

			$outFilePathBase = New-OutFilePathBase -DateTimeStampLocation 'End'

			$outFilePathBase
			<CurrentLocation>\Reports\<MyExchangeOrgName>-<CallingScriptName>-19991231T235959+1200

			$outFilePathBase.FileName
			<MyExchangeOrgName>-<CallingScriptName>19991231T235959+1200


		.EXAMPLE
			To change the date time stamp location to end of file name.  

			$outFilePathBase = New-OutFilePathBase -DateTimeStampLocation 'End' -OutFileNameTag 'Example'

			$outFilePathBase
			<CurrentLocation>\Reports\<MyExchangeOrgName>-<CallingScriptName>-Example-19991231T235959+1200

			$outFilePathBase.FileName
			<MyExchangeOrgName>-<CallingScriptName>-Example-19991231T235959+1200
		
		
		.NOTES
			2013-09-12 Terry E Dow - Added support for ExecutionSource of ForestName.
			2013-09-21 Terry E Dow - Peer reviewed with the North Texas PC User Group PowerShell SIG and specific suggestion by Josh Miller.
			2013-09-21 Terry E Dow - ? Changed output from PSObject to String.  No longer require referencing returned object's ".Value" property. ?
			2018-08-21 Terry E Dow - Replaced WMIObject with equivalent CIMInstance for future proofing.  Replaced $_ with $PSItem (requires PS ver 3) for clarity.  Replaced [VOID] ... with ... > $NULL for clarity.
			2018-11-05 Terry E Dow - Fixed $MyInvocation.ScriptName vs. $Script:MyInvocation.ScriptName scope difference when dot-sourced or Import-Module.
			2018-11-05 Terry E Dow - Fixed new $OutFolderPath compression to [inherited] recursive.
			2018-11-05 Terry E Dow - Support -ExecutionSource being empty string '' or $NULL.
			2018-11-06 Terry E Dow - Replaced Add-Member with PS3's PSCustomObject.
			2018-11-06 Terry E Dow - Documentation cleanup.
			2018-11-09 Terry E Dow - Fixed ExecutionSource switch error where msExchOrganizationName won over arbitrary string.
			2020-04-01 Terry E Dow - Added parameter -DateTimeLocal which accepts a local date and time string.
			2020-08-03 Terry E Dow - Added parameters -DateTimeStampFormat and -DateTimeStampLocation.  
			2020-08-28 Terry E Dow - Fixed -DateTimeStampFormat handling that when $NULL or empty string, to revert to default of 'yyyyMMdd\THHmmsszzz'. 
			2021-08-09 Terry E Dow - Replaced parameter ExecutionSource with OrganizatioName.  Added parameter alias for legacy support.  
			2021-08-10 Terry E Dow - Cleaned up documentation.  
			2022-01-07 Terry E Dow - Added support for -OrganizationName TenantName.  
			2022-01-11 Terry E Dow - Added MgGraph support in Get-TenantName function.  Improved speed by testing associated module import prior to Try/Catch.  Added note for deprecation of MSOnline and AzureAD modules on 2022-06-30.  
			2022-01-11 Terry E Dow - Changed Get-ForestName to return 2nd to last DNS name component, instead of full forest DNS name.  
			2022-02-04 Terry E Dow - Update Get-TenantName to try newest modules over older modules first (reversed order).  
			2022-02-15 Terry E Dow - Added Get-TenantName support for Exchange Online PowerShell V2.
			2022-02-23 Terry E Dow - Added Get-TenantName support for Exchange PowerShell V1.
			2022-06-14 Terry E Dow - Improved Az PowerShell (Az.Accounts) connection state detection.  
			2022-06-14 Terry E Dow - Improved AzureAD V2 – Azure Active Directory PowerShell for Graph (AzureAD) connection state detection.  
			2022-06-14 Terry E Dow - Improved Exchange PowerShell (on-premises V1) connection state detection.  
			2022-08-10 Terry E Dow - Added -WhatIf:$FALSE to "Invoke-CimMethod -MethodName CompressEx ..." command.
			2022-09-08 Terry E Dow - Improved service connection status detection in Get-TenantName for Microsoft.Graph, Az.Account, and ExchangeOnlineManagement.  
			2022-09-13 Terry E Dow - Minor documentation typing errors corrected.  
			2022-09-21 Terry E Dow - Updated for ExchangeOnlineManagement V2 to V3 general availability.  
			2022-09-30 Terry E Dow - Re-normalized Get-Tentant M365 queries.
			2022-09-30 Terry E Dow - Added support for MicrosoftTeams module in Get-Tenant.  
			2022-09-30 Terry E Dow - Added support for Microsoft.Online.SharePoint.PowerShell module in Get-Tentant.  

		.LINK
	#>
	[CmdletBinding(
		SupportsShouldProcess = $TRUE # Enable support for -WhatIf by invoked destructive cmdlets.
	)]
	Param(
			[ Parameter( HelpMessage='Specify a folder path or UNC where the output file is written.' ) ]
		[String] $OutFolderPath = '.\Reports',

			[ Parameter( HelpMessage='Specifiy the script''s executing environment organization name.  Must be either; "TenantName", "msExchOrganizationName", "ForestName", "DomainName", "ComputerName", or an arbitrary string including empty string "" or $NULL.' ) ]
			[Alias('ExecutionSource')]
		[String] $OrganizationName = 'TenantName',

			[ Parameter( HelpMessage='Optional string added to the end of the output file name proper (disregarding date time stamp location).' ) ]
		[String] $OutFileNameTag = '',

			[ Parameter( HelpMessage='Optionally specify a date time stamp string in a format that is standard for the local system''s culture ( (Get-Culture).DateTimeFormat ).' ) ]
		[String] $DateTimeLocal = '',
			
			[ Parameter( HelpMessage='Optionally specify a date time stamp format.  Default is sortable date/time stamp in ISO-8601:2004 basic format ''yyyyMMdd\THHmmsszzz''' ) ]
		[String] $DateTimeStampFormat = 'yyyyMMdd\THHmmsszzz',
		
			[ Parameter( HelpMessage='Optionally specify a date time stamp string location in the file name to be at the "Start" (default), "End", or "None".' ) ]
			[ ValidateSet( 'Start', 'End', 'None', '', $NULL ) ]
		[String] $DateTimeStampLocation = 'Start',
		
			[ Parameter( HelpMessage='Optionally specify the number of days added or subtracted from the current date or the optionally supplied -DateTimeLocal value.' ) ]
		[Int] $DateOffsetDays = 0,

			[ Parameter( HelpMessage='Optional file name component delimiter.  The specified string cannot be an invalid file name character.' ) ]
			[ ValidateScript( { [System.IO.Path]::GetInvalidFileNameChars() -NotContains $PSItem } ) ]
		[String] $FileNameComponentDelimiter = '-',

			[ Parameter( HelpMessage='Optionally specify which character to use to replace invalid folder and file name characters.  The specified string cannot be an invalid folder or file name character.' ) ]
			[ ValidateScript( { [System.IO.Path]::GetInvalidPathChars() -NotContains $PSItem -And [System.IO.Path]::GetInvalidFileNameChars() -NotContains $PSItem } ) ]
		[String] $InvalidFilePathCharsSubstitute = '_'
	)
	
	#Requires -version 3
	Set-StrictMode -Version Latest
	
	# Detect cmdlet common parameters.
	$cmdletBoundParameters = $PSCmdlet.MyInvocation.BoundParameters
	$Confirm = If ( $cmdletBoundParameters.ContainsKey('Confirm') ) { $cmdletBoundParameters['Confirm'] } Else { $FALSE }
	$Debug = If ( $cmdletBoundParameters.ContainsKey('Debug') ) { $cmdletBoundParameters['Debug'] } Else { $FALSE }
	# Replace default -Debug preference from 'Inquire' to 'Continue'.
	If ( $DebugPreference -Eq 'Inquire' ) { $DebugPreference = 'Continue' }
	$Verbose = If ( $cmdletBoundParameters.ContainsKey('Verbose') ) { $cmdletBoundParameters['Verbose'] } Else { $FALSE }
	$WhatIf = If ( $cmdletBoundParameters.ContainsKey('WhatIf') ) { $cmdletBoundParameters['WhatIf'] } Else { $FALSE }
	
	#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8
	# Declare internal functions.
	#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8

	Function Get-ComputerName {
		#Write-Output (Get-CimInstance -ClassName CIM_ComputerSystem -Property Name).Name
		Write-Output (Get-ComputerInfo -Property csName).csName 
	}
	
	Function Get-DomainName {
		Write-Output ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().GetDirectoryEntry()).Name
	}

	Function Get-ForestName {
		# Write-Output ([System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()).Name # Returns Forest full DNS name.
		# Presumptuously getting 2nd to last domain name component.  First component may be too generic (e.g. 'CORP', 'GLOBAL', 'RESOURCE', et al).  
		Write-Output ([System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()).Name.Split('.')[-2] 
	}
	
	Function Get-MsExchOrganizationName {
		$currentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
		$rootDomainDN = $currentForest.RootDomain.GetDirectoryEntry().DistinguishedName
		$msExchConfigurationContainerSearcher = New-Object DirectoryServices.DirectorySearcher
		$msExchConfigurationContainerSearcher.SearchRoot = "LDAP://CN=Microsoft Exchange,CN=Services,CN=Configuration,$rootDomainDN"
		$msExchConfigurationContainerSearcher.Filter = '(objectCategory=msExchOrganizationContainer)'
		$msExchConfigurationContainerResult = $msExchConfigurationContainerSearcher.FindOne()
		Write-Output $msExchConfigurationContainerResult.Properties.Item('Name')
	}

	Function Get-TenantName {
		# Assuming we're already connected via one of these: Connect-MgGraph (Microsoft.Graph), Connect-AzAccount (Az.Accounts), Connect-ExchangeOnline (ExchangeOnlineManagement), on-premises Exchange Server, Microsoft Teams (MicrosoftTeams module), SharePoint Online Management Shell (Microsoft.Online.SharePoint.PowerShell module), Connect-AzureAD (AzureAD), or Connect-MsolService (MSOnline)
		
		$tenantName = ''
		# $tenatId = ''

		# Try if connected via Connect-MgGraph [Microsoft Graph PowerShell (Microsoft.Graph module)]
		If ( (-Not $tenantName) -And (Get-Module -Name Microsoft.Graph.Authentication) -And ([Bool] (Get-MgContext)) ) {
			Try {
				$mgOrgainization = Get-MgOrganization -ErrorAction Stop -Verbose:$FALSE -Debug:$FALSE
				$mgVerifiedDomainDefault = ( ($mgOrgainization).VerifiedDomains | Where-Object { $PSItem.IsDefault } ).Name
				#$mgVerifiedDomainInitial = ( ($mgOrgainization).VerifiedDomains | Where-Object { $PSItem.IsInitial } ).Name			
				# Get default domain's first domain name component.
				$tenantName = ( $mgVerifiedDomainDefault.Split( '.' ) )[0] 
				#$tenantId = $mgOrgainization.Id
				Write-Debug "Get-MgOrganization found TenantName: $tenantName"
			} Catch {
				Write-Debug $PSItem.Exception.Message 
			}
		}

		# Try if connected via Connect-AzAccount [Azure Resource Manager/Azure Active Directory Graph (Az.Accounts module)]
		If ( (-Not $tenantName) -And (Get-Module -Name Az.Accounts) -And ([Bool] (Get-AzContext)) ) {
			Try {
				$azTenant = Get-AzTenant -ErrorAction Stop -Verbose:$FALSE -Debug:$FALSE
				# Get default domain's first domain name component.
				$tenantName = ( $azTenant.DefaultDomain.Split( '.') )[0] 
				#$tenantId = $azTenant.TenantId
				Write-Debug "Get-AzTenant found TenantName: $tenantName"
			} Catch {
				Write-Debug $PSItem.Exception.Message 
			}
		}
				
		# Try if connected via Connect-ExchangeOnline [Exchange Online PowerShell V3 (ExchangeOnlineManagement module)]
		If ( (-Not $tenantName) -And (Get-Module -Name ExchangeOnlineManagement) -And ( ( [Bool] (Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.State -Eq 'Opened' -And $PSItem.ComputerName -Eq 'outlook.office365.com' } ) -Or ( [Bool] (Get-ConnectionInformation) ) ) ) ) { # OR Connect-IPPSSession: -And $PSItem.ComputerName -Like '*.ps.compliance.protection.outlook.com'
			Try {
				$exoAcceptedDomains = Get-AcceptedDomain -Verbose:$FALSE -Debug:$False
				#$exoAcceptedDomainNameCoexistence = If ( $exoAcceptedDomains.IsCoexistenceDomain -Contains $TRUE ) { ($exoAcceptedDomains | Where-Object { $PSItem.IsCoexistenceDomain }).DomainName.ToString() } Else { '' }
				$exoAcceptedDomainNameDefault = ($exoAcceptedDomains | Where-Object { $PSItem.Default }).DomainName
				#$exoAcceptedDomainNameInitial = ($exoAcceptedDomains | Where-Object { $PSItem.InitialDomain }).DomainName
				# Get default domain's first domain name component.
				$tenantName = ( $exoAcceptedDomainNameDefault.Split( '.' ) )[0] 
				#If ( $tenantName ) { $tenantId = (Invoke-WebRequest "https://login.windows.net/$tenantName.onmicrosoft.com/.well-known/openid-configuration" | ConvertFrom-Json).token_endpoint.Split('/')[3] } Else { $tenantId = $NULL }
				Write-Debug "Get-AcceptedDomain (V2/3) found TenantName: $tenantName"
			} Catch { 
				Write-Debug $PSItem.Exception.Message 
			}
		}

		# Try if connected via on-premises Exchange mailbox management admin server PowerShell (Exchange Management Shell)
		If ( (-Not $tenantName) -And (Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And ( $PSItem.Name -Like 'ExchangeSession*' -Or $PSItem.Name -Like 'Session*' ) -And $PSItem.State -Eq 'Opened' }) ) {
			Try {
				#$exchAcceptedDomains = Get-AcceptedDomain -Verbose:$FALSE -Debug:$False
				$exchAcceptedDomains = Get-ExchAcceptedDomain -Verbose:$FALSE -Debug:$False
				#$exchAcceptedDomainNameCoexistence = If ( $exchAcceptedDomains.IsCoexistenceDomain -Contains $TRUE ) { ($exchAcceptedDomains | Where-Object { $PSItem.IsCoexistenceDomain }).DomainName.ToString() } Else { '' }
				$exchAcceptedDomainNameDefault = ($exchAcceptedDomains | Where-Object { $PSItem.Default }).DomainName
				#$exchAcceptedDomainNameInitial = ($exchAcceptedDomains | Where-Object { $PSItem.InitialDomain }).DomainName
				# Get default domain's first domain name component.
				$tenantName = ( $exchAcceptedDomainNameDefault.Split( '.' ) )[0] 
				#If ( $tenantName ) { $tenantId = (Invoke-WebRequest "https://login.windows.net/$tenantName.onmicrosoft.com/.well-known/openid-configuration" | ConvertFrom-Json).token_endpoint.Split('/')[3] } Else { $tenantId = $NULL }
				Write-Debug "Get-AcceptedDomain (V1) found TenantName: $tenantName"
			} Catch { 
				Write-Debug $PSItem.Exception.Message 
			}
		}
		
		# Try if connected via Microsoft Teams (MicrosoftTeams module)
		If ( (-Not $tenantName) -And (Get-Module -Name MicrosoftTeams)  ) {
			Try {
				$csTenant = Get-CsTenant -ErrorAction Stop -Verbose:$FALSE -Debug:$False | Out-Null
				#$csVerifiedDomainInitial = $csTenant.VerifiedDomains[0].Name # presume first verified domain is Initial.  
				$csVerifiedDomainDefault = If ( 1 -LT ($csTenant.VerifiedDomains).Count ) { $csTenant.VerifiedDomains[1].Name } # presume second verified domain is Default.  
				# Get default domain's first domain name component.
				$tenantName = ( $csVerifiedDomainDefault.Split( '.' ) )[0] 
				#$tenantId = $csTenant.TenantId
				Write-Debug "Get-CsTenant found TenantName: $tenantName"
			} Catch { 
				Write-Debug $PSItem.Exception.Message 
			}
		}
		
		# Try if connected via SharePoint Online Management Shell (Microsoft.Online.SharePoint.PowerShell module)
		If ( (-Not $tenantName) -And (Get-Module -Name Microsoft.Online.SharePoint.PowerShell)  ) {
			Try {
				Get-SPOSite -ErrorAction Stop -Verbose:$FALSE -Debug:$False |
					ForEach-Object {
						$spoSite = $PSItem
						# Find root level SPO site that ends with a forward-slash.  
						If ( $spoSite.Url.EndsWith('/') ) {
							# Extract first domain name component https://<contoso>.sharepoint.com/
							$spoSiteDomain = (($spoSite.Url.Split('/'))[2].Split('.'))[0]
							# Extract tenant name, that is not Admin (contoso-admin) or OneDrive (contoso-my).  
							If ( -Not ( $spoSiteDomain.EndsWith( '-admin' ) -Or $spoSiteDomain.EndsWith( '-my' ) ) ) {
								$tenantName = $spoSiteDomain
							}
						}
					}
				#If ( $tenantName ) { $tenantId = (Invoke-WebRequest "https://login.windows.net/$tenantName.onmicrosoft.com/.well-known/openid-configuration" | ConvertFrom-Json).token_endpoint.Split('/')[3] } Else { $tenantId = $NULL }
				Write-Debug "Get-SPOSite found TenantName: $tenantName"
			} Catch { 
				Write-Debug $PSItem.Exception.Message 
			}
		}
		
		# Try if connected via Connect-AzureAd [AzureAD V2 – Azure Active Directory PowerShell for Graph (AzureAD module)] # Deprecated 2022-06-30.
		If ( (-Not $tenantName) -And (Get-Module -Name AzureAD) -And ([Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::AccessTokens) ) {
			Try {
				# Get default domain's first domain name component.
				$tenantName = ( (Get-AzureADDomain -ErrorAction Stop -Verbose:$FALSE -Debug:$FALSE | Where-Object { $PSItem.IsDefault }).Name.Split( '.') )[0] 
				#$tenantId = (Get-AzureADTenantDetail -ErrorAction Stop -Verbose:$FALSE -Debug:$FALSE).ObjectId
				Write-Debug "Get-AzureADDomain found TenantName: $tenantName"
			} Catch {
				Write-Debug $PSItem.Exception.Message 
			}
		}
		
		# Try if connected via Connect-MsolService [AzureAD V1 – Microsoft Azure Active Directory Module for Windows PowerShell (MSOnline module)] # Deprecated 2022-06-30.
		If ( (-Not $tenantName) -And (Get-Module -Name MSOnline) ) {
			Try {			
				# Get default domain's first domain name component.
				$tenantName = ( (Get-MsolDomain -ErrorAction Stop -Verbose:$FALSE -Debug:$FALSE | Where-Object { $PSItem.IsDefault }).Name.Split( '.') )[0] 
				#$tenantId = (Get-MSOLCompanyInformation -ErrorAction Stop -Verbose:$FALSE -Debug:$FALSE).ObjectId.Guid
				Write-Debug "Get-MsolDomain found TenantName: $tenantName"
			} Catch {
				Write-Debug $PSItem.Exception.Message 
			}
		}
		
		If ( $tenantName ) {
			Write-Output $tenantName
		} Else {
			Write-Debug 'Get-TenantName is throwing an error.'
			Throw 'M365 Tenant not found.' # in support of Try/Catch block.  
		}
	}

	#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8
	# Build output folder path.
	#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8
	
	# Replace invalid folder characters: "<>| and others.
	$OutFolderPath = [RegEx]::Replace( $OutFolderPath, "[$([System.IO.Path]::GetInvalidPathChars())]", $InvalidFilePathCharsSubstitute )
	Write-Debug "`$OutFolderPath:,$OutFolderPath"
	
	# Get the current path.  If invoked from a script...
	Write-Debug "`$script:MyInvocation.InvocationName:,$($script:MyInvocation.InvocationName)"
	If ( $script:MyInvocation.InvocationName ) {
		# ...get the parent script's command path.
		$currentPath = Split-Path $script:MyInvocation.MyCommand.Path -Parent
	} Else {
		# ...else get the current location.
		$currentPath = (Get-Location).Path
	}
	Write-Debug "`$currentPath:,$currentPath"
	
	# Get the full path of the combined folders of the current path and the specified output folder (which may be a relative path).
	$OutFolderPath = [System.IO.Path]::GetFullPath( [System.IO.Path]::Combine( $currentPath, $OutFolderPath ) )

	# Verify Output folder path name has trailing directory separator character.
	If ( -Not $OutFolderPath.EndsWith( [System.IO.Path]::DirectorySeparatorChar ) ) {
		$OutFolderPath += [System.IO.Path]::DirectorySeparatorChar
	}
	Write-Debug "`$OutFolderPath:,$OutFolderPath"

	# If the output folder does not exist and not a UNC path, try to create and set it to compressed recursively.
	If ( -Not ((Test-Path $OutFolderPath -PathType Container) -Or ($OutFolderPath -Match '^\\\\[^\\]+\\')) ) {
		New-Item -Path $OutFolderPath -ItemType Directory -WhatIf:$FALSE > $NULL
		Get-CimInstance -ClassName CIM_Directory -Filter "Name='$($OutFolderPath.Replace('\','\\').TrimEnd('\'))'" |
			Invoke-CimMethod -MethodName CompressEx -Arguments @{ Recursive = $TRUE } -WhatIf:$FALSE > $NULL
	}

	#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8
	# Build file name components.
	#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8

	# Get date/time stamp string.
	$dateTime = $NULL
	If ( $DateTimeLocal ) {
		Try { $dateTime = (Get-Date -Date $DateTimeLocal).AddDays($DateOffsetDays) } 
		Catch { $dateTime = (Get-Date).AddDays($DateOffsetDays) }
	} Else {
		$dateTime = (Get-Date).AddDays($DateOffsetDays)
	}
	# Generate date/time stamp string and remove invalid file name characters (like colons (:)).
	If ( -Not $DateTimeStampFormat ) { $DateTimeStampFormat = 'yyyyMMdd\THHmmsszzz' }
	Try {
		$dateTimeStamp = [RegEx]::Replace( $dateTime.ToString( $DateTimeStampFormat ), "[$([System.IO.Path]::GetInvalidFileNameChars())]", '' )
	} Catch {
		$dateTimeStamp = [RegEx]::Replace( $dateTime.ToString( 'yyyyMMdd\THHmmsszzz' ), "[$([System.IO.Path]::GetInvalidFileNameChars())]", '' )
	}
	Write-Debug "`$dateTimeStamp:,$dateTimeStamp"
	
	# Get executing environment's organization name.
	Switch ( $OrganizationName ) {
	
		'TenantName' {
			# Try to get current M365 tenant name, else get Exchange organization name, domain or computer name.
			Try {
				$organizationNameValue = Get-TenantName
				Write-Debug "Get-TenantName found TenantName: $organizationNameValue"
			} Catch {				
				
				# Try to get current forest's Exchange organization name, else get domain or computer name.
				Try {
					$organizationNameValue = Get-MsExchOrganizationName
					Write-Debug "Get-MsExchOrganizationName found TenantName: $organizationNameValue"
				} Catch {
				
					# Try to get current forest name, else get computer name.
					Try {
						$organizationNameValue = Get-ForestName
						Write-Debug "Get-ForestName found TenantName: $organizationNameValue"
					} Catch {
					
						# Try to get current domain name, else get computer name.
						Try {
							$organizationNameValue = Get-DomainName
							Write-Debug "Get-DomainName found TenantName: $organizationNameValue"
						} Catch {
							$organizationNameValue = Get-ComputerName
							Write-Debug "Get-ComputerName found TenantName: $organizationNameValue"
						}
					}
					
				}
			}
			Break
		}
		
		'msExchOrganizationName' {
			# Try to get current forest's Exchange organization name, else get domain or computer name.
			Try {
				$organizationNameValue = Get-MsExchOrganizationName
				Write-Debug "Get-MsExchOrganizationName found msExchOrganizationName: $organizationNameValue"
			} Catch {
			
				# Try to get current forest name, else get computer name.
				Try {
					$organizationNameValue = Get-ForestName
					Write-Debug "Get-ForestName found msExchOrganizationName: $organizationNameValue"
				} Catch {
				
					# Try to get current domain name, else get computer name.
					Try {
						$organizationNameValue = Get-DomainName
						Write-Debug "Get-DomainName found msExchOrganizationName: $organizationNameValue"
					} Catch {
						$organizationNameValue = Get-ComputerName
						Write-Debug "Get-ComputerName found msExchOrganizationName: $organizationNameValue"
					}
				}
				
			}
			Break
		}
		
		'ForestName' {
			# Try to get current forest name, else get domain or computer name.
			Try {
				$organizationNameValue = Get-ForestName
				Write-Debug "Get-ForestName found ForestName: $organizationNameValue"
			} Catch {
			
				# Try to get current domain name, else get computer name.
				Try {
					$organizationNameValue = Get-DomainName
					Write-Debug "Get-DomainName found ForestName: $organizationNameValue"
				} Catch {
					$organizationNameValue = Get-ComputerName
					Write-Debug "Get-ComputerName found ForestName: $organizationNameValue"
				}
				
			}
			Break
		}

		'DomainName' {
			# Try to get current domain name, else get computer name.
			Try {
				$organizationNameValue = Get-DomainName
				Write-Debug "Get-DomainName found DomainName: $organizationNameValue"
			} Catch {
				$organizationNameValue = Get-ComputerName
				Write-Debug "Get-ComputerName found DomainName: $organizationNameValue"
			}
			Break
		}

		'ComputerName' {
			# Get current computer name.
			$organizationNameValue = Get-ComputerName
			Write-Debug "Get-ComputerName found ComputerName: $organizationNameValue"
			Break
		}

		{ -Not $PSItem } { # If empty string '' or $NULL
			$organizationNameValue = ''
			Break
		}

		Default {
			# Pass specified arbitrary string.
			$organizationNameValue = $OrganizationName
		}
	}
	Write-Debug "`$organizationNameValue:,$organizationNameValue"

	# Get current script name.
	Write-Debug "`$script:MyInvocation.ScriptName:,$($script:MyInvocation.ScriptName)"
	Write-Debug "`$MyInvocation.ScriptName:,$($MyInvocation.ScriptName)"
	If ( $Script:MyInvocation.ScriptName ) {
		$myScriptFileName = [System.IO.Path]::GetFileNameWithoutExtension( $Script:MyInvocation.ScriptName ) # Import-Module
	} Else {
		$myScriptFileName = [System.IO.Path]::GetFileNameWithoutExtension( $MyInvocation.ScriptName ) # dot-sourced
	}
	Write-Debug "`$myScriptFileName:,$myScriptFileName"
	
	Write-Debug "`$OutFileNameTag:,$OutFileNameTag"

	#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8
	# Build file path name without extension.
	#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8

	# Join non-null file name components with delimiter.
	Switch ( $DateTimeStampLocation ) {
	
		{ $PSItem -EQ 'Start' -Or $PSItem -EQ '' -Or $PSItem -EQ $NULL } {
			$outFileName =  ( $( ( $dateTimeStamp, $organizationNameValue, $myScriptFileName, $OutFileNameTag ) | Where-Object { $PSItem } ) -Join $FileNameComponentDelimiter).Trim( $FileNameComponentDelimiter )
		}

		'End' {
			$outFileName =  ( $( ( $organizationNameValue, $myScriptFileName, $OutFileNameTag, $dateTimeStamp ) | Where-Object { $PSItem } ) -Join $FileNameComponentDelimiter).Trim( $FileNameComponentDelimiter )
		}

		'None' {
			$outFileName =  ( $( ( $organizationNameValue, $myScriptFileName, $OutFileNameTag ) | Where-Object { $PSItem } ) -Join $FileNameComponentDelimiter).Trim( $FileNameComponentDelimiter )
		}
			
	}
	
	# Replace invalid file name characters: "*/:<>?[\]|
	$outFileName = [RegEx]::Replace( $outFileName, "[$([System.IO.Path]::GetInvalidFileNameChars())]", $InvalidFilePathCharsSubstitute )
	Write-Debug "`$outFileName:,$outFileName"
	
	# Join folder path and file name and other information derived from this solution.
	Write-Debug "Value:,$OutFolderPath$outFileName"
	Write-Output ( [PSCustomObject] @{ 
		Value = "$OutFolderPath$outFileName"
		FolderPath = $OutFolderPath
		FileName = $outFileName
		DateTimeStamp = $dateTimeStamp
		OrganizationName = $organizationNameValue
		ExecutionSourceName = $organizationNameValue # Legacy support. To be deprecated.  
		ScriptFileName = $myScriptFileName 
	} )
}
