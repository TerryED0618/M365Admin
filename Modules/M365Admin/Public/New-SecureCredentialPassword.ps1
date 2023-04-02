Function New-SecureCredentialPassword {
	<#
		.SYNOPSIS
			This interactive cmdlet prompts and then writes a password to a secured (encrypted) text file.

		.DESCRIPTION
			The user is prompted to enter their password twice into two SecureStrings.  SecureString encodes with default Data Protection API (DPAPI) with a DataProtectionScope of CurrentUser and LocalMachine security tokens.  If the two passwords match, one is written to an encrypted text file that can only be decrypt using the user's credentials on the same computer.  Even after the user's password is changed their new credentials can still decrypt the file.  
			
			WARNING:
			Comparison of the two passwords must be done in PlainText so an in-memory security vulnerability exists during this cmdlet's execution.  Close this session as soon as possible to limit exposure to memory scanning malware.  For more information see System.Management.Automation.PSCredential.GetNetworkCredential().Password
			
			The UserName component of the credential is informative only and not saved.  
			
		.PARAMETER OutFilePath String
			Specifies the path to the output file.

		.NOTES
			2016-09-02	Terry E Dow - Initial version
			2022-08-26	Terry E Dow - Set password equal comparison to case-sensitive "-cEQ".  
			2022-08-26	Terry E Dow - Replaced $Env:USERNAME with [Environment]::UserName with the intent to be cross platform.  
			
	#>
	Param(
		[Parameter(
			ValueFromPipeline=$TRUE,
			ValueFromPipelineByPropertyName=$TRUE 
		)]
		[ValidateNotNullOrEmpty()]
		[String] $FilePath = '.\SecureCredentialPassword.txt'
	)

	Write-Host "Select Cancel button twice to abort."

	$passwordsMatch = $FALSE
	While ( -Not $passwordsMatch ) {

		# Get two credentials
		$credential1 = Get-Credential -UserName [Environment]::UserName -Message "Enter your credentials a first time."
		$credential2 = Get-Credential -UserName [Environment]::UserName -Message "Enter your credentials a second time."

		# Extract passwords from credential SecureStrings.  
		If ( $credential1 ) {
			$password1 = $credential1.GetNetworkCredential().Password # In-memory Security Vulnerability!
		} Else {
			$password1 = ''
		}
		If ( $credential2 ) {
			$password2 = $credential2.GetNetworkCredential().Password # In-memory Security Vulnerability!
		} Else {
			$password2 = ''
		}
		
		# Verify both passwords were not blank.  
		If ( $password1 -And $password2 ) {
		
			# Verify both passwords match.  
			If ( $password1 -cEQ $password2 ) {
				$passwordsMatch = $TRUE
				
				# Write the 1st credential's password as a SecureString to a text file.  
				$credential1.Password | 
					ConvertFrom-SecureString | 
					Out-File -FilePath $FilePath
				If ( $? ) {
					Write-Host "$(Get-Date) Updated file $FilePath" -ForegroundColor Green
				}
		
			# Passwords did not match, warn and try again.  	
			} Else {	
				Write-Host "$(Get-Date) Passwords did not match." -ForegroundColor Red
			}

		# If only one is blank, warn and try again.  
		} ElseIf ( $password1 -XOR $password2 ) {
			Write-Host "$(Get-Date) Enter your password twice." -ForegroundColor Red
			
		# If both are blank, exit. 
		} Else {
			$passwordsMatch = $TRUE
			#Break
		}
		
	}

	# Clean up resource.
	Clear-Variable -Name password1
	Clear-Variable -Name password2
	Remove-Variable -Name password1
	Remove-Variable -Name password2
	
	# Prompt garbage collection.
	[System.GC]::GetTotalMemory( 'forcefullcollection' ) | Out-Null

}