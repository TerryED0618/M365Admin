Function Convert-CanonicalNameToDistinguishedName {
	<#
		.SYNOPSIS
			Convert Microsoft Active Direcory CanonicalName string to LDAP DistinguishedName value.  

		.DESCRIPTION
			Convert Microsoft Active Direcory CanonicalName string to LDAP DistinguishedName value.  
			
			Escaped LDAP DistinguishedName characters are supported.  
			
			Microsoft Active Direcory Duplicate Object Name Resolution '\0ACNF:<objectGUID>' is supported.  
			
			With Microsoft Active Direcory their are both OrganizationalUnits (OU) and container objects (CN).  CanonicalNames do not provide this information.  Most parent distinguished name (PDN) paths are assumed to be OrganizationalUnits (OU) and may not match the object's DistinguisedName correctly.  
			Some well known Microsoft containers are supported:
				Builtin
				Computers
				ForeignSecurityPrincipals
				System
				Users
								
		.PARAMETER CanonicalName String
			Microsoft Active Direcory constructed Canonical-Name attribute https://docs.microsoft.com/en-us/windows/win32/adschema/a-canonicalname

		.PARAMETER IsOrganizationalUnit Switch
			The relative distinguished name (RDN) is assumed to be a common-name 'CN='.  When enabled, the RDN of 'OU=' is used instead.  No change is made with the parent distinguished name (PDN) path.  
			
		.OUTPUTS
			RFC 4512 compliant LDAP DistinguishedName string.

		.EXAMPLE
			This example searches for all Active Direcory user objects, and writes their DistinguishedName.  

			Get-ADUser -Filter * -Properties CanonicalName | 
				Where-Object { $PSItem.CanonicalName } |
				ForEach-Object {
					Convert-CanonicalNameToDistinguishedName -CanonicalName $PSItem.CanonicalName
				}
			
			CN=UserA,CN=Users,DC=contoso,DC=com
			CN=UserB,CN=Users,DC=contoso,DC=com
			CN=UserC,CN=Users,DC=contoso,DC=com
			...

		.EXAMPLE
			This example searches for all Active Direcory user objects, and pipes the returned objects to Convert-CanonicalNameToDistinguishedName

			Get-ADUser -Filter * -Properties CanonicalName | 
				Where-Object { $PSItem.CanonicalName } |
				Convert-CanonicalNameToDistinguishedName
			
			CN=UserA,CN=Users,DC=contoso,DC=com
			CN=UserB,CN=Users,DC=contoso,DC=com
			CN=UserC,CN=Users,DC=contoso,DC=com
			...

		.NOTES
			Author: Terry E Dow
			Creation Date: 2014-02-22
			Last Modified: 2020-09-29
			
		.LINK
			https://github.com/TerryED0618/
	#>
	[CmdletBinding()]
	Param (
	
		[parameter(
			Mandatory=$TRUE,
			ValueFromPipeLine=$TRUE,
			ValueFromPipeLineByPropertyName=$TRUE
		)]
		[ValidateNotNullOrEmpty()]
		[Alias( 'Identity' )]
		[String] $CanonicalName = '',
		
		[Switch] $IsOrganizationalUnit = $NULL
		
	)
		
	Begin {
		Set-StrictMode -Version Latest

		# Detect cmdlet common parameters. 
		$cmdletBoundParameters = $PSCmdlet.MyInvocation.BoundParameters
		$Debug = If ( $cmdletBoundParameters.ContainsKey('Debug') ) { $cmdletBoundParameters['Debug'] } Else { $FALSE }
		# Replace default -Debug preference from 'Inquire' to 'Continue'.  
		If ( $DebugPreference -Eq 'Inquire' ) { $DebugPreference = 'Continue' }
		$Verbose = If ( $cmdletBoundParameters.ContainsKey('Verbose') ) { $cmdletBoundParameters['Verbose'] } Else { $FALSE }
		$WhatIf = If ( $cmdletBoundParameters.ContainsKey('WhatIf') ) { $cmdletBoundParameters['WhatIf'] } Else { $FALSE }
		Remove-Variable -Name cmdletBoundParameters -WhatIf:$FALSE
		
		$DNCharsToEscape = '\"#+,;<=>' # https://social.technet.microsoft.com/wiki/contents/articles/5312.active-directory-characters-to-escape.aspx # Replace order specific - replace escape character (self) first, then other characters.
		$CNCharsToEscape = '\/' # https://social.technet.microsoft.com/wiki/contents/articles/5312.active-directory-characters-to-escape.aspx
	}
	
	Process { 
		# Escape Duplicate Object Name Resolution '\0ACNF:<objectGUID>'.
		$canonicalName = $canonicalName -Replace "\$([Char] 10)", '%0A' 
	
		# Escape embedded CanonicalName delimiter character and split into components.
		$components = $canonicalName.Replace( '\/', '%2F' ).Trim( '/' ).Split( '/' ) 
		#Write-Debug "`$components: '$components'"
		$componentLastIndex = @( $components ).Count - 1 
		#Write-Debug "`$componentLastIndex: '$componentLastIndex'"
		
		# For each component remove the CanonicalName escaped characters, and add DistinguishedName escaped characters.  
		For ( $i = 0; $i -LE $componentLastIndex; $i++ ) {
			ForEach ( $char In $CNCharsToEscape.ToCharArray() ) {
				$char = [Char] $char
				$components[ $i ] = $components[ $i ].Replace( "\$char", "$char" )
			}
		
			ForEach ( $char In $DNCharsToEscape.ToCharArray() ) {
				$char = [Char] $char
				$components[ $i ] = $components[ $i ].Replace( "$char", "\$char" )
			}
		}
		
		# Build the first (RDN) component.
		If ( 0 -LT $componentLastIndex ) {
			If ( $IsOrganizationalUnit ) {
				$relativeDistinguishedName = "OU=$( $components[-1] )"
			} Else {
				$relativeDistinguishedName = "CN=$( $components[-1] )"
			}
		} Else {
			$relativeDistinguishedName = '' 
		}
		#Write-Debug "`$relativeDistinguishedName: '$relativeDistinguishedName'"
		
		# Optionally remove first and last component, reverse the order, then build middle (PDN) component.  
		If ( 1 -LT $componentLastIndex ) {
			$parentDistinguishedName = "OU=$( @( $components | Select-Object -Skip 1 | Select-Object -SkipLast 1  )[ ($componentLastIndex - 2)..0 ] -Join ',OU=' )" 
		} Else {
			$parentDistinguishedName = ''
		}
		#Write-Debug "`$parentDistinguishedName: '$parentDistinguishedName'"
		
		# Build last (DC) component.  
		$domainComponent = "DC=$( $components[0].Split('.') -Join ',DC=' )"
		#Write-Debug "`$domainComponent: '$domainComponent'"
		
		# Join components.
		$distinguishedName = ( ( $relativeDistinguishedName, $parentDistinguishedName, $domainComponent ) | Where-Object { $PSItem } ) -Join ',' 

		# Windows Active Directory domain root 'Builtin', 'Computers' and 'Users' are not OrganizationalUnits, they are containers.  
		$distinguishedName = $distinguishedName.Replace( 'OU=Builtin,DC=', 'CN=Builtin,DC=' ).Replace( 'OU=Computers,DC=', 'CN=Computers,DC=' ).Replace( 'OU=ForeignSecurityPrincipals,DC=', 'CN=ForeignSecurityPrincipals,DC=' ).Replace( 'OU=System,DC=', 'CN=System,DC=' ).Replace( 'OU=Users,DC=', 'CN=Users,DC=' )
		# Microsoft Exchange 'Microsoft Exchange System Objects' and 'Monitoring Mailboxes' are not OrganizationalUnits, they are containers.
		$distinguishedName = $distinguishedName.Replace( 'OU=Microsoft Exchange System Objects,DC=', 'CN=Microsoft Exchange System Objects,DC=' ).Replace( 'OU=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=', 'CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=' ) # Replace order specific.
		# Microsoft System Center Operations Manager (SCOM/SCCM) 'OperationsManager' and 'OpsMgrLatencyMonitors', 'System' and 'System Management' are not OrganizationalUnits, they are containers.  
		$distinguishedName = $distinguishedName.Replace( 'OU=OperationsManager,DC=', 'CN=OperationsManager,DC=' ).Replace( 'OU=OpsMgrLatencyMonitors,DC=', 'CN=OpsMgrLatencyMonitors,DC=' ).Replace( 'OU=System,DC=', 'CN=System,DC=' ).Replace( 'OU=System Management,CN=System,OU=System,DC=', 'CN=System Management,CN=System,OU=System,DC=' )
		
		# Restore escaped embeded CanonicalName delimiter character and Duplicate Object Name Resolution '\0ACNF:<objectGUID>'.
		$distinguishedName = $distinguishedName.Replace( '%2F', '/' ).Replace( '%0A', '\0A' )
		
		Write-Output $distinguishedName
	}
}