<# Execution Examples:
$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
. .\Set-M365AdminTemplate.ps1; Set-M365AdminTemplate -AdminCredential $adminCredential -ConnectExchangeServer -ExchangeServerFqdn Exch01.domain.com 

$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
. .\Set-M365AdminTemplate.ps1; Set-M365AdminTemplate -AdminCredential $adminCredential -ConnectAzAccount -ConnectExchangeServer -ConnectExchangeOnline 

$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
. .\Set-M365AdminTemplate.ps1; Set-M365AdminTemplate -AdminCredentialUserName $adminCredential.UserName -ConnectAzAccount -ConnectExchangeServer -ConnectExchangeOnline -ConnectIPPSSession -ConnectMgGraph -ConnectMicrosoftTeams -ConnectSPOService

. .\Set-M365AdminTemplate.ps1; Set-M365AdminTemplate -AdminCredentialUserName Admin@domain.com -AdminCredentialPasswordFilePath .\SecureCredentialPassword.txt -ConnectAzAccount -ConnectExchangeServer -ConnectExchangeOnline -ConnectIPPSSession -ConnectMgGraph -ConnectMicrosoftTeams -ConnectSPOService

. .\Set-M365AdminTemplate.ps1; Set-M365AdminTemplate -AdminCredentialUserName Admin@domain.com -ConnectAzAccount -ConnectExchangeServer -ConnectExchangeOnline -ConnectIPPSSession -ConnectMgGraph

. .\Set-M365AdminTemplate.ps1; Set-M365AdminTemplate -Tenant domain.onmicrosoft.com -ApplicationId 36ee4c6c-0812-40a2-b820-b22ebd02bce3 -CertificateThumbprint 83213AEAC56D61C97AEE5C1528F4AC5EBA7321C1 -ConnectAzAccount -ConnectExchangeServer -ConnectExchangeOnline -ConnectIPPSSession -ConnectMgGraph

. .\Set-M365AdminTemplate.ps1; Set-M365AdminTemplate -Tenant 71c3c5b7-6481-4751-b3e9-06b574584e6b -ApplicationId 36ee4c6c-0812-40a2-b820-b22ebd02bce3 -CertificateThumbprint 83213AEAC56D61C97AEE5C1528F4AC5EBA7321C1 -ConnectAzAccount -ConnectExchangeServer -ConnectExchangeOnline -ConnectIPPSSession -ConnectMgGraph
#>
<# Post Ctrl+C/abnormal termination clean up:
Disconnect-M365Admin
Stop-Transcript
#>


