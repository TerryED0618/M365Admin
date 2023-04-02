# Generic PowerShell module to import PS1 files into current session.  
# Attribution: http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/
# Attribution: https://github.com/andrewmatveychuk/powershell.sample-module/blob/master/SampleModule/SampleModule.psm1

# Get public and private function definition files, excluding Pester test scripts.  
$public  = If ( Test-Path -Path $PSScriptRoot\Public  -PathType Container ) { @( Get-ChildItem -Path $PSScriptRoot\Public\*.PS1  -Exclude "*.Tests.*" ) } Else { @() } 
$private = If ( Test-Path -Path $PSScriptRoot\Private -PathType Container ) { @( Get-ChildItem -Path $PSScriptRoot\Private\*.PS1 -Exclude "*.Tests.*" ) } Else { @() } 
# $test    = If ( Test-Path -Path $PSScriptRoot\Test    -PathType Container ) { @( Get-ChildItem -Path $PSScriptRoot\Test\*.PS1                         ) } Else { @() } 

# Dot source each of the PS1 files.
ForEach ( $import In @( $public + $private ) ) {
	Try {
		Write-Verbose "Importing $($import.FullName)..."
		
		. $import.fullname
		
	} Catch {
		Write-Error -Message "Failed to import function $($import.FullName): $PSItem"
	}
}

# Export Public functions:
# 	Rely on PSD1's FunctionsToExport (recommended) or include the following:
# 	If ( $public ) { Export-ModuleMember -Function $public.BaseName }