Function Convert-DistinguishedNameToCanonicalName {
	<#
		.SYNOPSIS
			Convert DistinguishedName string to Active Direcory constructed attribute CanonicalName value.  

		.DESCRIPTION
			Convert DistinguishedName string to Active Direcory constructed attribute CanonicalName value.  
			
			Escaped LDAP DistinguishedName characters are supported.  
			
			Microsoft Active Direcory Duplicate Object Name Resolution '\0ACNF:<objectGUID>' is supported.  
						
		.PARAMETER DistinguishedName String
			RFC 4512 compliant LDAP DistinguishedName string.
			
		.OUTPUTS
			String Canonical-Name attribute https://docs.microsoft.com/en-us/windows/win32/adschema/a-canonicalname

		.EXAMPLE
			This example searches for all Active Direcory user objects, and writes their CanonicalName.  

			Get-ADUser -Filter * | 
				ForEach-Object {
					Convert-DistinguishedNameToCanonicalName -DistinguishedName $PSItem.DistinguishedName
				}
				
			contoso.com/Users/UserA
			contoso.com/Users/UserB
			contoso.com/Users/UserC
			...

		.EXAMPLE
			This example searches for an Active Direcory object named 'UserA', and pipes the returned object to Convert-DistinguishedNameToCanonicalName

			Get-ADUser -Filter UserA | 
				Convert-DistinguishedNameToCanonicalName
				
			contoso.com/Users/UserA
			
		.NOTES
			Author: Terry E Dow
			Creation Date: 2014-02-22
			Last Modified: 2020-09-29

			A DistinguishedName pattern has been seen that is not handled with this solution:
			DC=a.root-servers.net,DC=RootDNSServers,CN=MicrosoftDNS,CN=System,DC=contoso,DC=com
			contoso.com/System/MicrosoftDNS/RootDNSServers/a.root-servers.net
			
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
		[String] $DistinguishedName = ''
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

		$distinguishedNamePattern = [RegEx]::New( '^(?<RDN>(?:CN|OU)=[^,]*)?(?<PDN>((,(?:CN|OU)=[^,]+,?)+))?,?(?<DC>(DC=[^,]+,?)+)$', [Text.RegularExpressions.RegexOptions]::Compiled ) 
		
		$DNCharsToEscape = '\"#+,;<=>' # https://social.technet.microsoft.com/wiki/contents/articles/5312.active-directory-characters-to-escape.aspx # Replace order specific - replace escape character (self) first, then other characters.
		$CNCharsToEscape = '\/' # https://social.technet.microsoft.com/wiki/contents/articles/5312.active-directory-characters-to-escape.aspx
	}
	
	Process {
	
		# Escape Duplicate Object Name Resolution '\0ACNF:<objectGUID>'.
		$DistinguishedName = $DistinguishedName.Replace( '\0A', '%0A' )
	
		# Escape embedded DistinguishedName delimiter character.
		$DistinguishedName = $DistinguishedName.Replace( '\,', '%2C' )
	
		# Remove the DistinguishedName escaped characters.
		ForEach ( $char In $DNCharsToEscape.ToCharArray() ) {
			$char = [Char] $char
			$DistinguishedName = $DistinguishedName.Replace( "\$char", "$char" )
		}

		# Add CanonicalName escaped characters.  
		ForEach ( $char In $CNCharsToEscape.ToCharArray() ) {
			$char = [Char] $char
			$DistinguishedName = $DistinguishedName.Replace( "$char", "\$char" )
		}		

		$domainComponent = ''
		$parentDistinguishedName = ''
		$relativeDistinguishedName = ''
		
		# Parse DistinguishedName via RegEx pattern.  
		If ( $DistinguishedName -Match $distinguishedNamePattern ) { 
			
			If ( $Matches.RDN ) { 
				$relativeDistinguishedName = $Matches.RDN.Replace( 'CN=', '' ).Replace( 'OU=', '' )
			}
			#Write-Debug "`$relativeDistinguishedName: '$relativeDistinguishedName'"
			
			# Split, then reverse the order of PDN components, and then join them with CanonicalName delimiter.  
			If ( $Matches.PDN ) { 
				$parentDistinguishedName = $Matches.PDN.Replace( ',CN=', '/' ).Replace( ',OU=', '/' ).Trim( 'CN=' ).Trim( 'OU=' ).Trim( '/' ).Trim( ',' )
				$parentDistinguishedNameSplit = $parentDistinguishedName.Split( '/' )
				$parentDistinguishedNameSplitLastIndex = @( $parentDistinguishedNameSplit ).Count - 1
				$parentDistinguishedName = ( ( $parentDistinguishedNameSplit[ $parentDistinguishedNameSplitLastIndex..0 ] ) -Join '/' )
			}
			#Write-Debug "`$parentDistinguishedName: '$parentDistinguishedName'"
			
			$domainComponent = $Matches.DC.Replace( ',DC=', '.' ).Trim( 'DC=' ) 
			#Write-Debug "`$domainComponent: '$domainComponent'"
			
		}

		# Join components, and then restore escaped embeded DistinguishedName delimiter character and Duplicate Object Name Resolution '\0ACNF:<objectGUID>'.
		$canonicalName = "$domainComponent/$( ( ( $parentDistinguishedName, $relativeDistinguishedName ) | Where-Object { $PSItem } ) -Join '/' )".Replace( '%2C', ',' ).Replace( '%0A', "$([Char] 10)" )
			
		Write-Output $canonicalName
	}
}