Function Get-M365AdminTemplate {
	<#
	
		.SYNOPSIS
			Template script that connects to M365 services (workload).

		.DESCRIPTION
			Template script that connects to M365 services (workload):
				Azure ActiveDirectory PowerShell (Az.Resources module)
				Exchange Online PowerShell V3 (ExchangeOnlineManagement module)
				Security & Compliance PowerShell via Exchange Online PowerShell V3 (ExchangeOnlineManagement module)
				Exchange Server PowerShell (Exchange Management Shell)
				SharePoint Online (Microsoft.Online.SharePoint.PowerShell module)
				Microsoft Teams (MicrosoftTeams module)
				PowerShell SDK for Microsoft Graph (Microsoft.Graph module)
			
		.PARAMETER AdminCredential 
			The Credential parameter specifies the administrator's user name and password that's used to run this command. Typically, you use this parameter in scripts or when you need to provide different credentials that have the required permissions.
			This parameter requires the creation and passing of a credential object. This credential object is created by using the Get-Credential cmdlet. For more information, see Get-Credential (http://go.microsoft.com/fwlink/p/?linkId=142122).

		.PARAMETER AdminCredentialUserName 
			Specifies an administrator's user name for the credential in User Principal Name (UPN) format, such as "user@domain.com". Use the period (.) to get the current user's UPN.
			The UserPrincipalName parameter specifies the account that you want to use to connect (for example, navin@contoso.onmicrosoft.com). Using this parameter allows you to skip the username dialog in the modern authentication prompt for credentials (you only need to enter your password).
			
		.PARAMETER AdminCredentialPasswordFilePath 
			Specifies file name where the administrator's secure credential password file is located.  The default of null will prompt for the credentials.
			SecureString is encoded with default Data Protection API (DPAPI) with a DataProtectionScope of CurrentUser and LocalMachine security tokens.
			To write a secure (encrypted) string file:
			
			Read-Host -AsSecureString "Securely enter password" | ConvertFrom-SecureString | Out-File -FilePath '.\SecureCredentialPassword.txt'

		.PARAMETER ApplicationId 
			Specifies the application ID of the service principal.
			The AppId parameter specifies the application ID of the service principal that's used in certificate based authentication (CBA). A valid value is the GUID of the application ID (service principal). For example, 36ee4c6c-0812-40a2-b820-b22ebd02bce3.
			The client id of your application.
			
		.PARAMETER CertificateThumbprint 
			Certificate Hash or Thumbprint.
			The CertificateThumbprint parameter specifies the certificate that's used for CBA. A valid value is the thumbprint value of the certificate. For example, 83213AEAC56D61C97AEE5C1528F4AC5EBA7321C1.
			Specifies the certificate thumbprint of a digital public key X.509 certificate of a user account that has permission to perform this action.
			The thumbprint of your certificate. The Certificate will be retrieved from the current user's certificate store.

		.PARAMETER ExchangeServerFqdn 
			One or more on-premises Exchange mailbox management admin server fully qualified domain name. If not specified a list of server FQDNs will be collected from on-premises Active Directory and one will be randomly selected.  
 
		.PARAMETER Tenant 
			Optional tenant name or ID.
			The Organization parameter specifies the organization that's used in CBA. Be sure to use an .onmicrosoft.com domain for the parameter value. Otherwise, you might encounter cryptic permission issues when you run commands in the app context.
			
		.PARAMETER AuthenticationUrl 
			SharePoint Online location for AAD Cross-Tenant Authentication service. Can be optionally used if non-default Cross-Tenant Authentication Service is used.

		.PARAMETER Url 
			Specifies the URL of the SharePoint Online Administration Center site.

		.PARAMETER OutFolderPath 
			Specify where to write the output file.  The default is the sub-folder '.\Reports'.  
		
		.PARAMETER OrganizationName 
			Specify the script's executing environment organization name.  Must be either: 
				TenantName
				msExchOrganizationName
				ForestName
				DomainName
				ComputerName
				an arbitrary string 
				'' or $NULL 

		.PARAMETER OutFileNameTag 
				Optional string added to the end of the output file name.
		
		.PARAMETER AlertOnly 
			When enabled, only unhealthy items are reported.
			
		.PARAMETER MailFrom 
			Optionally specify the address from which the mail is sent.
			
		.PARAMETER MailTo 
			Optionally specify the addresses to which the mail is sent.
			
		.PARAMETER MailServer 
			Optionally specify the name of the SMTP server that sends the mail message. Either:
				An accessible on-premises MailHost FQDN
				via Direct Send to internal "$tenantName.mail.protection.outlook.com", SendAs app credentials required ('Microsoft Graph', 'Mail.Send')
				via SMTP Client Submission 'smtp.office365.com', user credentials required
			
		.PARAMETER CompressAttachmentLargerThan 
			If the mail message attachment is over this size compress (zip) it.

		.EXAMPLE 


		.NOTES
			2022-09-23 Terry E Dow - Initial version
			
		.LINK
			Exchange Online PowerShell https://docs.microsoft.com/en-us/powershell/exchange/exchange-online-powershell
			Exchange Server PowerShell (Exchange Management Shell) https://docs.microsoft.com/en-us/powershell/exchange/exchange-management-shell
			Intro to SharePoint Online Management Shell https://docs.microsoft.com/en-us/powershell/sharepoint/sharepoint-online/introduction-sharepoint-online-management-shell
			Introducing the Azure Az PowerShell module https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az
			Microsoft Graph PowerShell overview https://docs.microsoft.com/en-us/powershell/microsoftgraph/overview
			Microsoft Teams PowerShell Overview https://docs.microsoft.com/en-us/microsoftteams/teams-powershell-overview
			Security & Compliance PowerShell https://docs.microsoft.com/en-us/powershell/exchange/scc-powershell
			Deep Dive: How Hybrid Authentication Really Works https://techcommunity.microsoft.com/t5/exchange-team-blog/deep-dive-how-hybrid-authentication-really-works/ba-p/606780
	#>
	[CmdletBinding(
		SupportsShouldProcess = $TRUE # Enable support for -WhatIf by invoked destructive cmdlets.
	)]
	Param (

		# Get-M365AdminTemplate parameters:			

		# Get-EXOMailbox parameters:
		[String] $ResultSize = 'Unlimited',

		[ValidateSet( '', 'DiscoveryMailbox', 'EquipmentMailbox', 'GroupMailbox', 'LegacyMailbox', 'LinkedMailbox', 'LinkedRoomMailbox', 'RoomMailbox', 'SchedulingMailbox', 'SharedMailbox', 'TeamMailbox', 'UserMailbox' )]
		[String] $RecipientTypeDetails = '',

				# Common authentication parameters for Microsoft 365 services (workloads):		
		
			[Parameter(
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet', 
				Mandatory=$TRUE,
				ValueFromPipelineByPropertyName=$TRUE 
			)]
			[Parameter( 
				ParameterSetName = 'UserModernAuthParameterSet', 
				ValueFromPipelineByPropertyName=$TRUE 
			)] 
			[Alias( 'Credential' )]
		[System.Management.Automation.Credential()] $AdminCredential = [System.Management.Automation.PSCredential]::Empty,
				
			[Parameter( 
				ParameterSetName = 'UserBasicAuthWithUserNamePasswordFileParameterSet',
				Mandatory=$TRUE,
				ValueFromPipelineByPropertyName=$TRUE 
			)] 
			[Parameter( 
				ParameterSetName = 'UserModernAuthParameterSet', 
				ValueFromPipelineByPropertyName=$TRUE 
			)] 
		[String] $AdminCredentialUserName,  
		
			[Parameter( 
				ParameterSetName = 'UserBasicAuthWithUserNamePasswordFileParameterSet', 
				Mandatory=$TRUE,
				ValueFromPipelineByPropertyName=$TRUE 
			)] 
			[Parameter( 
				ParameterSetName = 'UserModernAuthParameterSet', 
				ValueFromPipelineByPropertyName=$TRUE 
			)] 
		[String] $AdminCredentialPasswordFilePath,
		
			[Parameter(
				ParameterSetName = 'AppCertificateBasedAuthParameterSet', 
				Mandatory=$TRUE,
				ValueFromPipelineByPropertyName=$TRUE
			)]
			[Alias( 'ApplicationName' )]
		[String] $ApplicationId,

			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				Mandatory=$TRUE,
				ParameterSetName = 'AppCertificateBasedAuthParameterSet' 
			)]
		[String] $CertificateThumbPrint,

			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet' 
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithUserNamePasswordFileParameterSet' 
			)]			
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserModernAuthParameterSet' 
			)]
		[String[]] $Scopes,
		
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'AppCertificateBasedAuthParameterSet',
				Mandatory=$TRUE,
				HelpMessage = 'The Tenant parameter specifies the organization that''s used in CBA. Be sure to use an .onmicrosoft.com domain for the parameter value. Otherwise, you might encounter cryptic permission issues when you run commands in the app context.' 
			)]
			# [ValidateScript( { $PSItem -Eq $NULL -Or $PSItem -Like '*.onmicrosoft.com' -Or [guid]::TryParse( $PSItem, [ref][guid]::Empty ) } )]																															
			[Alias( 'Organization', 'TenantId', 'TenantInitialDomain' )]
		[String] $Tenant,
		
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet' 
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithUserNamePasswordFileParameterSet' 
			)]	
		[Switch] $UseBasicAuth,

		
		# Connect-SPOService parameters:						  
		
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE
			)]
			[Alias( 'TenantAdminUrl' )]  
		[String] $Url, # https://contoso-admin.sharepoint.com
		
		# New-[Exchange]PSSession (on-premises) custom parameters:													
		
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE
			)]
		[String[]] $ExchangeServerFqdn, 

		# New-OutFilePathBase parameters:						   
			
			[Parameter( 
				HelpMessage = 'Specify where to write the output file.' 
			)]
		[String] $OutFolderPath,
		
			[Parameter( 
				HelpMessage = 'Specifiy the script''s executing environment organization name.  Must be either: "TenantName", "msExchOrganizationName", "ForestName", "DomainName", "ComputerName", or an arbitrary string including "" or $NULL.' 
			)]
		[String] $OrganizationName = 'TenantName',

			[Parameter( 
				HelpMessage = 'Optional string added to the end of the output file name.' 
			)]
		[String] $OutFileNameTag,
		
		# Send-MailMessage parameters:						
		
			[Parameter( 
				HelpMessage='When enabled, only unhealthy items are reported.' 
			) ]
		[Switch] $AlertOnly = $FALSE,
		
			[Parameter( 
				HelpMessage = 'Optionally specify the address from which the mail is sent.' 
			) ]
		[String] $MailFrom,
		
			[Parameter( 
				HelpMessage = 'Optioanlly specify the addresses to which the mail is sent.' 
			) ]
		[String[]] $MailTo,
		
			[Parameter( 
				HelpMessage = 'Optionally specify the name of the SMTP server that sends the mail message.' 
			) ]
		[String] $MailServer,

			[Parameter( 
				HelpMessage = 'If the mail message attachment is over this size compress (zip) it.' 
			) ]
		[Int] $CompressAttachmentLargerThan = 5MB
 
	)
	
	Begin {
		
		#Set-StrictMode -Version Latest
		
		# Collect script execution metrics.
		$scriptStartTime = Get-Date
		$dateTimeStamp = [RegEx]::Replace( $scriptStartTime.ToString('yyyyMMdd\THHmmsszzz'),"[$([System.IO.Path]::GetInvalidFileNameChars())]", '' )
		Write-Verbose "`$MyInvocation.MyCommand.Name Begin: '$($MyInvocation.MyCommand.Name)'"
		Write-Verbose "`t`$scriptStartTime: '$($scriptStartTime.ToString('s'))'" 

		# Detect cmdlet common parameters.
		$cmdletBoundParameters = $PSCmdlet.MyInvocation.BoundParameters
		$Confirm = If ( $cmdletBoundParameters.ContainsKey('Confirm') ) { [Bool] $cmdletBoundParameters['Confirm'] } Else { $FALSE }
		$Debug = If ( $cmdletBoundParameters.ContainsKey('Debug') ) { [Bool] $cmdletBoundParameters['Debug'] } Else { $FALSE }
		# Replace default -Debug preference from 'Inquire' to 'Continue'.
		If ( $DebugPreference -Eq 'Inquire' ) { $DebugPreference = 'Continue' }
		$Verbose = If ( $cmdletBoundParameters.ContainsKey('Verbose') ) { [Bool] $cmdletBoundParameters['Verbose'] } Else { $FALSE }
		$WhatIf = If ( $cmdletBoundParameters.ContainsKey('WhatIf') ) { [Bool] $cmdletBoundParameters['WhatIf'] } Else { $FALSE }
		If ( $Debug ) {
			$silentlyContinueUnlessDebug = 'Continue'
		} Else {
			$silentlyContinueUnlessDebug = 'SilentlyContinue'
		}

		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12
		#region Connect to M365 services (workload) as an system administrator that this solution requires.  
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12

		# Connect to M365 services (workload) based upon this solutions requirements and the parameterset being used.  
		Write-Debug "$(Get-Date) `$PsCmdlet.ParameterSetName: '$($PsCmdlet.ParameterSetName)'"
		Switch ( $PsCmdlet.ParameterSetName ) {
			
			'AppCertificateBasedAuthParameterSet' {
				# Connect-M365Admin -ApplicationId $ApplicationId -CertificateThumbprint $CertificateThumbprint -Tenant $Tenant -ConnectAzAccount -ConnectExchangeOnline -ConnectExchangeServer -ExchangeServerFqdn $ExchangeServerFqdn -ConnectIPPSSession -ConnectMgGraph # not supported with CBA: -ConnectMicrosoftTeams -ConnectSPOService 
				Connect-M365Admin -ApplicationId $ApplicationId -CertificateThumbprint $CertificateThumbprint -Tenant $Tenant -ConnectAzAccount -ConnectExchangeOnline 
			}
		
			'UserBasicAuthWithCredentialParameterSet' {
				# Connect-M365Admin -AdminCredential $AdminCredential -ConnectAzAccount -ConnectExchangeOnline -ConnectExchangeServer -ExchangeServerFqdn $ExchangeServerFqdn -ConnectIPPSSession -ConnectMgGraph -ConnectMicrosoftTeams -ConnectSPOService -Url $Url 
				Connect-M365Admin -AdminCredential $AdminCredential -UseBasicAuth:$UseBasicAuth -ConnectExchangeOnline 
			}
			
			'UserBasicAuthWithUserNamePasswordFileParameterSet' {
				# Connect-M365Admin-AdminCredentialUserName $AdminCredentialUserName -AdminCredentialPasswordFilePath $AdminCredentialPasswordFilePath -ConnectAzAccount -ConnectExchangeOnline -ConnectExchangeServer -ExchangeServerFqdn $ExchangeServerFqdn -ConnectIPPSSession -ConnectMgGraph -ConnectMicrosoftTeams -ConnectSPOService -Url $Url 
				Connect-M365Admin -AdminCredentialUserName $AdminCredentialUserName -AdminCredentialPasswordFilePath $AdminCredentialPasswordFilePath -UseBasicAuth:$UseBasicAuth -ConnectExchangeOnline 
			}
						
			'UserModernAuthParameterSet' {
				# Connect-M365Admin -AdminCredentialUserName $AdminCredentialUserName -ConnectAzAccount -ConnectExchangeOnline -ConnectIPPSSession -ConnectMgGraph -ConnectMicrosoftTeams  # Not supported with ModernAuth: -ConnectExchangeServer -ConnectSPOService
				Connect-M365Admin -AdminCredentialUserName $AdminCredentialUserName -ConnectAzAccount -ConnectExchangeOnline 
			}
			
		}
		#endregion Connect to M365 services (workload) that this solution requires.  
		
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12
		#region Support Active Directory (on-premises) (ActiveDirectory module).
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12

		$win32ComputerSystem = Get-CimInstance -Class Win32_ComputerSystem -Verbose:$FALSE
		$isPartOfDomain = $win32ComputerSystem.PartOfDomain
		Write-Debug "`$isPartOfDomain: '$isPartOfDomain'"
		
		$adForestDomainController = $NULL
		$adForestDomainControllerGlobalCatalog = $NULL
		If ( $isPartOfDomain ) {
			Write-Host "$(Get-Date) Connecting to ActiveDirectory."
			$isDomainController = ( 3 -LT $win32ComputerSystem.DomainRole ) # StandaloneWorkstation=0; MemberWorkstation=1; StandaloneServer=2; MemberServer=3; BackupDomainController=4; PrimaryDomainController=5
			Write-Debug "`$isDomainController: '$isDomainController'"
			
			If ( -Not $isDomainController ) {
				
				# Get Active Directory closest Domain Controller server.  
				$aDDomainController = $NULL
				$aDDomainController = Get-ADDomainController -Discover -NextClosestSite -Service 'ADWS' -ErrorAction $silentlyContinueUnlessDebug
				If ( $aDDomainController ) {
					$adForestDomainController = $aDDomainController.HostName
				} Else {
					$adForestDomainController = $env:LOGONSERVER
				}
				
				# Get Active Directory closest Global Catalog server (with GC port).  
				$aDDomainController = $NULL
				$aDDomainController = Get-ADDomainController -Discover -NextClosestSite -Service 'GlobalCatalog','ADWS' -ErrorAction $silentlyContinueUnlessDebug
				If ( $aDDomainController ) {
					$adForestDomainControllerGlobalCatalog = $aDDomainController.HostName
				}			

			} Else {
				# This is a domain controller - get its DNS name.  
				#$adForestDomainController = (Resolve-DnsName (HOSTNAME) | Where-Object { $PSItem.Type -EQ 'A' }).Name
				$adForestDomainController = (Resolve-DnsName (HOSTNAME))[0].Name
			}
		}
		Write-Verbose "$(Get-Date) `$adForestDomainController: '$adForestDomainController'"
		Write-Verbose "$(Get-Date) `$adForestDomainControllerGlobalCatalog: '$adForestDomainControllerGlobalCatalog'"
		#endregion Support Active Directory (on-premises) (ActiveDirectory module).

		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12
		#region Support on-premises Exchange Server PowerShell (Exchange Management Shell)
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12

		# Assert ViewEntireForest to TRUE.  
		If ( -Not (Get-ExchADServerSettings -ErrorAction SilentlyContinue ).ViewEntireForest ) { Set-ExchADServerSettings -ViewEntireForest:$TRUE -ErrorAction SilentlyContinue }

		$matchByteQuantifiedSize = New-Object RegEx '[\d,.]*\s(?:K|M|G|T)?B\s\((?<ToBytes>[\d,.]*)\sbytes\)', @( 'Compiled', 'IgnoreCase' )
		# $exoMailboxStatistics.TotalItemSize -Replace $matchByteQuantifiedSize, '${ToBytes}'

		#endregion Support on-premises Exchange Server PowerShell (Exchange Management Shell)
		
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12
		#region Prepare OutFiles.
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12
				
		# Create a hash table to splat parameters.  
		$newOutFilePathBaseParameters = @{}
		If ( $OutFolderPath ) { $newOutFilePathBaseParameters.OutFolderPath = $OutFolderPath }
		If ( $OrganizationName ) { $newOutFilePathBaseParameters.OrganizationName = $OrganizationName } 
		If ( $OutFileNameTag ) { $newOutFilePathBaseParameters.OutFileNameTag = $OutFileNameTag } 
		$newOutFilePathBaseParameters.DateTimeLocal = $scriptStartTime
		If ( $Debug ) {
			ForEach ( $key In $newOutFilePathBaseParameters.Keys ) {
				Write-Debug "`$newOutFilePathBaseParameters[$key]`:,$($newOutFilePathBaseParameters[$key])"
			}
		}

		# Define Out and Log file names.  
		$outFilePathBase = New-OutFilePathBase @newOutFilePathBaseParameters
		$outFilePathName = "$($outFilePathBase.Value).csv"
		Write-Debug "`$outFilePathName: '$outFilePathName'"
		$logFilePathName = "$($outFilePathBase.Value).log"
		Write-Debug "`$logFilePathName: '$logFilePathName'"
		#endregion Prepare OutFiles.
		
		# Optionally start PowerShell transcript.
		If ( $Debug -Or $Verbose ) {
			Try { Stop-Transcript -ErrorAction Stop } Catch { }
			Start-Transcript -Path $logFilePathName -WhatIf:$FALSE
		}
		
		# #---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8
		# #region Get Exchange Online Accepted Domain names
		# #---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8

		# $exoAcceptedDomains = Get-AcceptedDomain -Verbose:$FALSE -Debug:$False
		# $exoAcceptedInitialDomainName = ($exoAcceptedDomains | Where-Object { $PSItem.InitialDomain }).DomainName
		# Write-Verbose "`$exoAcceptedInitialDomainName: '$exoAcceptedInitialDomainName'"
		# $exoAcceptedDefaultDomainName = ($exoAcceptedDomains | Where-Object { $PSItem.Default }).DomainName
		# Write-Verbose "`$exoAcceptedDefaultDomainName: '$exoAcceptedDefaultDomainName'"
		# # Get default domain's first domain name component.
		# $tenantName = $exoAcceptedDefaultDomainName.Split( '.' )[0]
		# Write-Verbose "`$tenantName: '$tenantName'"
		# # https://learn.microsoft.com/en-us/exchange/exchange-hybrid#key-terminology coexistence domain
		# $exoAcceptedCoexistenceDomainName = If ( $exoAcceptedDomains.IsCoexistenceDomain -Contains $TRUE ) { 
				# ($exoAcceptedDomains | Where-Object { $PSItem.IsCoexistenceDomain }).DomainName 
			# } Else { 
				# "$tenantName.mail.onmicrosoft.com"
			# }
		# Write-Verbose "`$exoAcceptedCoexistenceDomainName: '$exoAcceptedCoexistenceDomainName'"
		
		# If ( -Not $CoexistenceDomain ) {
			# $CoexistenceDomain = $exoAcceptedCoexistenceDomainName
		# } 
		# Write-Verbose "`$CoexistenceDomain: '$CoexistenceDomain'"
		# #endregion Get Exchange Online Domain names
		
		
		
	}
	
	Process {		
		
		Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox | 
			ForEach-Object {
				$exoMailbox = $PSItem 
				Write-Host "$(Get-Date) $($PSItem.UserPrincipalName)"
				
				# Initialize metrics.  
				$status = ''
				
				# Get additional Exchange Online info.
				$errorMessage = 'Unhandled'
				Try {
					
					$exoMailboxStatistics = Get-MailboxStatistics -Identity $exoMailbox.Identity 
				
					If ( $WhatIf ) { $errorMessage = 'WhatIf' } Else { $errorMessage = 'Success' }	
				} Catch {
					$errorMessage = $PSItem.Exception.Message
					Write-Host $PSItem.Exception.Message -ForegroundColor Red -BackgroundColor Black
					Write-Host "ScriptLineNumber: '$($PSItem.InvocationInfo.ScriptLineNumber)'" -ForegroundColor Yellow -BackgroundColor Black
				}
				$status = "$(( ( $status, 'Get-MailboxStatistics:', $errorMessage ) -Join ' ' ).Trim( ' ' ))`n"
				
				# Get-Azure AD info.
				$errorMessage = 'Unhandled'
				Try {
					
					$azAdUser = Get-AzAdUser -UserPrincipalName $exoMailbox.UserPrincipalName -Select Department -Verbose:$FALSE -Debug:$FALSE -ErrorAction Stop
			
					If ( $WhatIf ) { $errorMessage = 'WhatIf' } Else { $errorMessage = 'Success' }	
				} Catch {
					$errorMessage = $PSItem.Exception.Message
					Write-Host $PSItem.Exception.Message -ForegroundColor $Host.PrivateData.ErrorForegroundColor -BackgroundColor $Host.PrivateData.ErrorBackgroundColor
					Write-Host "ScriptLineNumber: '$($PSItem.InvocationInfo.ScriptLineNumber)'" -ForegroundColor $Host.PrivateData.WarningForegroundColor -BackgroundColor $Host.PrivateData.WarningBackgroundColor
				}
				$status = "$(( ( $status, 'Get-AzAdUser:', $errorMessage ) -Join ' ' ).Trim( ' ' ))`n"
			
				Write-Output ( [PSCustomObject] @{
					UserPrincipalName = $exoMailbox.UserPrincipalName
					Alias = $exoMailbox.Alias
					PrimarySmtpAddress = $exoMailbox.PrimarySmtpAddress
					DisplayName = $exoMailbox.DisplayName
					Department = $azAdUser.Department
					#TotalItemSizeBQS = $exoMailboxStatistics.TotalItemSize
					TotalItemSizeMB = [Math]::Round( [Long] ( $exoMailboxStatistics.TotalItemSize -Replace $matchByteQuantifiedSize, '${ToBytes}' ) / 1MB, 2 ).ToString( 'N2' )
					ItemCount = $exoMailboxStatistics.ItemCount
					Status = $status
				} )
				
			} |
			Export-CSV -Path $outFilePathName -NoTypeInformation -Encoding UTF8 -WhatIf:$FALSE
	
	}
	
	End { 
		
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12
		#region Clean up.
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12

		Disconnect-M365Admin
		#endregion Clean up.

		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12
		#region Write report.
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12
		
		# If ( $report ) { 
			# $report |
				# Export-Csv -Path $outFilePathName -Append -NoTypeInformation -Encoding UTF8 -WhatIf:$FALSE
		# }
			
		# # If out file is empty, remove it.  
		# $outFileLength = If ( Test-Path -Path $outFilePathName -PathType Leaf ) { (Get-ChildItem -LiteralPath $outFilePathName).Length } Else { 0 }
		# Write-Debug "`$outFileLength:,$outFileLength"
		# If ( -Not ( 3 -LT $outFileLength ) ) { # Ignore first three characters in UTF-8 encoding formatted files "EF BB BF" or "C2EF C2BB C2BF".  
			# Remove-Item -Path $outFilePathName -Verbose:$FALSE -Debug:$FALSE -WhatIf:$FALSE
		# }

		#endregion Write report.

		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12
		#region Optionally mail report.
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12

		# If report file(s) have been written, and mandatory Send-MailMessage parameters are specified.
		If ( (Test-Path -Path $outFilePathName -PathType Leaf) -And $MailFrom -And $MailTo -And $MailServer ) {

			$messageSubject = "Get/Set M365 Admin Template $reportType for $($outFilePathBase.OrganizationName) on $((Get-Date).ToString('s'))"
			$reportHead = 'ExO Recipients'

			# Determine subject line report/alert mode.  
			If ( $AlertOnly ) {
				$reportType = 'Alert'
			} Else {
				$reportType = 'Report'
			}
			
			# Create a hash table to splat parameters.  
			$sendMailMessageParameters = @{}
			$sendMailMessageParameters.From = $MailFrom
			$sendMailMessageParameters.To = $MailTo
			$sendMailMessageParameters.SmtpServer = $MailServer
			$sendMailMessageParameters.Subject = $messageSubject
			
			# If the out file is larger than a specified limit (message size limit default is 10-150MB), then create a compressed (zipped) copy.  
			$outFileLength = (Get-ChildItem -LiteralPath $outFilePathName).Length
			Write-Host "`$outFileLength: '$outFileLength'"

			$outZipFilePathName = $NULL
			If ( $CompressAttachmentLargerThan -LT $outFileLength ) {
				
				$outZipFilePathName = "$($outFilePathBase.Value).zip"
				Write-Debug "`$outZipFilePathName: '$outZipFilePathName'"
				
				# Create a hash table to splat parameters. 
				$compressArchiveParameters = @{}
				# $compressArchiveParameters.CompressionLevel = 'Optimal' # Processing time is dependent on file size.  Default.  
				$compressArchiveParameters.LiteralPath = $outFilePathName
				$compressArchiveParameters.DestinationPath = $outZipFilePathName
				If ( $Debug ) {
					ForEach ( $key In $compressArchiveParameters.Keys ) {
						Write-Debug "`$compressArchiveParameters[$key]: '$($compressArchiveParameters[$key])'"
					}
				}
			
				# Compress the report attachment(s) into a single Zip file.  
				Compress-Archive @compressArchiveParameters
				
				# Attach the Zip file to the mail message.  
				$sendMailMessageParameters.Attachments = $outZipFilePathName
				
				$sendMailMessageParameters.Body = "See attached zipped Excel (CSV) spreadsheet(s)."
				
			} Else {
			
				# Attach the report file(s) to the mail message.  
				$sendMailMessageParameters.Attachments = @()
				If ( $report ) { 
					$sendMailMessageParameters.Attachments += $outFilePathName
				}
				
				# Include the report contents in the mail message body as HTML.
				$sendMailMessageParameters.BodyAsHtml = $TRUE
				
				$sendMailMessageParameters.Body = "See attached Excel (CSV) spreadsheet.`n"
				$sendMailMessageParameters.Body += "<br />`n<br />`n"
				
				If ( $report ) { 
					$sendMailMessageParameters.Body += $report.Keys |
						ForEach-Object {
							Write-Output $report[$PSItem]
						} | 
						Select-Object -Property RecordType,CreationDate,UserIds,Operations,Identity,LastLogonDaysSince |
						Sort-Object -Property CreationDate |
						ConvertTo-Html -Head $reportHead
						
					$sendMailMessageParameters.Body += "<br />`n"
				}
				
			} 
			
			If ( $Debug ) {
				ForEach ( $key In $sendMailMessageParameters.Keys ) {
					Write-Debug "`$sendMailMessageParameters[$key]: '$($sendMailMessageParameters[$key])'"
				}
			}

			# Send the report.  
			Send-MailMessage @sendMailMessageParameters

			# Remove the temporary zip file.  
			If ( $outZipFilePathName -And (Test-Path -LiteralPath $outZipFilePathName -PathType Leaf) ) {
				Remove-Item -LiteralPath $outZipFilePathName
			}
		
		}
		#endregion Optionally mail report.		

		# Optionally write script execution metrics.
		Write-Verbose "`$MyInvocation.MyCommand.Name End: '$($MyInvocation.MyCommand.Name)'"
		$scriptEndTime = Get-Date
		Write-Verbose "`t`$scriptEndTime: '$($scriptEndTime.ToString('s'))'" 
		$scriptElapsedTime =  $scriptEndTime - $scriptStartTime
		Write-Verbose "`t`$scriptElapsedTime: '$scriptElapsedTime'"
		
		# If started, stop the PowerShell transcript.
		If ( $Debug -Or $Verbose ) {
			Stop-Transcript
		}
		
	}
	
}
