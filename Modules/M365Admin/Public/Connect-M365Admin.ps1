<# Execution Examples:

$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
Connect-M365Admin -AdminCredential $adminCredential -ConnectExchangeOnline 

$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
Connect-M365Admin -AdminCredential $adminCredential -ConnectExchangeServer 

$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
Connect-M365Admin -AdminCredential $adminCredential -ConnectExchangeOnline -ConnectExchangeServer 

Connect-M365Admin -AdminCredentialUserName Admin@domain.com -ConnectExchangeOnline 

Connect-M365Admin -AdminCredentialUserName Admin@domain.com -AdminCredentialPasswordFilePath '.\SecureCredentialPassword.txt' -ConnectExchangeServer 

Connect-M365Admin -AdminCredentialUserName Admin@domain.com -AdminCredentialPasswordFilePath '.\SecureCredentialPassword.txt' -ConnectExchangeOnline -ConnectExchangeServer

#>
<# Post Ctrl+C/abnormal termination clean up:

Disconnect-M365Admin
Stop-Transcript

#>


Function Connect-M365Admin {
	<#
	
		.SYNOPSIS
			Connects to M365 services (workload) and on-premises Exchange mailbox management server.

		.DESCRIPTION
			Connects to M365 services (workload):
				Azure ActiveDirectory PowerShell (Az.Resources module)
				Exchange Online PowerShell V3 (ExchangeOnlineManagement module)
				Security & Compliance PowerShell via Exchange Online PowerShell V3 (ExchangeOnlineManagement module)
				Exchange Server PowerShell (Exchange Management Shell)
				SharePoint Online Management Shell (Microsoft.Online.SharePoint.PowerShell module)
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

		.PARAMETER UseBasicAuth
			When specified use BasicAuth instead of the preferred ModernAuth for the following connection parameters:
				-ConnectAzAccount
				-ConnectExchangeOnline
				-ConnectIPPSSession

		.PARAMETER ConnectAzAccount 
			When specified connect to Azure Resource Management.   
			
			Microsoft services (workload) supported:
				Azure ActiveDirectory via Az.Resources module.
				All other Az.* modules and their supported resources and services (workload).
			
			Authentication protocol this solution supports for this service:
				Password based Basic Authentication (BasicAuth) is - not supported.
				Token based Modern Authentication (ModernAuth or OAuth 2.0) including support for multi-factor authentication (MFA) is - supported.
				Certificate-based application (CBA) authentication is - supported.

				
		.PARAMETER ConnectExchangeOnline 
			When specified connect to Exchange Online.  

			Microsoft services (workload) supported:
 				Exchange Online via ExchangeOnlineManagement module.
			
			Authentication protocol this solution supports for this service:
				Password based Basic Authentication (BasicAuth) is - not supported.
				Token based Modern Authentication (ModernAuth or OAuth 2.0) including support for multi-factor authentication (MFA) is - supported.
				Certificate-based application (CBA) authentication is - supported.

		.PARAMETER ConnectExchangeServer 
			When specified connect to on-premises Exchange mailbox management admin server using remote PowerShell session (WinRM).  

			Microsoft services (workload) accessed:
				Exchange on premises.
			
			Authentication protocol this solution supports for this service:
				Password based Basic Authentication (BasicAuth) is - supported.
				Token based Modern Authentication (ModernAuth or OAuth 2.0) including support for multi-factor authentication (MFA) is - not supported.
				Certificate-based application (CBA) authentication is - supported.

		.PARAMETER ConnectIPPSSession 
			When specified connect to Information Protection using the ExchangeOnlineManagement module.  
		
			Microsoft services (workload) supported:
				Security and Compliance via ExchangeOnlineManagement module.
			
			Authentication protocol this solution supports for this service:
				Password based Basic Authentication (BasicAuth) is - not supported.
				Token based Modern Authentication (ModernAuth or OAuth 2.0) including support for multi-factor authentication (MFA) is - supported.
				Certificate-based application (CBA) authentication is - supported.
		
		.PARAMETER ConnectMicrosoftTeams 
			When specified connect to Microsoft Teams.  

			Microsoft services (workload) accessed:
				Microsoft Teams via MicrosoftTeams module.  
			
			Authentication protocol this solution supports for this service:
				Password based Basic Authentication (BasicAuth) is - supported.
				Token based Modern Authentication (ModernAuth or OAuth 2.0) including support for multi-factor authentication (MFA) is - not supported.
				Certificate-based application (CBA) authentication is - not supported.
			
		.PARAMETER ConnectMgGraph 
			When specified connect to Microsoft Graph using the Microsoft.Graph PowerShell SDK module.  
			The PowerShell SDK supports two types of access: delegated user, and app-only access.  
			MgGraph does not elevate a delegated users beyond what it has already been granted by other means such as being added to a directory role, a role-based access control (RBAC) group, or granted rights to inpersonate.  

			Microsoft services (workload) supported:
				Audit and Reporting via Microsoft.Graph.Reports module.
				Azure ActiveDirectory via Microsoft.Graph.DirectoryObjects, Microsoft.Graph.Groups, Microsoft.Graph.Identity.DirectoryManagement, Microsoft.Graph.Users modules.
				Information Protection via Microsoft.Graph.Identity.SignIns module.
				Intune via Microsoft.Graph.DeviceManagement.*, Microsoft.Graph.Devices.CorporateManagement modules.  
				Licensing via Microsoft.Graph.Identity.DirectoryManagement module.
				Microsoft Teams via Microsoft.Graph.Teams module.
				Security and Compliance via Microsoft.Graph.Security module.
				Service Health via Microsoft.Graph.Devices.ServiceAnnouncement module.  
				SharePoint Online via Microsoft.Graph.Files, Microsoft.Graph.Sites modules.  
				All other Microsoft.Graph.* modules and their supported resources and services (workload).
			
			Authentication protocol this solution supports for this service:
				Password based Basic Authentication (BasicAuth) is - not supported.
				Token based Modern Authentication (ModernAuth or OAuth 2.0) including support for multi-factor authentication (MFA) is - supported.
				Certificate-based application (CBA) authentication is - supported.
		
		.PARAMETER ConnectSPOService 
			When specified connect to SharePoint Online.  

			Microsoft services (workload) accessed:
				SharePoint Online Management Shell via Microsoft.Online.SharePoint.PowerShell module.  
			
			Authentication protocol this solution supports for this service:
				Password based Basic Authentication (BasicAuth) is - supported.
				Token based Modern Authentication (ModernAuth or OAuth 2.0) including support for multi-factor authentication (MFA) is - not supported.
				Certificate-based application (CBA) authentication is - not supported.

		.PARAMETER ExchangeServerFqdn 
			One or more on-premises Exchange mailbox management admin server fully qualified domain name. If not specified a list of server FQDNs will be collected from on-premises Active Directory and one will be randomly selected.  
 
		.PARAMETER ExchPowerShellMaxConnectionTimePeriodMinutes 
			The number of minutes to stay connected to on-premises Exchange mailbox management admin server before refreshing (disconnect/connect).  The default is every 45 minutes.  

		.PARAMETER Tenant 
			Optional tenant name or ID.
			The Organization parameter specifies the organization that's used in CBA. Be sure to use an .onmicrosoft.com domain for the parameter value. Otherwise, you might encounter cryptic permission issues when you run commands in the app context.
			
		.PARAMETER AuthenticationUrl 
			SharePoint Online location for AAD Cross-Tenant Authentication service. Can be optionally used if non-default Cross-Tenant Authentication Service is used.

		.PARAMETER Region
			The valid values are: Default | ITAR | Germany | China
			The default value is "default".
			Note: The ITAR value is for GCC High and DoD tenancies only.

		.PARAMETER Url 
			Specifies the URL of the SharePoint Online Administration Center site.  For example https://consoto-admin.sharepoint.com/

		.EXAMPLE 
			Connect-M365 -Tenant domain.onmicrosoft.com -ApplicationId 36ee4c6c-0812-40a2-b820-b22ebd02bce3 -CertificateThumbprint 83213AEAC56D61C97AEE5C1528F4AC5EBA7321C1 -ConnectAzAccount
			
			Connect to Azure Active Directory with a registered Azure AD application and a certificate thumbprint using Certificate-Based Authentication.
			A certificate with the private key is stored in this workstation's certificate store location of either CurrentUser or LocalMachine.  A corresponding certificate with the public key is registered with the Azure AD application.  

		.EXAMPLE 
			Connect-M365 -Tenant domain.onmicrosoft.com -ApplicationId 36ee4c6c-0812-40a2-b820-b22ebd02bce3 -CertificateThumbprint 83213AEAC56D61C97AEE5C1528F4AC5EBA7321C1 -ConnectExchangeOnline

			Connect to Exchange Online with a registered Azure AD application and a certificate thumbprint using Certificate-Based Authentication.
			A certificate with the private key is stored in this workstation's certificate store location of either CurrentUser or LocalMachine.  A corresponding certificate with the public key is registered with the Azure AD application.  
			
		.EXAMPLE 
			Connect-M365 -Tenant domain.onmicrosoft.com -ApplicationId 36ee4c6c-0812-40a2-b820-b22ebd02bce3 -CertificateThumbprint 83213AEAC56D61C97AEE5C1528F4AC5EBA7321C1 -ConnectIPPSSession

			Connect to Security and Compliance Center with a registered Azure application and a certificate thumbprint using Certificate-Based Authentication.
			A certificate with the private key is stored in this workstation's certificate store location of either CurrentUser or LocalMachine.  A corresponding certificate with the public key is registered with the Azure AD application.  

		.EXAMPLE 
			Connect-M365 -Tenant domain.onmicrosoft.com -ApplicationId 36ee4c6c-0812-40a2-b820-b22ebd02bce3 -CertificateThumbprint 83213AEAC56D61C97AEE5C1528F4AC5EBA7321C1 -ConnectMgGraph

			Connect to Microsoft Graph with a registered Azure AD application and a certificate thumbprint using Certificate-Based Authentication.
			A certificate with the private key is stored in this workstation's certificate store location of either CurrentUser or LocalMachine.  A corresponding certificate with the public key is registered with the Azure AD application.  

		.EXAMPLE 
			Connect-M365 -Tenant domain.onmicrosoft.com -ApplicationId 36ee4c6c-0812-40a2-b820-b22ebd02bce3 -CertificateThumbprint 83213AEAC56D61C97AEE5C1528F4AC5EBA7321C1 -ConnectAzAccount -ConnectExchangeOnline -ConnectIPPSSession -ConnectMgGraph

			Connect to all M365 services (workload) that support certificate-based authentication.
			A certificate with the private key is stored in this workstation's certificate store location of either CurrentUser or LocalMachine.  A corresponding certificate with the public key is registered with the Azure AD application.  


		.EXAMPLE 
			$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
			Connect-M365 -AdminCredential $adminCredential -ConnectAzAccount 

			Connect to Azure Active Directory with password containing administrator credential using BasicAuth to ModernAuth.
			The password is ignored and a multi-factor authentication (MFA) prompt is expected when the current access token is expired.  

		.EXAMPLE 
			Connect-M365 -AdminCredentialUserName Admin@domain.com -AdminCredentialPasswordFilePath .\SecureCredentialPassword.txt -ConnectAzAccount 

			Connect to Azure Active Directory with administrator user name and a secure string password file using BasicAuth to ModernAuth.
			The password is ignored and a multi-factor authentication (MFA) prompt is expected when the current access token is expired.  

		.EXAMPLE 
			$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
			Connect-M365 -AdminCredential $adminCredential -ConnectExchangeOnline

			Connect to Exchange Online with password containing administrator credential using BasicAuth to ModernAuth.
			The password is ignored and a multi-factor authentication (MFA) prompt is expected when the current access token is expired.  

		.EXAMPLE 
			Connect-M365 -AdminCredentialUserName Admin@domain.com -AdminCredentialPasswordFilePath .\SecureCredentialPassword.txt -ConnectExchangeOnline

			Connect to Exchange Online with administrator user name and a secure string password file using BasicAuth to ModernAuth.
			The password is ignored and a multi-factor authentication (MFA) prompt is expected when the current access token is expired.  

		.EXAMPLE 
			$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
			Connect-M365 -AdminCredential $adminCredential -ConnectExchangeServer 

			Connect to a random on-premises Exchange mailbox management admin server with password containing administrator credential using BasicAuth.

		.EXAMPLE 
			Connect-M365 -AdminCredentialUserName Admin@domain.com -AdminCredentialPasswordFilePath .\SecureCredentialPassword.txt -ConnectExchangeServer 

			Connect to a random on-premises Exchange mailbox management admin server with administrator user name and a secure string password file using BasicAuth.

		.EXAMPLE 
			$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
			Connect-M365 -AdminCredential $adminCredential -ConnectExchangeServer -ExchangeServerFqdn Exch01.domain.com 

			Connect to a specified on-premises Exchange mailbox management admin server Exch01.domain.com with password containing administrator credential using BasicAuth.

		.EXAMPLE 
			Connect-M365 -AdminCredentialUserName Admin@domain.com -AdminCredentialPasswordFilePath .\SecureCredentialPassword.txt -ConnectExchangeServer -ExchangeServerFqdn Exch01.domain.com 

			Connect to a specified on-premises Exchange mailbox management admin server Exch01.domain.com with administrator user name and a secure string password file using BasicAuth.

		.EXAMPLE 
			$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
			Connect-M365 -AdminCredential $adminCredential -ConnectIPPSSession

			Connect to Security and Compliance Center with password containing administrator credential using BasicAuth to ModernAuth.
			The password is ignored and a multi-factor authentication (MFA) prompt is expected when the current access token is expired.  

		.EXAMPLE 
			Connect-M365 -AdminCredentialUserName Admin@domain.com -AdminCredentialPasswordFilePath .\SecureCredentialPassword.txt -ConnectIPPSSession

			Connect to Security and Compliance Center with administrator user name and a secure string password file using BasicAuth to ModernAuth.
			The password is ignored and a multi-factor authentication (MFA) prompt is expected when the current access token is expired.  
		
		.EXAMPLE 
			$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
			Connect-M365 -AdminCredential $adminCredential -ConnectMicrosoftTeams

			Connect to MicrosoftTeams with password containing administrator credential using BasicAuth.

		.EXAMPLE 
			$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
			Connect-M365 -AdminCredentialUserName Admin@domain.com -AdminCredentialPasswordFilePath .\SecureCredentialPassword.txt -ConnectMicrosoftTeams

			Connect to MicrosoftTeams with administrator user name and a secure string password file using BasicAuth.

		.EXAMPLE 
			$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
			Connect-M365 -AdminCredential $adminCredential -ConnectMgGraph

			Connect to Microsoft Graph with password containing administrator credential using BasicAuth to ModernAuth.
			The password is ignored and a multi-factor authentication (MFA) prompt is expected when the current access token is expired.  

		.EXAMPLE 
			Connect-M365 -AdminCredentialUserName Admin@domain.com -AdminCredentialPasswordFilePath .\SecureCredentialPassword.txt -ConnectMgGraph

			Connect to Microsoft Graph with administrator user name and a secure string password file using BasicAuth to ModernAuth.
			The password is ignored and a multi-factor authentication (MFA) prompt is expected when the current access token is expired.  	
		
		.EXAMPLE 
			$adminCredential = Get-Credential -UserName Admin@domain.com -Message 'Enter your admin credentials.'
			Connect-M365 -AdminCredential $adminCredential -ConnectSPOService -Url 'https://domain-admin.sharepoint.com'

			Connect to SharePoint Online Administration Center with password containing administrator credential using BasicAuth.

		.EXAMPLE 
			Connect-M365 -AdminCredentialUserName Admin@domain.com -AdminCredentialPasswordFilePath .\SecureCredentialPassword.txt -ConnectSPOService -Url 'https://domain-admin.sharepoint.com'

			Connect to SharePoint Online Administration Center with administrator user name and a secure string password file using BasicAuth.

		.EXAMPLE 
			Connect-M365 -AdminCredentialUserName Admin@domain.com -AdminCredentialPasswordFilePath .\SecureCredentialPassword.txt -ConnectAzAccount -ConnectExchangeOnline -ConnectExchangeServer -ExchangeServerFqdn Exch01.domain.com -ConnectIPPSSession -ConnectMicrosoftTeams -ConnectMgGraph -ConnectSPOService -Url 'https://domain-admin.sharepoint.com'

			Connect to all M365 services (workload) that support BasicAuth or BasicAuth to ModernAuth.

		.EXAMPLE 
			Connect-M365 -AdminCredentialUserName Admin@domain.com -ConnectAzAccount 

			Connect to Azure Active Directory with administrator user name using ModernAuth.
			A multi-factor authentication (MFA) prompt is expected when the current access token is expired.  

		.EXAMPLE 
			Connect-M365 -AdminCredentialUserName Admin@domain.com -ConnectExchangeOnline

			Connect to Exchange Online with administrator user name using ModernAuth.
			A multi-factor authentication (MFA) prompt is expected when the current access token is expired.  

		.EXAMPLE 
			Connect-M365 -AdminCredentialUserName Admin@domain.com -ConnectIPPSSession

			Connect to Security and Compliance Center with with administrator user name using ModernAuth.
			A multi-factor authentication (MFA) prompt is expected when the current access token is expired.  
		
		.EXAMPLE 
			Connect-M365 -AdminCredentialUserName Admin@domain.com -ConnectMgGraph -Scope user.read

			Connect to Microsoft Graph with administrator user name using ModernAuth.
			A multi-factor authentication (MFA) prompt is expected when the current access token is expired.  

		.EXAMPLE 
			Connect-M365 -AdminCredentialUserName Admin@domain.com -ConnectAzAccount -ConnectExchangeOnline -ConnectIPPSSession -ConnectMgGraph -Scope user.read

			Connect to all M365 services (workload) that support ModernAuth.
			A multi-factor authentication (MFA) prompt is expected when the current access token is expired.  


		.NOTES
			2022-08-01 Terry E Dow - Initial version
			2023-02-20 Terry E Dow - Added feedback (Write-Host) with -ConnectExchangeServer when authentication for Kerberos fails.  
			2023-02-20 Terry E Dow - Added -UseBasicAuth to prefer BasicAuth over ModernAuth for -ConnectAzAccount, -ConnectExchangeOnline, and -ConnectIPPSSession only with parameter set UserBasicAuthWithCredentialParameterSet.
			2023-02-20 Terry E Dow - Added check for SecurityProtocolType TLS to disable obsolete SSL3, TLS [1.0], and TLS 1.1 and enable TLS 1.2.  Review when newer protocols are made available from Microsoft.  
			2023-02-20 Terry E Dow - Rearranged parameter order so the credential parameters (-AdminCredentials, et al) appear before -Connect... parameters.  
			2023-02-28 Terry E Dow - Minor documentation changes.  Removed ExchPowerShellMaxConnectionTimePeriodMinutes parameter.
			2023-03-02 Terry E Dow - Corrected ParameterSet settings regarding -AdminCredential, -AdminCredentialUserName, -AdminCredentialPasswordFilePath.  
			
		.LINK
			Exchange Online PowerShell https://docs.microsoft.com/en-us/powershell/exchange/exchange-online-powershell
			Exchange Server PowerShell (Exchange Management Shell) https://docs.microsoft.com/en-us/powershell/exchange/exchange-management-shell
			Intro to SharePoint Online Management Shell https://docs.microsoft.com/en-us/powershell/sharepoint/sharepoint-online/introduction-sharepoint-online-management-shell
			Introducing the Azure Az PowerShell module https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az
			Microsoft Graph PowerShell overview https://docs.microsoft.com/en-us/powershell/microsoftgraph/overview
			Microsoft Teams PowerShell Overview https://docs.microsoft.com/en-us/microsoftteams/teams-powershell-overview
			Security & Compliance PowerShell https://docs.microsoft.com/en-us/powershell/exchange/scc-powershell
			Deep Dive: How Hybrid Authentication Really Works https://techcommunity.microsoft.com/t5/exchange-team-blog/deep-dive-how-hybrid-authentication-really-works/ba-p/606780
			The Confused State of Microsoft 365 PowerShell https://practical365.com/microsoft-365-powershell-confusion/
	#>
	[CmdletBinding(
		SupportsShouldProcess = $TRUE, # Enable support for -WhatIf by invoked destructive cmdlets.
		DefaultParameterSetName = 'UserModernAuthParameterSet' 
	)]
	Param (

		# Common authentication parameters for Microsoft 365 services (workloads):		
		
			[Parameter(
				ParameterSetName = 'UserBasicAuthWithCredentialParameterSet', 
				Mandatory=$TRUE,
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
		
		# Microsoft 365 service (workload) connection parameters: 
		#	Set the following Connect* parameter values to $FALSE if not needed by this solution, and $TRUE if it is needed. 
		#	Also update the #Requires section in the Begin script block as instructed below.
												
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
				ParameterSetName = 'UserBasicAuthWithUserNamePasswordFileParameterSet' 
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
				ParameterSetName = 'UserBasicAuthWithUserNamePasswordFileParameterSet' 
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
				ParameterSetName = 'UserBasicAuthWithUserNamePasswordFileParameterSet' 
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
				ParameterSetName = 'UserBasicAuthWithUserNamePasswordFileParameterSet' 
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
				ParameterSetName = 'UserBasicAuthWithUserNamePasswordFileParameterSet' 
			)]			
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserModernAuthParameterSet' 
			)]
		[Switch] $ConnectMgGraph = $FALSE,
		
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
				ParameterSetName = 'UserBasicAuthWithUserNamePasswordFileParameterSet' 
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
				ParameterSetName = 'UserBasicAuthWithUserNamePasswordFileParameterSet' 
			)]
			[Parameter(
				ValueFromPipelineByPropertyName=$TRUE,
				ParameterSetName = 'UserModernAuthParameterSet' 
			)]			
		[Switch] $ConnectSPOService = $FALSE,

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
		[String[]] $ExchangeServerFqdn 
		
	)
	
	Begin {
		
		#Set-StrictMode -Version Latest

		# The following Requires are not required.  Documenting latest external module version this function has been tested with.  
		#
		# #Requires -Modules @{ ModuleName='ActiveDirectory'; ModuleVersion='1.0' } https://learn.microsoft.com/en-us/powershell/module/activedirectory/
		# #Requires -Modules @{ ModuleName='Az.Accounts'; ModuleVersion='2.10' } # 2.10.1 (Connect-AzAccount) https://learn.microsoft.com/en-us/powershell/azure/release-notes-azureps https://learn.microsoft.com/en-us/powershell/module/az.accounts/
		# #Requires -Modules @{ ModuleName='Az.Resources'; ModuleVersion='6.2' } # 6.2.0 (Connect-AzAccount) https://learn.microsoft.com/en-us/powershell/module/az.resources/
		# #Requires -Modules @{ ModuleName='ExchangeOnlineManagement'; ModuleVersion='3.0' } # 3.0.0 (Connect-ExchangeOnline or Connect-IPPSSession) https://learn.microsoft.com/en-us/powershell/exchange/exchange-online-powershell https://learn.microsoft.com/en-us/powershell/exchange/scc-powershell
		# #Requires -Modules @{ ModuleName='tmp_*.*'; ModuleVersion='1.0' } # 1.0 (Import-PSSession) https://learn.microsoft.com/en-us/powershell/exchange/exchange-management-shell
		# #Requires -Modules @{ ModuleName='Microsoft.Graph.Authentication'; ModuleVersion='1.12' } # 1.12.2 (Connect-MgGraph) https://learn.microsoft.com/en-us/powershell/microsoftgraph/authentication-commands
		# #Requires -Modules @{ ModuleName='Microsoft.Graph.Identity.DirectoryManagement'; ModuleVersion='1.12' } # 1.12.2 (Connect-MgGraph) https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.directorymanagement/
		# #Requires -Modules @{ ModuleName='MicrosoftTeams'; ModuleVersion='4.7' } # 4.7.0 (Connect-MicrosoftTeams) https://learn.microsoft.com/en-us/microsoftteams/teams-powershell-release-notes
		# #Requires -Modules @{ ModuleName='Microsoft.Online.SharePoint.PowerShell'; ModuleVersion='16.0' } # 16.0.22921.12000 (Connect-SPOService) https://learn.microsoft.com/en-us/powershell/module/sharepoint-online/
		
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

		# Is Security support provider interface (SSPI) SecurityProtocolType TLS 1.2 defined?
		If ( [Net.SecurityProtocolType].GetEnumNames() -Contains 'Tls12' ) {
			# Is TLS 1.2, and are obsolete SecurityProtocols SSL3, TLS [1.0], and TLS 1.1 disabled? 
			$servicePointManagerSecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol  -Split ', '
			If ( $servicePointManagerSecurityProtocol -NotContains 'Tls12' -Or  $servicePointManagerSecurityProtocol -Contains 'Ssl3' -Or $servicePointManagerSecurityProtocol -Contains 'Tls' -Or $servicePointManagerSecurityProtocol -Contains 'Tls11' ) {
				Write-Host "$(Get-Date) ServicePointManager's SecurityProtocol(s) enabled was: $($servicePointManagerSecurityProtocol -Join ', ')" 
				Try {
					[Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -BOr [Net.SecurityProtocolType]::Tls12 -BAnd ( -BNot ( [Net.SecurityProtocolType]::Ssl3 -BOr [Net.SecurityProtocolType]::Tls -BOr [Net.SecurityProtocolType]::Tls11 ) )
				} Catch {
					[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
				}
				# If TLS 1.3 is available, include it.  
				If ( [Net.SecurityProtocolType].GetEnumNames() -Contains 'Tls13' ) {
					[Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -BOr [Net.SecurityProtocolType]::Tls13
				}
				Write-Host "$(Get-Date) ServicePointManager's SecurityProtocol(s) enabled is: " -NoNewline
				[Net.ServicePointManager]::SecurityProtocol
			}
		}
		
		# Initialize metrics at this script scope.
		$wasAzAccountConnected = $NULL
		$wasExchangeServerConnected = $NULL
		$wasExchangeOnlineConnected = $NULL
		$wasIPConnected = $NULL
		$wasMicrosoftTeamsConnected = $NULL
		$wasMgGraphConnected = $NULL
		$wasSPOServiceConnected = $NULL
		
		# Respond to parameterset being used.  
		Write-Debug "`$PsCmdlet.ParameterSetName: '$($PsCmdlet.ParameterSetName)'"
		Switch ( $PsCmdlet.ParameterSetName ) {
			
			'AppCertificateBasedAuthParameterSet' {
				
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to Azure Az PowerShell (Az.Accounts Module) as an application.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				
				If ( $ConnectAzAccount ) {		
					
					# Check if currently connected.
					$isAzAccountConnected = $NULL
					Try {

						$isAzAccountConnected = [Bool] (Get-AzContext -ErrorAction Stop)

					} Catch {
						$isAzAccountConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'Az.Accounts' is not installed."
					}
					Write-Debug "`$isAzAccountConnected: '$isAzAccountConnected'"
					
					# If not connected then connect.
					If ( -Not $isAzAccountConnected ) {
						
						# Create a hash table to splat parameters.  
						$connectAzAccountParameters = @{}
						$connectAzAccountParameters.ApplicationId = $ApplicationId
						$connectAzAccountParameters.CertificateThumbprint = $CertificateThumbprint
						$connectAzAccountParameters.Debug = $FALSE
						$connectAzAccountParameters.ErrorAction = 'Stop'
						$connectAzAccountParameters.ServicePrincipal = $TRUE
						$connectAzAccountParameters.Tenant = $Tenant
						$connectAzAccountParameters.Verbose = $FALSE
						$connectAzAccountParameters.WhatIf = $FALSE
						If ( $Debug ) {
							ForEach ( $key In $connectAzAccountParameters.Keys ) {
								Write-Debug "`$connectAzAccountParameters[$key]: '$($connectAzAccountParameters[$key])'"
							}
						}
						
						Write-Host "$(Get-Date) Connecting to AzAccount as an application."
						$psAzureProfile = Connect-AzAccount @connectAzAccountParameters
						
						#$tenantName = ((Get-AzDomain -ErrorAction Stop -Verbose:$FALSE -Debug:$FALSE).DefaultDomain.Split('.'))[0]
						
					}
											
				}

				#endregion Connect to Azure Az PowerShell (Az.Accounts Module) as an application.
				
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to Exchange Online PowerShell V3 (ExchangeOnlineManagement module) as an application.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				
				If ( $ConnectExchangeOnline ) {
					
					# Check if currently connected.
					$isExchangeOnlineConnected = $NULL
					Try {

						$isExchangeOnlineConnected = ( [Bool] (Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.ComputerName -Eq 'outlook.office365.com' } ) -Or [Bool] (Get-ConnectionInformation -ErrorAction Stop) ) # -And $PSItem.State -Eq 'Opened'

					} Catch {
						$isExchangeOnlineConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'ExchangeOnlineManagement' is not installed."
					}
					Write-Debug "`$isExchangeOnlineConnected: '$isExchangeOnlineConnected'"
					
					# If not connected then connect.
					If ( -Not $isExchangeOnlineConnected ) {
					
						# Create a hash table to splat parameters.  
						$connectExchangeOnlineParameters = @{}
						#$connectExchangeOnlineParameters.CommandName = @( 'Get-AcceptedDomain', 'Get-ExoRecipient' ) # Minimal list of module functions this solution requires.  
						$connectExchangeOnlineParameters.AppId = $ApplicationId
						$connectExchangeOnlineParameters.CertificateThumbprint = $CertificateThumbprint
						$connectExchangeOnlineParameters.Debug = $FALSE
						$connectExchangeOnlineParameters.ErrorAction = 'Stop'
						$connectExchangeOnlineParameters.Organization = $Tenant # You must use an .onmicrosoft.com domain for the value of this parameter.
						$connectExchangeOnlineParameters.ShowBanner = $FALSE
						$connectExchangeOnlineParameters.Verbose = $FALSE	
						If ( $Debug ) {
							ForEach ( $key In $connectExchangeOnlineParameters.Keys ) {
								Write-Debug "`$connectExchangeOnlineParameters[$key]: '$($connectExchangeOnlineParameters[$key])'"
							}
						}
						
						Write-Host "$(Get-Date) Connecting to ExchangeOnline as an application."
						Connect-ExchangeOnline @connectExchangeOnlineParameters
						
						# $exoSession = Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.State -Eq 'Opened' -And $PSItem.ComputerName -Eq 'outlook.office365.com' }
						# Write-Debug "`$exoSession.TokenExpiryTime: '$($exoSession.TokenExpiryTime)'"
						
					}
						
				}
				
				#endregion Connect to Exchange Online PowerShell V3 module as an application.

				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to Security & Compliance PowerShell via Exchange Online PowerShell V3 (ExchangeOnlineManagement module) as an application.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				
				If ( $ConnectIPPSSession ) {
					
					# Check if currently connected.
					$isIPConnected = $NULL
					Try {
						
						$isIPConnected = ( [Bool] (Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.State -Eq 'Opened' -And $PSItem.ComputerName -Eq '*.ps.compliance.protection.outlook.com' } ) )
						
					} Catch {
						$isIPConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'ExchangeOnlineManagement' is not installed."
					}
					Write-Debug "`$isIPConnected: '$isIPConnected'"
					
					# If not connected then connect.
					If ( -Not $isIPConnected ) {
						
						# Create a hash table to splat parameters.  
						$connectExchangeOnlineParameters = @{}
						#$connectExchangeOnlineParameters.CommandName = @( 'Get-AcceptedDomain', 'Get-ExoRecipient' ) # Minimal list of module functions this solution requires.  
						$connectExchangeOnlineParameters.AppId = $ApplicationId
						$connectExchangeOnlineParameters.CertificateThumbprint = $CertificateThumbprint
						$connectExchangeOnlineParameters.Debug = $FALSE
						$connectExchangeOnlineParameters.ErrorAction = 'Stop'
						$connectExchangeOnlineParameters.Organization = $Tenant
						$connectExchangeOnlineParameters.ShowBanner = $FALSE
						$connectExchangeOnlineParameters.Verbose = $FALSE	
						If ( $Debug ) {
							ForEach ( $key In $connectExchangeOnlineParameters.Keys ) {
								Write-Debug "`$connectExchangeOnlineParameters[$key]: '$($connectExchangeOnlineParameters[$key])'"
							}
						}
						
						Write-Host "$(Get-Date) Connecting to IPPSSession as an application."
						Connect-IPSession @connectExchangeOnlineParameters
						
						$ipSession = Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.State -Eq 'Opened' -And $PSItem.ComputerName -Eq '*.ps.compliance.protection.outlook.com' }
						Write-Debug "`$exoSession.TokenExpiryTime: '$($exoSession.TokenExpiryTime)'"
						
						If ( $Debug ) {
							(Get-Command -Module $ipSession.CurrentModuleName).Name
						}

					}

				}

				#endregion Connect to Security & Compliance PowerShell via Exchange Online PowerShell V3 module as an application.
								
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to on-premises Exchange Server PowerShell (Exchange Management Shell) as an application.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				
				If ( $ConnectExchangeServer ) {
					
					# Check if currently connected.
					$isExchangeServerConnected = $NULL
					Try {

						$isExchangeServerConnected = [Bool] (Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And ( $PSItem.Name -Like 'ExchangeSession*' -Or $PSItem.Name -Like 'Session*' ) -And $PSItem.State -Eq 'Opened' })
					
					} Catch {
						$isExchangeServerConnected = $FALSE
					}
					Write-Debug "`$isExchangeServerConnected: '$isExchangeServerConnected'"

					# If not connected then connect.
					If ( -Not $isExchangeServerConnected ) {
						
						# If no Exchange mailbox management admin server is provided, query Active Directory Configuration container, then prompt user to select one or more to connect to.  
						If ( -Not $ExchangeServerFqdn ) {
							$currentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
							$rootDomainDN = $currentForest.RootDomain.GetDirectoryEntry().DistinguishedName
							$msExchConfigurationContainerSearcher = New-Object DirectoryServices.DirectorySearcher
							$msExchConfigurationContainerSearcher.SearchRoot = "LDAP://CN=Microsoft Exchange,CN=Services,CN=Configuration,$rootDomainDN"
							$msExchConfigurationContainerSearcher.Filter = '(&(objectCategory=msExchExchangeServer)(msExchMailboxManagerAdminMode=*))'
							$msExchConfigurationContainerResult = $msExchConfigurationContainerSearcher.FindAll()
							$ExchangeServerFqdn = $msExchConfigurationContainerResult | ForEach-Object{ (Resolve-DnsName -Name ($PSItem.Properties.cn)).Name }
							Write-Verbose "$(Get-Date) Available on-premises Exchange mailbox management admin servers: '$ExchangeServerFqdn'"
							# $ExchangeServerFqdn = $msExchMailboxManagerAdmin | Out-GridView -PassThru -Title 'Select one or more Exchange mailbox management admin server to randomly connect to, then select the OK button.'
						}
						# If ( -Not $ExchangeServerFqdn ) {
							# Throw( 'Select at least one Exchange mailbox management admin server before selecting the OK button.' )
						# }
						$ExchangeServerFqdn = $ExchangeServerFqdn | Get-Random
						Write-Host "$(Get-Date) Connecting to on-premises Exchange mailbox management admin server"
						
						#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

						# Create a hash table to splat parameters.  
						$newExchPSSessionParameters = @{}
						$newExchPSSessionParameters.AllowRedirection = $TRUE
						$newExchPSSessionParameters.ApplicationName = $ApplicationId
						$newExchPSSessionParameters.Authentication = 'Kerberos'
						$newExchPSSessionParameters.CertificateThumbprint = $CertificateThumbprint
						$newExchPSSessionParameters.ConfigurationName = 'Microsoft.Exchange'
						$newExchPSSessionParameters.ConnectionUri = "http://$ExchangeServerFqdn/PowerShell"
						$newExchPSSessionParameters.Debug = $FALSE
						$newExchPSSessionParameters.ErrorAction = 'Stop'
						$newExchPSSessionParameters.Verbose = $FALSE
						If ( $Debug ) {
							ForEach ( $key In $newExchPSSessionParameters.Keys ) {
								Write-Debug "`$newExchPSSessionParameters[$key]: '$($newExchPSSessionParameters[$key])'"
							}
						}

						# Create Exchange PSSession to with Kerberos authentication...
						$exchSession = $NULL
						Try { 
						
							$exchSession = New-PSSession @newExchPSSessionParameters
						
						} Catch {
							# ...If that fails, try Basic authentication.  
							$newExchPSSessionParameters.Authentication = 'Basic'
							Write-Debug "`$newExchPSSessionParameters[Authentication]: '$($newExchPSSessionParameters['Authentication'])'"
						
							$exchSession = New-PSSession @newExchPSSessionParameters
						}

						#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
						
						Write-Host "$(Get-Date)`t'$ExchangeServerFqdn' as an application using 'Exch' as a command prefix."
						
						# Create a hash table to splat parameters.  
						$importExchPSSessionParameters = @{}
						$importExchPSSessionParameters.AllowClobber = $TRUE
						$importExchPSSessionParameters.Debug = $FALSE
						$importExchPSSessionParameters.DisableNameChecking = $TRUE
						$importExchPSSessionParameters.ErrorAction = 'Stop'
						$importExchPSSessionParameters.Prefix = 'Exch'
						$importExchPSSessionParameters.Session = $exchSession
						$importExchPSSessionParameters.Verbose = $FALSE # $VerbosePreference 'Continue' is unexpectedly overriding -Verbose:$FALSE with Import-PSSSession [3.1.0.0]
						If ( $Debug ) {
							ForEach ( $key In $importExchPSSessionParameters.Keys ) {
								Write-Debug "`$importExchPSSessionParameters[$key]: '$($importExchPSSessionParameters[$key])'"
							}
						}

						# Make a backup of current VerbosePreference, and change it to SilentlyContinue (unless in Debug mode).  
						$verbosePreferenceRestore = $VerbosePreference 
						If ( -Not $Debug ) { $VerbosePreference = 'SilentlyContinue' } 
						
						# Import session module.  
						$exchModuleInfo = Import-PSSession @importExchPSSessionParameters
						# If ( $Debug ) { $exchModuleInfo.ExportedFunctions.Keys | Where-Object { $PSItem -Like 'Get-*' } }
						If ( $Debug ) { 
							Write-Debug "$(Get-Date) `$exchModuleInfo.ExportedFunctions.Keys.Count: '$($exchModuleInfo.ExportedFunctions.Keys.Count)'"
						}
						
						# Restore VerbosePreference to its prior value. 
						If ( -Not $Debug ) { $VerbosePreference = $verbosePreferenceRestore }

						# If this function definition is in-line or dot-sourced, the scope of the Exchange Server imported module is local, we are done here.  
					#}
				#}
				
						#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
						
						# If however this function definition is from within a PowerShell module, re-import the Exchange Server module using Import-Module -Global so that it persists outside of the module's scope.  
						
						# Create a hash table to splat parameters.  
						$importExchModuleParameters = @{}
						$importExchModuleParameters.Debug = $FALSE
						$importExchModuleParameters.DisableNameChecking = $TRUE
						$importExchModuleParameters.Global = $TRUE
						$importExchModuleParameters.ErrorAction = 'Stop'
						$importExchModuleParameters.ModuleInfo = $exchModuleInfo
						$importExchModuleParameters.Prefix = $importExchPSSessionParameters.Prefix
						$importExchModuleParameters.PassThru = $TRUE
						$importExchModuleParameters.Verbose = $FALSE
						If ( $Debug ) {
							ForEach ( $key In $importExchPSSessionParameters.Keys ) {
								Write-Debug "`$importExchPSSessionParameters[$key]: '$($importExchPSSessionParameters[$key])'"
							}
						}

						$exchModuleInfoGlobal = Import-Module @importExchModuleParameters
						# If ( $Debug ) { $exchModuleInfoGlobal.ExportedFunctions.Keys | Where-Object { $PSItem -Like 'Get-*' } }
						If ( $Debug ) { 
							Write-Debug "$(Get-Date) `$exchModuleInfoGlobal.ExportedFunctions.Keys.Count: '$($exchModuleInfoGlobal.ExportedFunctions.Keys.Count)'"
						}

						#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
						
						# Assert ViewEntireForest to TRUE.  
						If ( -Not (Get-ExchADServerSettings -ErrorAction $silentlyContinueUnlessDebug ).ViewEntireForest ) { Set-ExchADServerSettings -ViewEntireForest:$TRUE -ErrorAction $silentlyContinueUnlessDebug }

					}
				}

				#endregion Connect to on-premises Exchange Server PowerShell (Exchange Management Shell) as an application.

				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to SharePoint Online Administration Center Management Shell (Microsoft.Online.SharePoint.PowerShell Module) as application, not supported.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

				If ( $ConnectSpoService ) {
					Throw 'Connecting as an application is not supported with SharePoint Online Management Shell using module Microsoft.Online.SharePoint.PowerShell.'
				}

				#endregion Connect to SharePoint Online Management Shell (Microsoft.Online.SharePoint.PowerShell, not supported.

				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to Microsoft Teams (MicrosoftTeams Module) as application.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

				If ( $ConnectMicrosoftTeams ) {
										
					# Check if currently connected.
					$isMicrosoftTeamsConnected = $NULL
					Try {
						
						Get-CsTenant -ErrorAction Stop | Out-Null
						
						$isMicrosoftTeamsConnected = $TRUE
					} Catch {
						$isMicrosoftTeamsConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'MicrosoftTeams' is not installed."
					}
					Write-Debug "`$isMicrosoftTeamsConnected: '$isMicrosoftTeamsConnected'"
					
					# If not connected then connect.
					If ( -Not $isMicrosoftTeamsConnected ) {
						
						# Create a hash table to splat parameters.  
						$connectMicrosoftTeamsParameters = @{}
						$connectExchangeOnlineParameters.ApplicationId = $ApplicationId
						$connectMicrosoftTeamsParameters.CertificateThumbprint = $CertificateThumbprint
						$connectMicrosoftTeamsParameters.Debug = $FALSE
						$connectMicrosoftTeamsParameters.ErrorAction = 'Stop'
						$connectMicrosoftTeamsParameters.TenantId = $Tenant
						$connectMicrosoftTeamsParameters.Verbose = $FALSE
						$connectMicrosoftTeamsParameters.WhatIf = $FALSE
						If ( $Debug ) {
							ForEach ( $key In $connectMicrosoftTeamsParameters.Keys ) {
								Write-Debug "`$connectMicrosoftTeamsParameters[$key]: '$($connectMicrosoftTeamsParameters[$key])'"
							}
						}
						
						Write-Host "$(Get-Date) Connecting to Microsoft Teams as user with ModernAuth."
						$pSAzureContext = Connect-MicrosoftTeams @connectMicrosoftTeamsParameters
						
					}
	
				}

				#endregion Connect to Microsoft Teams (MicrosoftTeams Module) as application, not supported.

				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to PowerShell SDK for Microsoft Graph (Microsoft.Graph Module) as an application.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				
				If ( $ConnectMgGraph ) {

					# Check if currently connected.
					$isMgGraphConnected = $NULL
					Try {
						
						$isMgGraphConnected = [Bool] (Get-MgContext)
						
					} Catch {
						$isMgGraphConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'Microsoft.Graph.Authentication' is not installed."
					}
					Write-Debug "`$isMgGraphConnected: '$isMgGraphConnected'"

					# If not connected then connect.
					If ( -Not $isMgGraphConnected ) {
						
						# Create a hash table to splat parameters.  
						$connectMgGraphParameters = @{}
						$connectMgGraphParameters.CertificateThumbprint = $CertificateThumbprint
						$connectMgGraphParameters.ClientId = $ApplicationId
						$connectMgGraphParameters.Debug = $FALSE
						$connectMgGraphParameters.ErrorAction = 'Stop'
						$connectMgGraphParameters.TenantId = $Tenant
						$connectMgGraphParameters.Verbose = $FALSE
						If ( $Debug ) {
							ForEach ( $key In $connectMgGraphParameters.Keys ) {
								Write-Debug "`$connectMgGraphParameters[$key]: '$($connectMgGraphParameters[$key])'"
							}
						}
						
						Write-Host "$(Get-Date) Connecting to MgGraph as an application."
						$psMgGraphContext = Connect-MgGraph @connectMgGraphParameters
						
						#$tenantName = ( (Get-AzureADDomain -ErrorAction Stop -Verbose:$FALSE -Debug:$FALSE | Where-Object { $PSItem.IsDefault }).Name.Split( '.') )[0] 
						
					}
					
				}
				
				#endregion Connect to PowerShell SDK for Microsoft Graph (Microsoft.Graph Module) as an application.

			}
		
			{ $PSItem -In ( 'UserBasicAuthWithCredentialParameterSet', 'UserBasicAuthWithUserNamePasswordFileParameterSet' ) } {
				
				# If $CredentialUserName is a period (.) then get current user account's userPrincipalName (UPN).
				If ( $AdminCredentialUserName -EQ '.' ) { $AdminCredentialUserName = ( [AdsiSearcher] "(&(ObjectCategory=Person)(sAMAccountName=$Env:USERNAME))" ).FindOne().Properties['userprincipalname'] }
				
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Support PSCredential securely in batch mode.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				
				#If ( $PsCmdlet.ParameterSetName -Eq 'UserBasicAuthWithUserNamePasswordFileParameterSet' ) {
				If ( $AdminCredentialPasswordFilePath ) {
					
					# Read and convert encoded text into an in-memory secure string.
					Write-Host "$(Get-Date) Reading secure string file '$AdminCredentialPasswordFilePath'."
					$adminCredentialPassword = Get-Content -Path $AdminCredentialPasswordFilePath -ErrorAction Stop | ConvertTo-SecureString
					$AdminCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $AdminCredentialUserName, $adminCredentialPassword
					# Write a secure (encrypted) string file. SecureString is encoded with default Data Protection API (DPAPI) with a DataProtectionScope of CurrentUser and LocalMachine security tokens.
					# Read-Host -AsSecureString "Securely enter password" | ConvertFrom-SecureString | Out-File -FilePath '.\SecureCredentialPassword.txt'
					
				}
				#endregion Support PSCredential securely in batch mode.
				
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to Azure Az PowerShell (Az.Accounts Module) as user with BasicAuth to ModernAuth.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

				If ( $ConnectAzAccount ) {
					
					# Check if currently connected.
					$isAzAccountConnected = $NULL
					Try {

						$isAzAccountConnected = [Bool] (Get-AzContext -ErrorAction Stop)

					} Catch {
						$isAzAccountConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'Az.Accounts' is not installed."
					}
					Write-Debug "`$isAzAccountConnected: '$isAzAccountConnected'"
					
					# If not connected then connect.
					If ( -Not $isAzAccountConnected ) {
						
						# Create a hash table to splat parameters.  
						$connectAzAccountParameters = @{}
						If ( -Not $UseBasicAuth ) { 
							$connectAzAccountParameters.AccountId = $AdminCredential.UserName
						} Else {
							$connectAzAccountParameters.Credential = $AdminCredential
						}
						$connectAzAccountParameters.Debug = $FALSE
						$connectAzAccountParameters.ErrorAction = 'Stop'
						$connectAzAccountParameters.Verbose = $FALSE
						$connectAzAccountParameters.WhatIf = $FALSE
						If ( $Debug ) {
							ForEach ( $key In $connectAzAccountParameters.Keys ) {
								Write-Debug "`$connectAzAccountParameters[$key]: '$($connectAzAccountParameters[$key])'"
							}
						}
						
						If ( -Not $UseBasicAuth ) { 
							Write-Host "$(Get-Date) Connecting to AzAccount as user with BasicAuth to ModernAuth."
						} Else {
							Write-Host "$(Get-Date) Connecting to AzAccount as user with BasicAuth."
						}
						$psAzureProfile = Connect-AzAccount @connectAzAccountParameters
						
						#$tenantName = ((Get-AzDomain -ErrorAction Stop -Verbose:$FALSE -Debug:$FALSE).DefaultDomain.Split('.'))[0]
						
					}
						
				}

				#endregion Connect to Azure Az PowerShell (Az.Accounts Module) as user with BasicAuth.
				
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to Exchange Online PowerShell V3 (ExchangeOnlineManagement module) as user with BasicAuth to ModernAuth.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				
				If ( $ConnectExchangeOnline ) {
							
					# Check if currently connected.
					$isExchangeOnlineConnected = $NULL
					Try {

						$isExchangeOnlineConnected = ( [Bool] (Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.ComputerName -Eq 'outlook.office365.com' } ) -Or [Bool] (Get-ConnectionInformation -ErrorAction Stop) ) # -And $PSItem.State -Eq 'Opened'

					} Catch {
						$isExchangeOnlineConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'ExchangeOnlineManagement' is not installed."
					}
					Write-Debug "`$isExchangeOnlineConnected: '$isExchangeOnlineConnected'"
				
					# If not connected then connect.
					If ( -Not $isExchangeOnlineConnected ) {
					
						# Create a hash table to splat parameters.  
						$connectExchangeOnlineParameters = @{}
						#$connectExchangeOnlineParameters.CommandName = @( 'Get-AcceptedDomain', 'Get-ExoRecipient' ) # Minimal list of module functions this solution requires.  
						If ( -Not $UseBasicAuth ) { 
							$connectExchangeOnlineParameters.UserPrincipalName = $AdminCredential.UserName
						} Else {
							$connectExchangeOnlineParameters.Credential = $AdminCredential
						}
						$connectExchangeOnlineParameters.Debug = $FALSE
						$connectExchangeOnlineParameters.ErrorAction = 'Stop'
						$connectExchangeOnlineParameters.ShowBanner = $FALSE
						$connectExchangeOnlineParameters.Verbose = $FALSE	
						If ( $Debug ) {
							ForEach ( $key In $connectExchangeOnlineParameters.Keys ) {
								Write-Debug "`$connectExchangeOnlineParameters[$key]: '$($connectExchangeOnlineParameters[$key])'"
							}
						}
						
						If ( -Not $UseBasicAuth ) { 
							Write-Host "$(Get-Date) Connecting to ExchangeOnline as user with BasicAuth to ModernAuth."
						} Else {
							Write-Host "$(Get-Date) Connecting to ExchangeOnline as user with BasicAuth."
						}
						Connect-ExchangeOnline @connectExchangeOnlineParameters
						
						# $exoSession = Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.State -Eq 'Opened' -And $PSItem.ComputerName -Eq 'outlook.office365.com' }
						# Write-Debug "`$exoSession.TokenExpiryTime: '$($exoSession.TokenExpiryTime)'"
						
					}
					
				}
				
				#endregion Connect to Exchange Online PowerShell V3 module as user with BasicAuth.

				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to Security & Compliance PowerShell via Exchange Online PowerShell V3 (ExchangeOnlineManagement module) as user with BasicAuth to ModernAuth.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				
				If ( $ConnectIPPSSession ) {
					
					# Check if currently connected.
					$isIPConnected = $NULL
					Try {
						
						$isIPConnected = ( [Bool] (Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.State -Eq 'Opened' -And $PSItem.ComputerName -Eq '*.ps.compliance.protection.outlook.com' } ) )
						
					} Catch {
						$isIPConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'ExchangeOnlineManagement' is not installed."
					}
					Write-Debug "`$isIPConnected: '$isIPConnected'"
					
					# If not connected then connect.
					If ( -Not $isIPConnected ) {
						
							# Create a hash table to splat parameters.  
							$connectIPPSSessionParameters = @{}
							#$connectIPPSSessionParameters.CommandName = @( 'Get-AcceptedDomain', 'Get-ExoRecipient' ) # Minimal list of module functions this solution requires.  
							If ( -Not $UseBasicAuth ) { 
								$connectIPPSSessionParameters.UserPrincipalName = $AdminCredential.UserName
							} Else {
								$connectIPPSSessionParameters.Credential = $AdminCredential
							}
							$connectIPPSSessionParameters.Debug = $FALSE
							$connectIPPSSessionParameters.ErrorAction = 'Stop'
							$connectIPPSSessionParameters.Verbose = $FALSE	
							If ( $Debug ) {
								ForEach ( $key In $connectIPPSSessionParameters.Keys ) {
									Write-Debug "`$connectIPPSSessionParameters[$key]: '$($connectIPPSSessionParameters[$key])'"
								}
							}
							
							If ( -Not $UseBasicAuth ) { 
								Write-Host "$(Get-Date) Connecting to IPPSSession as user with BasicAuth to ModernAuth."
							} Else {
								Write-Host "$(Get-Date) Connecting to IPPSSession as user with BasicAuth."
							}
							Connect-IPPSSession @connectIPPSSessionParameters
							
							$ipSession = Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.State -Eq 'Opened' -And $PSItem.ComputerName -Like '*.ps.compliance.protection.outlook.com' }
							Write-Debug "`$ipSession.TokenExpiryTime: '$($ipSession.TokenExpiryTime)'"
							
							If ( $Debug ) {
								(Get-Command -Module $ipSession.CurrentModuleName).Name
							}
						}

				}

				#endregion Connect to Security & Compliance PowerShell via Exchange Online PowerShell V3 module as user with BasicAuth.
				
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to on-premises Exchange Server PowerShell (Exchange Management Shell) as user with BasicAuth.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

				If ( $ConnectExchangeServer ) {
					
					# Check if currently connected.
					$isExchangeServerConnected = $NULL
					Try {

						$isExchangeServerConnected = [Bool] (Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And ( $PSItem.Name -Like 'ExchangeSession*' -Or $PSItem.Name -Like 'Session*' ) -And $PSItem.State -Eq 'Opened' })
					
					} Catch {
						$isExchangeServerConnected = $FALSE
					}
					Write-Debug "`$isExchangeServerConnected: '$isExchangeServerConnected'"

					# If not connected then connect.
					If ( -Not $isExchangeServerConnected ) {
						
						# If no Exchange mailbox management admin server is provided, query Active Directory Configuration container, then prompt user to select one or more to connect to.  
						If ( -Not $ExchangeServerFqdn ) {
							$currentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
							$rootDomainDN = $currentForest.RootDomain.GetDirectoryEntry().DistinguishedName
							$msExchConfigurationContainerSearcher = New-Object DirectoryServices.DirectorySearcher
							$msExchConfigurationContainerSearcher.SearchRoot = "LDAP://CN=Microsoft Exchange,CN=Services,CN=Configuration,$rootDomainDN"
							$msExchConfigurationContainerSearcher.Filter = '(&(objectCategory=msExchExchangeServer)(msExchMailboxManagerAdminMode=*))'
							$msExchConfigurationContainerResult = $msExchConfigurationContainerSearcher.FindAll()
							$ExchangeServerFqdn = $msExchConfigurationContainerResult | ForEach-Object{ (Resolve-DnsName -Name ($PSItem.Properties.cn)).Name }
							Write-Verbose "$(Get-Date) Available on-premises Exchange mailbox management admin servers: '$ExchangeServerFqdn'"
							# $ExchangeServerFqdn = $msExchMailboxManagerAdmin | Out-GridView -PassThru -Title 'Select one or more Exchange mailbox management admin server to randomly connect to, then select the OK button.'
						}
						# If ( -Not $ExchangeServerFqdn ) {
							# Throw( 'Select at least one Exchange mailbox management admin server before selecting the OK button.' )
						# }
						$ExchangeServerFqdn = $ExchangeServerFqdn | Get-Random
						Write-Host "$(Get-Date) Connecting to on-premises Exchange mailbox management admin server"
						Write-Host "$(Get-Date)`t'$ExchangeServerFqdn' as user with BasicAuth using 'Exch' as a command prefix."

						#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

						# Create a hash table to splat parameters.  
						$newExchPSSessionParameters = @{}
						$newExchPSSessionParameters.AllowRedirection = $TRUE
						$newExchPSSessionParameters.Authentication = 'Kerberos'
						$newExchPSSessionParameters.ConfigurationName = 'Microsoft.Exchange'
						$newExchPSSessionParameters.ConnectionUri = "http://$ExchangeServerFqdn/PowerShell"
						$newExchPSSessionParameters.Credential = $AdminCredential
						$newExchPSSessionParameters.Debug = $FALSE
						$newExchPSSessionParameters.ErrorAction = 'Stop'
						$newExchPSSessionParameters.Verbose = $FALSE # $VerbosePreference is overriding -Verbose:$FALSE with Import-PSSSession [3.1.0.0].
						If ( $Debug ) {
							ForEach ( $key In $newExchPSSessionParameters.Keys ) {
								Write-Debug "`$newExchPSSessionParameters[$key]: '$($newExchPSSessionParameters[$key])'"
							}
						}

						# Create Exchange PSSession to with Kerberos authentication...
						$exchSession = $NULL
						Try { 
						
							$exchSession = New-PSSession @newExchPSSessionParameters
						
						} Catch {
							$errorMessage = $PSItem.Exception.Message
							Write-Host $PSItem.Exception.Message -ForegroundColor $Host.PrivateData.ErrorForegroundColor -BackgroundColor $Host.PrivateData.ErrorBackgroundColor
							#Write-Host "ScriptLineNumber: $($PSItem.InvocationInfo.ScriptLineNumber)" -ForegroundColor $Host.PrivateData.WarningForegroundColor -BackgroundColor $Host.PrivateData.WarningBackgroundColor
							Write-Host 'Authentication with Kerberos failed, reattempting connection with Basic authentication.'
							
							# ...If that fails, try Basic authentication.  
							$newExchPSSessionParameters.Authentication = 'Basic'
							Write-Debug "`$newExchPSSessionParameters[Authentication]: '$($newExchPSSessionParameters['Authentication'])'"
						
							$exchSession = New-PSSession @newExchPSSessionParameters
						}

						#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

						# Create a hash table to splat parameters.  
						$importExchPSSessionParameters = @{}
						$importExchPSSessionParameters.AllowClobber = $TRUE
						$importExchPSSessionParameters.Debug = $FALSE
						$importExchPSSessionParameters.DisableNameChecking = $TRUE
						$importExchPSSessionParameters.ErrorAction = 'Stop'
						$importExchPSSessionParameters.Prefix = 'Exch'
						$importExchPSSessionParameters.Session = $exchSession
						$importExchPSSessionParameters.Verbose = $FALSE # $VerbosePreference 'Continue' is unexpectedly overriding -Verbose:$FALSE with Import-PSSSession [3.1.0.0]
						If ( $Debug ) {
							ForEach ( $key In $importExchPSSessionParameters.Keys ) {
								Write-Debug "`$importExchPSSessionParameters[$key]: '$($importExchPSSessionParameters[$key])'"
							}
						}

						# Make a backup of current VerbosePreference, and change it to SilentlyContinue (unless in Debug mode).  
						$verbosePreferenceRestore = $VerbosePreference 
						If ( -Not $Debug ) { $VerbosePreference = 'SilentlyContinue' } 
						
						# Import session module.  
						$exchModuleInfo = Import-PSSession @importExchPSSessionParameters
						# If ( $Debug ) { $exchModuleInfo.ExportedFunctions.Keys | Where-Object { $PSItem -Like 'Get-*' } }
						If ( $Debug ) { 
							Write-Debug "$(Get-Date) `$exchModuleInfo.ExportedFunctions.Keys.Count: '$($exchModuleInfo.ExportedFunctions.Keys.Count)'"
						}
						
						# Restore VerbosePreference to its prior value. 
						If ( -Not $Debug ) { $VerbosePreference = $verbosePreferenceRestore }

						# If this function definition is in-line or dot-sourced, the scope of the Exchange Server imported module is local, we are done here.  
					#}
				#}
				
						#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
						
						# If however this function definition is from within a PowerShell module, re-import the Exchange Server module using Import-Module -Global so that it persists outside of the module's scope.  
						
						# Create a hash table to splat parameters.  
						$importExchModuleParameters = @{}
						$importExchModuleParameters.Debug = $FALSE
						$importExchModuleParameters.DisableNameChecking = $TRUE
						$importExchModuleParameters.Global = $TRUE
						$importExchModuleParameters.ErrorAction = 'Stop'
						$importExchModuleParameters.ModuleInfo = $exchModuleInfo
						$importExchModuleParameters.Prefix = $importExchPSSessionParameters.Prefix
						$importExchModuleParameters.PassThru = $TRUE
						$importExchModuleParameters.Verbose = $FALSE
						If ( $Debug ) {
							ForEach ( $key In $importExchModuleParameters.Keys ) {
								Write-Debug "`$importExchModuleParameters[$key]: '$($importExchModuleParameters[$key])'"
							}
						}

						$exchModuleInfoGlobal = Import-Module @importExchModuleParameters
						# If ( $Debug ) { $exchModuleInfoGlobal.ExportedFunctions.Keys | Where-Object { $PSItem -Like 'Get-*' } }
						If ( $Debug ) { 
							Write-Debug "$(Get-Date) `$exchModuleInfoGlobal.ExportedFunctions.Keys.Count: '$($exchModuleInfoGlobal.ExportedFunctions.Keys.Count)'"
						}
						
						#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
						
						# Assert ViewEntireForest to TRUE.  
						If ( -Not (Get-ExchADServerSettings -ErrorAction $silentlyContinueUnlessDebug ).ViewEntireForest ) { Set-ExchADServerSettings -ViewEntireForest:$TRUE -ErrorAction $silentlyContinueUnlessDebug }

					}
				}

				#endregion Connect to on-premises Exchange Server PowerShell (Exchange Management Shell) as user with BasicAuth.

				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to SharePoint Online Administration Center Management Shell (Microsoft.Online.SharePoint.PowerShell Module) as user with BasicAuth.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

				If ( $ConnectSpoService ) {
					
					# Check if currently connected.
					$isSpoServiceConnected = $NULL
					Try {
						
						Get-SPOTenant -ErrorAction Stop | Out-Null
						
						$isSpoServiceConnected = $TRUE
					} Catch {
						$isSpoServiceConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'Microsoft.Online.SharePoint.PowerShell' is not installed."
					}
					Write-Debug "`$isSpoServiceConnected: '$isSpoServiceConnected'"
					
					# If not connected then connect.	
					If ( -Not $isSpoServiceConnected ) {
						
						# Create a hash table to splat parameters.  
						$connectSpoServiceParameters = @{}
						$connectSpoServiceParameters.Credential = $AdminCredential
						If ( $Region ) { $connectSpoServiceParameters.Region = $Region }
						$connectSpoServiceParameters.Debug = $FALSE
						$connectSpoServiceParameters.ErrorAction = 'Stop'
						$connectSpoServiceParameters.Verbose = $FALSE
						If ( $Url) { 
							$connectSpoServiceParameters.Url = $Url
						} Else {
							$connectSpoServiceParameters.Url = "https://$tenantName-admin.sharepoint.com"
						}
						If ( $Debug ) {
							ForEach ( $key In $connectSpoServiceParameters.Keys ) {
								Write-Debug "`$connectSpoServiceParameters[$key]: '$($connectSpoServiceParameters[$key])'"
							}
						}
						
						Write-Host "$(Get-Date) Connecting to SharePoint Online Management Shell service as user with BasicAuth."
						Connect-SpoService @connectSpoServiceParameters
						
					}

				}

				#endregion Connect to SharePoint Online Management Shell (Microsoft.Online.SharePoint.PowerShell Module) as user with BasicAuth.

				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to Microsoft Teams (MicrosoftTeams Module) as user with BasicAuth.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

				If ( $ConnectMicrosoftTeams ) {
						
					# Check if currently connected.
					$isMicrosoftTeamsConnected = $NULL
					Try {
						
						Get-CsTenant -ErrorAction Stop | Out-Null
						
						$isMicrosoftTeamsConnected = $TRUE
					} Catch {
						$isMicrosoftTeamsConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'MicrosoftTeams' is not installed."
					}
					Write-Debug "`$isMicrosoftTeamsConnected: '$isMicrosoftTeamsConnected'"
						
					# If not connected then connect.
					If ( -Not $isMicrosoftTeamsConnected ) {
						
						# Create a hash table to splat parameters.  
						$connectMicrosoftTeamsParameters = @{}
						$connectMicrosoftTeamsParameters.Credential = $AdminCredential
						$connectMicrosoftTeamsParameters.Debug = $FALSE
						$connectMicrosoftTeamsParameters.ErrorAction = 'Stop'
						$connectMicrosoftTeamsParameters.Verbose = $FALSE
						$connectMicrosoftTeamsParameters.WhatIf = $FALSE
						If ( $Debug ) {
							ForEach ( $key In $connectMicrosoftTeamsParameters.Keys ) {
								Write-Debug "`$connectMicrosoftTeamsParameters[$key]: '$($connectMicrosoftTeamsParameters[$key])'"
							}
						}
						
						Write-Host "$(Get-Date) Connecting to Microsoft Teams as user with BasicAuth."
						$pSAzureContext = Connect-MicrosoftTeams @connectMicrosoftTeamsParameters
						
					}
					
				}

				#endregion Connect to Microsoft Teams (MicrosoftTeams Module) as user with BasicAuth.	
				
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to PowerShell SDK for Microsoft Graph (Microsoft.Graph Module) as CurrentUser with BasicAuth to ModernAuth.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				
				If ( $ConnectMgGraph ) {
					
					# Check if currently connected.
					$isMgGraphConnected = $NULL
					Try {
						
						$isMgGraphConnected = [Bool] (Get-MgContext)
						
					} Catch {
						$isMgGraphConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'Microsoft.Graph.Authentication' is not installed."
					}
					Write-Debug "`$isMgGraphConnected: '$isMgGraphConnected'"
					
					# If not connected then connect.
					If ( -Not $isMgGraphConnected ) {
							
						# Create a hash table to splat parameters.  
						$connectMgGraphParameters = @{}
						$connectMgGraphParameters.Debug = $FALSE
						$connectMgGraphParameters.ErrorAction = 'Stop'
						$connectMgGraphParameters.Scopes = $Scopes
						$connectMgGraphParameters.Verbose = $FALSE
						If ( $Debug ) {
							ForEach ( $key In $connectMgGraphParameters.Keys ) {
								Write-Debug "`$connectMgGraphParameters[$key]: '$($connectMgGraphParameters[$key])'"
							}
						}
						
						Write-Host "$(Get-Date) Connecting to MgGraph as user with BasicAuth to ModernAuth."
						$psMgGraphContext = Connect-MgGraph @connectMgGraphParameters
						
						#$tenantName = ( ((Get-MgOrganization).VerifiedDomains | Where-Object { $PSItem.IsDefault }).Name.Split('.'))[0]
						
					}

				}
				
				#endregion Connect to PowerShell SDK for Microsoft Graph (Microsoft.Graph Module) as user with BasicAuth.

			}
			
			'UserModernAuthParameterSet' {
								
				# If $CredentialUserName is a period (.) then get current user account's userPrincipalName (UPN).
				If ( $AdminCredentialUserName -EQ '.' ) { $AdminCredentialUserName = ( [AdsiSearcher] "(&(ObjectCategory=Person)(sAMAccountName=$Env:USERNAME))" ).FindOne().Properties['userprincipalname'] }

				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to Azure Az PowerShell (Az.Accounts Module) as user with ModernAuth.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

				If ( $ConnectAzAccount ) {
						
					# Check if currently connected.
					$isAzAccountConnected = $NULL
					Try {

						$isAzAccountConnected = [Bool] (Get-AzContext -ErrorAction Stop)

					} Catch {
						$isAzAccountConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'Az.Accounts' is not installed."
					}
					Write-Debug "`$isAzAccountConnected: '$isAzAccountConnected'"
					
					# If not connected then connect.
					If ( -Not $isAzAccountConnected ) {
						
						# Create a hash table to splat parameters.  
						$connectAzAccountParameters = @{}
						$connectAzAccountParameters.AccountId = $AdminCredentialUserName
						$connectAzAccountParameters.Debug = $FALSE
						$connectAzAccountParameters.ErrorAction = 'Stop'
						$connectAzAccountParameters.Verbose = $FALSE
						$connectAzAccountParameters.WhatIf = $FALSE
						If ( $Debug ) {
							ForEach ( $key In $connectAzAccountParameters.Keys ) {
								Write-Debug "`$connectAzAccountParameters[$key]: '$($connectAzAccountParameters[$key])'"
							}
						}
						
						Write-Host "$(Get-Date) Connecting to AzAccount as user with ModernAuth."
						$psAzureProfile = Connect-AzAccount @connectAzAccountParameters
						
						#$tenantName = ((Get-AzDomain -ErrorAction Stop -Verbose:$FALSE -Debug:$FALSE).DefaultDomain.Split('.'))[0]
						
					}
					
				}

				#endregion Connect to Azure Az PowerShell (Az.Accounts Module) as user with ModernAuth.
				
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to Exchange Online PowerShell V3 (ExchangeOnlineManagement module) as user with ModernAuth.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				
				If ( $ConnectExchangeOnline ) {					
							
					# Check if currently connected.
					$isExchangeOnlineConnected = $NULL
					Try {

						$isExchangeOnlineConnected = ( [Bool] (Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.ComputerName -Eq 'outlook.office365.com' } ) -Or [Bool] (Get-ConnectionInformation -ErrorAction Stop) ) # -And $PSItem.State -Eq 'Opened'

					} Catch {
						$isExchangeOnlineConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'ExchangeOnlineManagement' is not installed."
					}
					Write-Debug "`$isExchangeOnlineConnected: '$isExchangeOnlineConnected'"
					
					# If not connected then connect.
					If ( -Not $isExchangeOnlineConnected ) {
					
						# Create a hash table to splat parameters.  
						$connectExchangeOnlineParameters = @{}
						#$connectExchangeOnlineParameters.CommandName = @( 'Get-AcceptedDomain', 'Get-ExoRecipient' ) # Minimal list of module functions this solution requires.  
						$connectExchangeOnlineParameters.Debug = $FALSE
						$connectExchangeOnlineParameters.ErrorAction = 'Stop'
						$connectExchangeOnlineParameters.ShowBanner = $FALSE
						$connectExchangeOnlineParameters.UserPrincipalName = $AdminCredentialUserName
						$connectExchangeOnlineParameters.Verbose = $FALSE	
						If ( $Debug ) {
							ForEach ( $key In $connectExchangeOnlineParameters.Keys ) {
								Write-Debug "`$connectExchangeOnlineParameters[$key]: '$($connectExchangeOnlineParameters[$key])'"
							}
						}
						
						Write-Host "$(Get-Date) Connecting to ExchangeOnline as user with ModernAuth."
						Connect-ExchangeOnline @connectExchangeOnlineParameters
						
						# $exoSession = Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.State -Eq 'Opened' -And $PSItem.ComputerName -Eq 'outlook.office365.com' }
						# Write-Debug "`$exoSession.TokenExpiryTime: '$($exoSession.TokenExpiryTime)'"
						
					}
					
				}
				
				#endregion Connect to Exchange Online PowerShell V3 module as user with ModernAuth.

				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to Security & Compliance PowerShell via Exchange Online PowerShell V3 (ExchangeOnlineManagement module) as user with ModernAuth.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				
				If ( $ConnectIPPSSession ) {
					
					# Check if currently connected.
					$isIPConnected = $NULL
					Try {
						
						$isIPConnected = ( [Bool] (Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.State -Eq 'Opened' -And $PSItem.ComputerName -Eq '*.ps.compliance.protection.outlook.com' } ) )
						
					} Catch {
						$isIPConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'ExchangeOnlineManagement' is not installed."
					}
					Write-Debug "`$isIPConnected: '$isIPConnected'"
					
					# If not connected then connect.
					If ( -Not $isIPConnected ) {
						
						# Create a hash table to splat parameters.  
						$connectIPPSSessionParameters = @{}
						#$connectIPPSSessionParameters.CommandName = @( 'Get-AcceptedDomain', 'Get-ExoRecipient' ) # Minimal list of module functions this solution requires.  
						$connectIPPSSessionParameters.Debug = $FALSE
						$connectIPPSSessionParameters.ErrorAction = 'Stop'
						$connectIPPSSessionParameters.UserPrincipalName = $AdminCredentialUserName
						$connectIPPSSessionParameters.Verbose = $FALSE	
						If ( $Debug ) {
							ForEach ( $key In $connectIPPSSessionParameters.Keys ) {
								Write-Debug "`$connectIPPSSessionParameters[$key]: '$($connectIPPSSessionParameters[$key])'"
							}
						}
						
						Write-Host "$(Get-Date) Connecting to IPPSSession as user with ModernAuth."
						Connect-IPPSSession @connectIPPSSessionParameters
						
						$ipSession = Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.State -Eq 'Opened' -And $PSItem.ComputerName -Like '*.ps.compliance.protection.outlook.com' }
						Write-Debug "`$ipSession.TokenExpiryTime: '$($ipSession.TokenExpiryTime)'"
						
						If ( $Debug ) {
							(Get-Command -Module $ipSession.CurrentModuleName).Name
						}

					}
					
				}

				#endregion Connect to Security & Compliance PowerShell via Exchange Online PowerShell V3 module as user with ModernAuth.
				
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to on-premises Exchange Server PowerShell (Exchange Management Shell) as user with ModernAuth, not supported.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

				If ( $ConnectExchangeServer ) {
					Throw 'Connecting with ModernAuth not supported with on-premises Exchange Server PowerShell (Exchange Management Shell).'
				}
							
				#endregion Connect to on-premises Exchange Server PowerShell (Exchange Management Shell) as user with ModernAuth, not supported.
				
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to SharePoint Online Administration Center Management Shell (Microsoft.Online.SharePoint.PowerShell Module) as user with ModernAuth.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

				If ( $ConnectSpoService ) {
					
					# Check if currently connected.
					$isSpoServiceConnected = $NULL
					Try {
						
						Get-SPOTenant -ErrorAction Stop | Out-Null
						
						$isSpoServiceConnected = $TRUE
					} Catch {
						$isSpoServiceConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'Microsoft.Online.SharePoint.PowerShell' is not installed."
					}
					Write-Debug "`$isSpoServiceConnected: '$isSpoServiceConnected'"
					
					# If not connected then connect.	
					If ( -Not $isSpoServiceConnected ) {
							
						# Create a hash table to splat parameters.  
						$connectSpoServiceParameters = @{}
						#$connectSpoServiceParameters.AuthenticationUrl https://login.microsoftonline.com/organizations
						#$connectSpoServiceParameters.Credential = $AdminCredential # If no credentials are presented, a dialog will prompt for the credentials. This is required if the account is using multi-factor authentication.
						$connectSpoServiceParameters.ModernAuth = $TRUE
						If ( $Region ) { $connectSpoServiceParameters.Region = $Region }
						$connectSpoServiceParameters.Debug = $FALSE
						$connectSpoServiceParameters.ErrorAction = 'Stop'
						$connectSpoServiceParameters.Verbose = $FALSE
						If ( $Url) { 
							$connectSpoServiceParameters.Url = $Url
						} Else {
							$connectSpoServiceParameters.Url = "https://$tenantName-admin.sharepoint.com"
						}
						If ( $Debug ) {
							ForEach ( $key In $connectSpoServiceParameters.Keys ) {
								Write-Debug "`$connectSpoServiceParameters[$key]: '$($connectSpoServiceParameters[$key])'"
							}
						}
						
						Write-Host "$(Get-Date) Connecting to SharePoint Online Management Shell service as user with BasicAuth."
						Connect-SpoService @connectSpoServiceParameters
						
					}
		
				}

				#endregion Connect to SharePoint Online Management Shell (Microsoft.Online.SharePoint.PowerShell Module) as user with ModernAuth, not supported.

				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to Microsoft Teams (MicrosoftTeams Module) as user with ModernAuth.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

				If ( $ConnectMicrosoftTeams ) {
					
					# Check if currently connected.
					$isMicrosoftTeamsConnected = $NULL
					Try {
						
						Get-CsTenant -ErrorAction Stop | Out-Null
						
						$isMicrosoftTeamsConnected = $TRUE
					} Catch {
						$isMicrosoftTeamsConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'MicrosoftTeams' is not installed."
					}
					Write-Debug "`$isMicrosoftTeamsConnected: '$isMicrosoftTeamsConnected'"
					
					# If not connected then connect.
					If ( -Not $isMicrosoftTeamsConnected ) {
						
						# Create a hash table to splat parameters.  
						$connectMicrosoftTeamsParameters = @{}
						#$connectMicrosoftTeamsParameters.Credential = $AdminCredential
						$connectMicrosoftTeamsParameters.Debug = $FALSE
						$connectMicrosoftTeamsParameters.ErrorAction = 'Stop'
						$connectMicrosoftTeamsParameters.Verbose = $FALSE
						$connectMicrosoftTeamsParameters.WhatIf = $FALSE
						If ( $Debug ) {
							ForEach ( $key In $connectMicrosoftTeamsParameters.Keys ) {
								Write-Debug "`$connectMicrosoftTeamsParameters[$key]: '$($connectMicrosoftTeamsParameters[$key])'"
							}
						}
						
						Write-Host "$(Get-Date) Connecting to Microsoft Teams as user with ModernAuth."
						$pSAzureContext = Connect-MicrosoftTeams @connectMicrosoftTeamsParameters
						
					}
						
				}

				#endregion Connect to Microsoft Teams (MicrosoftTeams Module) as user with ModernAuth.	

				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				#region Connect to PowerShell SDK for Microsoft Graph (Microsoft.Graph Module) as user with ModernAuth.
				#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
				
				If ( $ConnectMgGraph ) {
					
					# Check if currently connected.
					$isMgGraphConnected = $NULL
					Try {
						
						$isMgGraphConnected = [Bool] (Get-MgContext)
						
					} Catch {
						$isMgGraphConnected = $FALSE
						Write-Error "$(Get-Date) PowerShell module 'Microsoft.Graph.Authentication' is not installed."
					}
					Write-Debug "`$isMgGraphConnected: '$isMgGraphConnected'"
					
					# If not connected then connect.
					If ( -Not $isMgGraphConnected ) {
							
						# Create a hash table to splat parameters.  
						$connectMgGraphParameters = @{}
						$connectMgGraphParameters.Debug = $FALSE
						$connectMgGraphParameters.ErrorAction = 'Stop'
						$connectMgGraphParameters.Scopes = $Scopes
						$connectMgGraphParameters.Verbose = $FALSE
						If ( $Debug ) {
							ForEach ( $key In $connectMgGraphParameters.Keys ) {
								Write-Debug "`$connectMgGraphParameters[$key]: '$($connectMgGraphParameters[$key])'"
							}
						}
						
						Write-Host "$(Get-Date) Connecting to MgGraph as user with ModernAuth."
						$psMgGraphContext = Connect-MgGraph @connectMgGraphParameters
						
						#$tenantName = ( (Get-AzureADDomain -ErrorAction Stop -Verbose:$FALSE -Debug:$FALSE | Where-Object { $PSItem.IsDefault }).Name.Split( '.') )[0] 
						
					}
						
				}
				
				#endregion Connect to PowerShell SDK for Microsoft Graph (Microsoft.Graph Module) as user with ModernAuth.

			}

			Default {
				Write-Error "Unhandled ParameterSetName: '$($PsCmdlet.ParameterSetName)'."
			}
			
		}
			
	}
	
	Process {	
		# This block intentionally left blank.
	}
	
	End { 
		
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
		# Optionally write script execution metrics.
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
		
		Write-Verbose "`$MyInvocation.MyCommand.Name End: '$($MyInvocation.MyCommand.Name)'"
		$scriptEndTime = Get-Date
		Write-Verbose "`t`$scriptEndTime: '$($scriptEndTime.ToString('s'))'" 
		$scriptElapsedTime =  $scriptEndTime - $scriptStartTime
		Write-Verbose "`t`$scriptElapsedTime: '$scriptElapsedTime'"
		
	}
	
}