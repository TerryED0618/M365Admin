<# Post Ctrl+C/abnormal termination clean up:
Disconnect-M365Admin
Stop-Transcript
#>


Function Get-M365AdminTest {
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
 
		.PARAMETER ExchPowerShellMaxConnectionTimePeriodMinutes 
			The number of minutes to stay connected to on-premises Exchange mailbox management admin server before refreshing (disconnect/connect).  The default is every 45 minutes.  

		.PARAMETER Tenant 
			Optional tenant name or ID.
			The Organization parameter specifies the organization that's used in CBA. Be sure to use an .onmicrosoft.com domain for the parameter value. Otherwise, you might encounter cryptic permission issues when you run commands in the app context.
			
		.PARAMETER AuthenticationUrl 
			SharePoint Online location for AAD Cross-Tenant Authentication service. Can be optionally used if non-default Cross-Tenant Authentication Service is used.

		.PARAMETER Url 
			Specifies the URL of the SharePoint Online Administration Center site.

		.PARAMETER NoDisconnect
			When specified the M365 services (workload) are not disconnected upon exiting of this script.  

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
			$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
			. .\Get-M365AdminTest.ps1; Get-M365AdminTest -AdminCredential $adminCredential -ConnectExchangeServer -ExchangeServerFqdn Exch01.domain.com 

		.EXAMPLE 
			. .\Get-M365AdminTest.ps1; Get-M365AdminTest -AdminCredentialUserName Admin@domain.com -AdminCredentialPasswordFilePath .\SecureCredentialPassword.txt -ConnectExchangeServer -ExchangeServerFqdn Exch01.domain.com 

		.EXAMPLE 
			$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
			. .\Get-M365AdminTest.ps1; Get-M365AdminTest -AdminCredential $adminCredential -ConnectAzAccount -ConnectExchangeOnline -ConnectExchangeServer -ExchangeServerFqdn Exch01.domain.com   

		.EXAMPLE 
			$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
			. .\Get-M365AdminTest.ps1; Get-M365AdminTest -AdminCredentialUserName $adminCredential.UserName -ConnectAzAccount -ConnectExchangeOnline -ConnectExchangeServer -ExchangeServerFqdn Exch01.domain.com -ConnectIPPSSession -ConnectMgGraph -ConnectMicrosoftTeams -ConnectSPOService

		.EXAMPLE 
			. .\Get-M365AdminTest.ps1; Get-M365AdminTest -AdminCredentialUserName Admin@domain.com -AdminCredentialPasswordFilePath .\SecureCredentialPassword.txt -ConnectAzAccount -ConnectExchangeServer -ConnectExchangeOnline -ConnectIPPSSession -ConnectMgGraph -ConnectMicrosoftTeams -ConnectSPOService

		.EXAMPLE 
			. .\Get-M365AdminTest.ps1; Get-M365AdminTest -AdminCredentialUserName Admin@domain.com -ConnectAzAccount -ConnectExchangeServer -ConnectExchangeOnline -ConnectIPPSSession -ConnectMgGraph

		.EXAMPLE 
			. .\Get-M365AdminTest.ps1; Get-M365AdminTest -Tenant domain.onmicrosoft.com -ApplicationId 36ee4c6c-0812-40a2-b820-b22ebd02bce3 -CertificateThumbprint 83213AEAC56D61C97AEE5C1528F4AC5EBA7321C1 -ConnectAzAccount -ConnectExchangeServer -ConnectExchangeOnline -ConnectIPPSSession -ConnectMgGraph

		.EXAMPLE 
			. .\Get-M365AdminTest.ps1; Get-M365AdminTest -Tenant 71c3c5b7-6481-4751-b3e9-06b574584e6b -ApplicationId 36ee4c6c-0812-40a2-b820-b22ebd02bce3 -CertificateThumbprint 83213AEAC56D61C97AEE5C1528F4AC5EBA7321C1 -ConnectAzAccount -ConnectExchangeServer -ConnectExchangeOnline -ConnectIPPSSession -ConnectMgGraph


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

		# Get/Set-M365AdminTemplate parameters:			

		
		# Common authentication parameters for Microsoft 365 services (workload):		
		
			[Parameter(
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet', Mandatory=$TRUE,
				ValueFromPipelineByPropertyName=$TRUE 
			)]
			[Alias( 'Credential' )]
		[System.Management.Automation.Credential()] $AdminCredential = [System.Management.Automation.PSCredential]::Empty,
				
			[Parameter( 
				ParameterSetName = 'UserBasicAuthWithoutCredentialParameterSet'
			)] 
			[Parameter( 
				ParameterSetName = 'UserModernAuthParameterSet', Mandatory=$TRUE
			)] 
		[String] $AdminCredentialUserName,  
		
			[Parameter( 
				ParameterSetName = 'UserBasicAuthWithoutCredentialParameterSet', Mandatory=$TRUE
			)] 
		[String] $AdminCredentialPasswordFilePath,
		
			[Parameter(
				ParameterSetName = 'AppCertificateBasedAuthParameterSet', Mandatory=$TRUE,
				ValueFromPipelineByPropertyName=$TRUE
			)]
			[Alias( 'ApplicationName' )]
		[String] $ApplicationId,

			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'AppCertificateBasedAuthParameterSet' 
			)]
		[String] $CertificateThumbPrint,

			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet' 
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithoutCredentialParameterSet' 
			)]			
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserModernAuthParameterSet' 
			)]
		[String[]] $Scopes,
		
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'AppCertificateBasedAuthParameterSet',
				HelpMessage = 'The Tenant parameter specifies the organization that''s used in CBA. Be sure to use an .onmicrosoft.com domain for the parameter value. Otherwise, you might encounter cryptic permission issues when you run commands in the app context.' 
			)]
			# [ValidateScript( { $PSItem -Eq $NULL -Or $PSItem -Like '*.onmicrosoft.com' -Or [guid]::TryParse( $PSItem, [ref][guid]::Empty ) } )]																															
			[Alias( 'Organization', 'TenantId', 'TenantInitialDomain' )]
		[String] $Tenant,
		

		# Microsoft 365 service (workload) connection parameters: 
		#	Set the following Connect* parameter values to $FALSE if not needed by this solution, and $TRUE if it is needed. 
												
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'AppCertificateBasedAuthParameterSet'
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet' 
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithoutCredentialParameterSet' 
			)]			
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserModernAuthParameterSet' 
			)]
		[Switch] $ConnectAzAccount = $FALSE,

			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'AppCertificateBasedAuthParameterSet'
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet' 
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithoutCredentialParameterSet' 
			)]			
		[Switch] $ConnectExchangeServer = $FALSE,

			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'AppCertificateBasedAuthParameterSet'
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet' 
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithoutCredentialParameterSet' 
			)]			
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserModernAuthParameterSet' 
			)]
		[Switch] $ConnectExchangeOnline = $FALSE,

			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'AppCertificateBasedAuthParameterSet'
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet' 
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithoutCredentialParameterSet' 
			)]			
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserModernAuthParameterSet' 
			)]
		[Switch] $ConnectIPPSSession = $FALSE,

			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'AppCertificateBasedAuthParameterSet'
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet' 
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithoutCredentialParameterSet' 
			)]			
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserModernAuthParameterSet' 
			)]
		[Switch] $ConnectMgGraph = $FALSE,
		
			# September 2022	4.7.1-preview	Releases Application-based authentication support in Connect-MicrosoftTeams in preview. The supported cmdlets are being gradually rolled out, more details in Application-based authentication in Teams PowerShell Module.
			# [Parameter(
				# ValueFromPipelineByPropertyName=$TRUE,
				# ParameterSetName = 'AppCertificateBasedAuthParameterSet'
			# )]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet' 
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithoutCredentialParameterSet' 
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserModernAuthParameterSet' 
			)]
		[Switch] $ConnectMicrosoftTeams = $FALSE,

			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet' 
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithoutCredentialParameterSet' 
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserModernAuthParameterSet' 
			)]			
		[Switch] $ConnectSPOService = $FALSE,

		# Common authentication parameters for Microsoft 365 services (workload):		
		
			[Parameter(
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet', Mandatory=$TRUE,
				ValueFromPipelineByPropertyName=$TRUE 
			)]
			[Alias( 'Credential' )]
		[System.Management.Automation.Credential()] $AdminCredential = [System.Management.Automation.PSCredential]::Empty,
				
			[Parameter( 
				ParameterSetName = 'UserBasicAuthWithoutCredentialParameterSet'
			)] 
			[Parameter( 
				ParameterSetName = 'UserModernAuthParameterSet', Mandatory=$TRUE
			)] 
		[String] $AdminCredentialUserName,  
		
			[Parameter( 
				ParameterSetName = 'UserBasicAuthWithoutCredentialParameterSet', Mandatory=$TRUE
			)] 
		[String] $AdminCredentialPasswordFilePath,
		
			[Parameter(
				ParameterSetName = 'AppCertificateBasedAuthParameterSet', Mandatory=$TRUE,
				ValueFromPipelineByPropertyName=$TRUE
			)]
			[Alias( 'ApplicationName' )]
		[String] $ApplicationId,

			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'AppCertificateBasedAuthParameterSet' 
			)]
		[String] $CertificateThumbPrint,

			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet' 
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserBasicAuthWithoutCredentialParameterSet' 
			)]			
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserModernAuthParameterSet' 
			)]
		[String[]] $Scopes,
		
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'AppCertificateBasedAuthParameterSet',
				HelpMessage = 'The Tenant parameter specifies the organization that''s used in CBA. Be sure to use an .onmicrosoft.com domain for the parameter value. Otherwise, you might encounter cryptic permission issues when you run commands in the app context.' 
			)]
			# [ValidateScript( { $PSItem -Eq $NULL -Or $PSItem -Like '*.onmicrosoft.com' -Or [guid]::TryParse( $PSItem, [ref][guid]::Empty ) } )]																															
			[Alias( 'Organization', 'TenantId', 'TenantInitialDomain' )]
		[String] $Tenant,
		
		# Connect-SPOService parameters:						  
		
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE
			)]
		[String] $Region, 

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

			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE
			)]
		[Int] $ExchPowerShellMaxConnectionTimePeriodMinutes = 45,
		
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
		[String] $OutFileNameTag
		
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
				Connect-M365Admin -ApplicationId $ApplicationId -CertificateThumbprint $CertificateThumbprint -Tenant $Tenant -ConnectAzAccount:$ConnectAzAccount -ConnectExchangeOnline:$ConnectExchangeOnline -ConnectExchangeServer:$ConnectExchangeServer -ExchangeServerFqdn $ExchangeServerFqdn -ConnectIPPSSession:$ConnectIPPSSession -ConnectMgGraph:$ConnectMgGraph -Verbose:$Verbose -Debug:$Debug -WhatIf:$FALSE # not supported with CBA: -ConnectMicrosoftTeams -ConnectSPOService 
			}
		
			{ $PSItem -In ( 'UserBasicAuthWithCredentialParameterSet', 'UserBasicAuthWithoutCredentialParameterSet' ) } {
				Connect-M365Admin -AdminCredential $AdminCredential -ConnectAzAccount:$ConnectAzAccount -ConnectExchangeOnline:$ConnectExchangeOnline -ConnectExchangeServer:$ConnectExchangeServer -ExchangeServerFqdn $ExchangeServerFqdn -ConnectIPPSSession:$ConnectIPPSSession -ConnectMgGraph:$ConnectMgGraph -ConnectMicrosoftTeams:$ConnectMicrosoftTeams -ConnectSPOService:$ConnectSPOService -Url $Url -Verbose:$Verbose -Debug:$Debug -WhatIf:$FALSE 
			}
			
			'UserModernAuthParameterSet' {
				Connect-M365Admin -AdminCredentialUserName $AdminCredentialUserName -ConnectAzAccount:$ConnectAzAccount -ConnectExchangeOnline:$ConnectExchangeOnline -ConnectIPPSSession:$ConnectIPPSSession -ConnectMgGraph:$ConnectMgGraph -ConnectMicrosoftTeams:$ConnectMicrosoftTeams -Verbose:$Verbose -Debug:$Debug -WhatIf:$FALSE  # Not supported with ModernAuth: -ConnectExchangeServer -ConnectSPOService
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
				Write-Debug "`$newOutFilePathBaseParameters[$key]: '$($newOutFilePathBaseParameters[$key])'"
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
	
	}
	
	Process {		
		
		If ( $ConnectAzAccount ) { 
			$tenantName = $NULL
			$azTenant = Get-AzTenant -ErrorAction Stop -Verbose:$FALSE -Debug:$FALSE
			# Get default domain's first domain name component.
			$tenantName = ( $azTenant.DefaultDomain.Split( '.') )[0] 
			If ( $tenantName ) { $tenantId = $azTenant.TenantId } Else { $tenantId = $NULL }
			Write-Host
			Write-Host "$(Get-Date) AzAccount:"
			Write-Host "$(Get-Date)`tTenant Name: '$tenantName'"
			Write-Host "$(Get-Date)`tTenant Id: '$tenantId'"
		}
		
		If ( $ConnectExchangeOnline ) {
			$tenantName = $NULL
			$exoAcceptedDomains = Get-AcceptedDomain -Verbose:$FALSE -Debug:$False
			#$exoAcceptedDomainNameCoexistence = If ( $exoAcceptedDomains.IsCoexistenceDomain -Contains $TRUE ) { ($exoAcceptedDomains | Where-Object { $PSItem.IsCoexistenceDomain }).DomainName.ToString() } Else { '' }
			$exoAcceptedDomainNameDefault = ($exoAcceptedDomains | Where-Object { $PSItem.Default }).DomainName
			#$exoAcceptedDomainNameInitial = ($exoAcceptedDomains | Where-Object { $PSItem.InitialDomain }).DomainName
			# Get default domain's first domain name component.
			$tenantName = ( $exoAcceptedDomainNameDefault.Split( '.' ) )[0] 
			Try {
				$tenantId = (Invoke-WebRequest -URI "https://login.windows.net/$tenantName.onmicrosoft.com/.well-known/openid-configuration" -ErrorAction Stop | ConvertFrom-Json).token_endpoint.Split('/')[3]
			} Catch {
				$tenantId = $NULL
			}
			Write-Host
			Write-Host "$(Get-Date) ExchangeOnline:"
			Write-Host "$(Get-Date)`tTenant Name: '$tenantName'"
			Write-Host "$(Get-Date)`tTenant Id: '$tenantId'"
		}
		
		If ( $ConnectExchangeServer ) {
			$tenantName = $NULL
			$exchAcceptedDomains = Get-ExchAcceptedDomain -Verbose:$FALSE -Debug:$False
			#$exchAcceptedDomainNameCoexistence = If ( $exchAcceptedDomains.IsCoexistenceDomain -Contains $TRUE ) { ($exchAcceptedDomains | Where-Object { $PSItem.IsCoexistenceDomain }).DomainName.ToString() } Else { '' }
			$exchAcceptedDomainNameDefault = ($exchAcceptedDomains | Where-Object { $PSItem.Default }).DomainName
			#$exchAcceptedDomainNameInitial = ($exchAcceptedDomains | Where-Object { $PSItem.InitialDomain }).DomainName
			# Get default domain's first domain name component.
			$tenantName = ( $exchAcceptedDomainNameDefault.Split( '.' ) )[0] 
			Try {
				# Perhaps the on-premises Exchange server default accepted domain name matches the M365 tenant name?  
				$tenantId = (Invoke-WebRequest -URI "https://login.windows.net/$tenantName.onmicrosoft.com/.well-known/openid-configuration" -ErrorAction Stop | ConvertFrom-Json).token_endpoint.Split('/')[3]
			} Catch {
				$tenantId = $NULL
			}
			Write-Host
			Write-Host "$(Get-Date) ExchangeServer:"
			Write-Host "$(Get-Date)`tTenant Name: '$tenantName'"
			Write-Host "$(Get-Date)`tTenant Id: '$tenantId' (maybe)"
		}
		
		If ( $ConnectIPPSSession ) { 
			$tenantName = $NULL
			# $ipAcceptedDomains = Get-AcceptedDomain -Verbose:$FALSE -Debug:$False
			# #$ipAcceptedDomainNameCoexistence = If ( $ipAcceptedDomains.IsCoexistenceDomain -Contains $TRUE ) { ($ipAcceptedDomains | Where-Object { $PSItem.IsCoexistenceDomain }).DomainName.ToString() } Else { '' }
			# $ipAcceptedDomainNameDefault = ($ipAcceptedDomains | Where-Object { $PSItem.Default }).DomainName
			# #$ipAcceptedDomainNameInitial = ($ipAcceptedDomains | Where-Object { $PSItem.InitialDomain }).DomainName
			# # Get default domain's first domain name component.
			# $tenantName = ( $ipAcceptedDomainNameDefault.Split( '.' ) )[0] 
			Try {
				$tenantId = (Invoke-WebRequest -URI "https://login.windows.net/$tenantName.onmicrosoft.com/.well-known/openid-configuration" -ErrorAction Stop | ConvertFrom-Json).token_endpoint.Split('/')[3]
			} Catch {
				$tenantId = $NULL
			}
			Write-Host
			Write-Host "$(Get-Date) IPPSSession:"
			Write-Host "$(Get-Date)`tTenant Name: '$tenantName'"
			Write-Host "$(Get-Date)`tTenant Id: '$tenantId'"
		}
		
		If ( $ConnectMgGraph ) {
			$tenantName = $NULL
			$mgOrgainization = Get-MgOrganization -ErrorAction Stop -Verbose:$FALSE -Debug:$FALSE
			$mgVerifiedDomainDefault = ( ($mgOrgainization).VerifiedDomains | Where-Object { $PSItem.IsDefault } ).Name
			#$mgVerifiedDomainInitial = ( ($mgOrgainization).VerifiedDomains | Where-Object { $PSItem.IsInitial } ).Name			
			# Get default domain's first domain name component.
			$tenantName = ( $mgVerifiedDomainDefault.Split( '.' ) )[0] 
			If ( $tenantName ) { $tenantId = $mgOrgainization.Id } Else { $tenantId = $NULL } 
			Write-Host
			Write-Host "$(Get-Date) MgGraph:"
			Write-Host "$(Get-Date)`tTenant Name: '$tenantName'"
			Write-Host "$(Get-Date)`tTenant Id: '$tenantId'"
		}
		
		If ( $ConnectMicrosoftTeams ) {
			$tenantName = $NULL
			$csTenant = Get-CsTenant -ErrorAction Stop | Out-Null
			#$csVerifiedDomainInitial = $csTenant.VerifiedDomains[0].Name # presume first verified domain is Initial.  
			$csVerifiedDomainDefault = If ( 1 -LT ($csTenant.VerifiedDomains).Count ) { $csTenant.VerifiedDomains[1].Name } # presume second verified domain is Default.  
			# Get default domain's first domain name component.
			$tenantName = ( $csVerifiedDomainDefault.Split( '.' ) )[0] 
			If ( $tenantName ) { $tenantId = $csTenant.TenantId } Else { $tenantId = $NULL } 
			Write-Host
			Write-Host "$(Get-Date) MicrosoftTeams:"
			Write-Host "$(Get-Date)`tTenant Name: '$tenantName'"
			Write-Host "$(Get-Date)`tTenant Id: '$tenantId'"
		}
		
		If ( $ConnectSPOService ) {
			$tenantName = $NULL
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
			Try {
				$tenantId = (Invoke-WebRequest -URI "https://login.windows.net/$tenantName.onmicrosoft.com/.well-known/openid-configuration" -ErrorAction Stop | ConvertFrom-Json).token_endpoint.Split('/')[3]
			} Catch {
				$tenantId = $NULL
			}
			Write-Host
			Write-Host "$(Get-Date) SPOService:"
			Write-Host "$(Get-Date)`tTenant Name: '$tenantName'"
			Write-Host "$(Get-Date)`tTenant Id: '$tenantId'"
		}

	}
	
	End { 
		
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12
		#region Clean up.
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12

		Disconnect-M365Admin -Verbose:$Verbose -Debug:$Debug -WhatIf:$FALSE
		
		#endregion Clean up.

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
