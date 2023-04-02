# M365Admin

## SYNOPSIS
Connects to M365 services (workload) and on-premises Exchange mailbox management server.

## DESCRIPTION
Connects to M365 services (workload):
>	Azure ActiveDirectory PowerShell (Az.Resources module)

>	Exchange Online PowerShell V3 (ExchangeOnlineManagement module)

>	Security & Compliance PowerShell via Exchange Online PowerShell V3 (ExchangeOnlineManagement module)

>	Exchange Server PowerShell (Exchange Management Shell)

>	SharePoint Online Management Shell (Microsoft.Online.SharePoint.PowerShell module)

>	Microsoft Teams (MicrosoftTeams module)

>	PowerShell SDK for Microsoft Graph (Microsoft.Graph module)
			
### PARAMETER AdminCredential 
The Credential parameter specifies the administrator's user name and password that's used to run this command. Typically, you use this parameter in scripts or when you need to provide different credentials that have the required permissions.
This parameter requires the creation and passing of a credential object. This credential object is created by using the Get-Credential cmdlet. For more information, see Get-Credential (http://go.microsoft.com/fwlink/p/?linkId=142122).

### PARAMETER AdminCredentialUserName 
Specifies an administrator's user name for the credential in User Principal Name (UPN) format, such as "user@domain.com". Use the period (.) to get the current user's UPN.
The UserPrincipalName parameter specifies the account that you want to use to connect (for example, navin@contoso.onmicrosoft.com). Using this parameter allows you to skip the username dialog in the modern authentication prompt for credentials (you only need to enter your password).
			
### PARAMETER AdminCredentialPasswordFilePath 
Specifies file name where the administrator's secure credential password file is located.  The default of null will prompt for the credentials.
SecureString is encoded with default Data Protection API (DPAPI) with a DataProtectionScope of CurrentUser and LocalMachine security tokens.
To write a secure (encrypted) string file:

Read-Host -AsSecureString "Securely enter password" | ConvertFrom-SecureString | Out-File -FilePath '.\SecureCredentialPassword.txt'

### PARAMETER ApplicationId 
Specifies the application ID of the service principal.
The AppId parameter specifies the application ID of the service principal that's used in certificate based authentication (CBA). A valid value is the GUID of the application ID (service principal). For example, 36ee4c6c-0812-40a2-b820-b22ebd02bce3.
The client id of your application.
			
### PARAMETER CertificateThumbprint 
Certificate Hash or Thumbprint.
The CertificateThumbprint parameter specifies the certificate that's used for CBA. A valid value is the thumbprint value of the certificate. For example, 83213AEAC56D61C97AEE5C1528F4AC5EBA7321C1.
Specifies the certificate thumbprint of a digital public key X.509 certificate of a user account that has permission to perform this action.
The thumbprint of your certificate. The Certificate will be retrieved from the current user's certificate store.

### PARAMETER UseBasicAuth
When specified use BasicAuth instead of the preferred ModernAuth for the following connection parameters:
>	-ConnectAzAccount

>	-ConnectExchangeOnline

>	-ConnectIPPSSession

### PARAMETER ConnectAzAccount 
When specified connect to Azure Resource Management.   

Microsoft services (workload) supported:
>	Azure ActiveDirectory via Az.Resources module.

>	All other Az.* modules and their supported resources and services (workload).

Authentication protocol this solution supports for this service:
>	Password based Basic Authentication (BasicAuth) is - not supported.

>	Token based Modern Authentication (ModernAuth or OAuth 2.0) including support for multi-factor authentication (MFA) is - supported.

>	Certificate-based application (CBA) authentication is - supported.

				
### PARAMETER ConnectExchangeOnline 
When specified connect to Exchange Online.  

Microsoft services (workload) supported:
>	Exchange Online via ExchangeOnlineManagement module.

Authentication protocol this solution supports for this service:
>	Password based Basic Authentication (BasicAuth) is - not supported.

>	Token based Modern Authentication (ModernAuth or OAuth 2.0) including support for multi-factor authentication (MFA) is - supported.

>	Certificate-based application (CBA) authentication is - supported.

### PARAMETER ConnectExchangeServer 
When specified connect to on-premises Exchange mailbox management admin server using remote PowerShell session (WinRM).  

Microsoft services (workload) accessed:
>	Exchange on premises.

Authentication protocol this solution supports for this service:
>	Password based Basic Authentication (BasicAuth) is - supported.

>	Token based Modern Authentication (ModernAuth or OAuth 2.0) including support for multi-factor authentication (MFA) is - not supported.

>	Certificate-based application (CBA) authentication is - supported.

### PARAMETER ConnectIPPSSession 
When specified connect to Information Protection using the ExchangeOnlineManagement module.  

Microsoft services (workload) supported:
>	Security and Compliance via ExchangeOnlineManagement module.

Authentication protocol this solution supports for this service:
>	Password based Basic Authentication (BasicAuth) is - not supported.

>	Token based Modern Authentication (ModernAuth or OAuth 2.0) including support for multi-factor authentication (MFA) is - supported.

>	Certificate-based application (CBA) authentication is - supported.
		
### PARAMETER ConnectMicrosoftTeams 
When specified connect to Microsoft Teams.  

Microsoft services (workload) accessed:
>	Microsoft Teams via MicrosoftTeams module.  

Authentication protocol this solution supports for this service:
>	Password based Basic Authentication (BasicAuth) is - supported.

>	Token based Modern Authentication (ModernAuth or OAuth 2.0) including support for multi-factor authentication (MFA) is - not supported.

>	Certificate-based application (CBA) authentication is - not supported.
			
### PARAMETER ConnectMgGraph 
When specified connect to Microsoft Graph using the Microsoft.Graph PowerShell SDK module.  
The PowerShell SDK supports two types of access: delegated user, and app-only access.  
MgGraph does not elevate a delegated users beyond what it has already been granted by other means such as being added to a directory role, a role-based access control (RBAC) group, or granted rights to inpersonate.  

Microsoft services (workload) supported:
>	Audit and Reporting via Microsoft.Graph.Reports module.

>	Azure ActiveDirectory via Microsoft.Graph.DirectoryObjects, Microsoft.Graph.Groups, Microsoft.Graph.Identity.DirectoryManagement, Microsoft.Graph.Users modules.

>	Information Protection via Microsoft.Graph.Identity.SignIns module.

>	Intune via Microsoft.Graph.DeviceManagement.*, Microsoft.Graph.Devices.CorporateManagement modules.  

>	Licensing via Microsoft.Graph.Identity.DirectoryManagement module.

>	Microsoft Teams via Microsoft.Graph.Teams module.

>	Security and Compliance via Microsoft.Graph.Security module.

>	Service Health via Microsoft.Graph.Devices.ServiceAnnouncement module.  

>	SharePoint Online via Microsoft.Graph.Files, Microsoft.Graph.Sites modules.  

>	All other Microsoft.Graph.* modules and their supported resources and services (workload).

Authentication protocol this solution supports for this service:
>	Password based Basic Authentication (BasicAuth) is - not supported.

>	Token based Modern Authentication (ModernAuth or OAuth 2.0) including support for multi-factor authentication (MFA) is - supported.

>	Certificate-based application (CBA) authentication is - supported.
		
### PARAMETER ConnectSPOService 
When specified connect to SharePoint Online.  

Microsoft services (workload) accessed:
>	SharePoint Online Management Shell via Microsoft.Online.SharePoint.PowerShell module.  

Authentication protocol this solution supports for this service:
>	Password based Basic Authentication (BasicAuth) is - supported.

>	Token based Modern Authentication (ModernAuth or OAuth 2.0) including support for multi-factor authentication (MFA) is - not supported.

>	Certificate-based application (CBA) authentication is - not supported.

### PARAMETER ExchangeServerFqdn 
One or more on-premises Exchange mailbox management admin server fully qualified domain name. If not specified a list of server FQDNs will be collected from on-premises Active Directory and one will be randomly selected.  
 
### PARAMETER ExchPowerShellMaxConnectionTimePeriodMinutes 
The number of minutes to stay connected to on-premises Exchange mailbox management admin server before refreshing (disconnect/connect).  The default is every 45 minutes.  

### PARAMETER Tenant 
Optional tenant name or ID.
The Organization parameter specifies the organization that's used in CBA. Be sure to use an .onmicrosoft.com domain for the parameter value. Otherwise, you might encounter cryptic permission issues when you run commands in the app context.
			
### PARAMETER AuthenticationUrl 
SharePoint Online location for AAD Cross-Tenant Authentication service. Can be optionally used if non-default Cross-Tenant Authentication Service is used.

### PARAMETER Region
The valid values are: Default | ITAR | Germany | China
The default value is "default".
Note: The ITAR value is for GCC High and DoD tenancies only.

### PARAMETER Url 
Specifies the URL of the SharePoint Online Administration Center site.  For example https://consoto-admin.sharepoint.com/
