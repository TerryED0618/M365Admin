Function Test-ExchSessionState {
	<#
		.SYNOPSIS
			Check if current Exchange management server session state needs to be refreshed (disconnect/connect).

		.DESCRIPTION
			This function should be called prudently in an inner loop that is processing Exchange module commands.  
			
		.PARAMETER NewExchPSSessionParameters <Hashtable>
			A hashtable used to splat the New-PSSession parameters. https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting

		.PARAMETER ImportExchPSSessionParameters <Hashtable>
			A hashtable used to splat the Import-PSSession parameters. 
			
		.PARAMETER ExchPowerShellMaxConnectionTimePeriodMinutes <Int>
			The number of minutes to stay connected to Exchange (on-premises) mailbox management admin server before refreshing (disconnect/connect).  The default is every 45 minutes.  

		.PARAMETER ExchExchangeConnectionTimePeriodLast <DateTime>
			The date/time of the last time the Exchange mailbox management admin server connection is connected or refreshed.  
			
		.OUTPUTS
			ExchExchangeConnectionTimePeriodLast <DateTime> value is returned.  Pass this value back in when running, the value will be updated when the connection is refreshed and then returned by this function.  

		.EXAMPLE
			$exchExchangeConnectionTimePeriodLast = Test-ExchSessionState -ExchExchangeConnectionTimePeriodLast $exchExchangeConnectionTimePeriodLast -NewExchPSSessionParameters $newExchPSSessionParameters -ImportExchPSSessionParameters $importExchPSSessionParameters
	#>
	Param (
			[Parameter(Mandatory=$TRUE)]
		[DateTime] $ExchExchangeConnectionTimePeriodLast,
		
		[Int] $ExchPowerShellMaxConnectionTimePeriodMinutes = 45,
		
			[Parameter(Mandatory=$TRUE)]
		[Hashtable] $NewExchPSSessionParameters,
		
			[Parameter(Mandatory=$TRUE)]
		[Hashtable] $ImportExchPSSessionParameters,
										
		[Int] $sleepLength = 15, # Seconds
		
		[Int] $sleepProgressLength = 5 # Seconds

	)
	Write-Debug "`$MyInvocation.MyCommand.Name Begin: '$($MyInvocation.MyCommand.Name)'"
	Write-Debug "`t`$scriptStartTime: '$($scriptStartTime.ToString('s'))'" 
	Write-Debug "`t`$ExchExchangeConnectionTimePeriodLast: '$ExchExchangeConnectionTimePeriodLast'"
	
	$exchSession = Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And ( $PSItem.Name -Like 'ExchangeSession*' -Or $PSItem.Name -Like 'Session*' ) }
	Write-Debug "`t`$exchSession.Name: $($exchSession.Name)"
	Write-Debug "`t`$exchSession.State: $($exchSession.State)"
	Write-Debug "`t`$exchSession.Availability: $($exchSession.Availability)"
	
	$exchExchangeConnectionTimePeriodSinceSeconds = [Int] ( ( (Get-Date) - $exchExchangeConnectionTimePeriodLast ).TotalSeconds )
	Write-Debug "`$ExchExchangeConnectionTimePeriodSinceSeconds: $ExchExchangeConnectionTimePeriodSinceSeconds / $($ExchPowerShellMaxConnectionTimePeriodMinutes * 60)"
	If ( ($ExchPowerShellMaxConnectionTimePeriodMinutes * 60) -LT $exchExchangeConnectionTimePeriodSinceSeconds ) {
		Write-Host "$(Get-Date) Reconnecting on-premises Exchange mailbox management admin server session." -ForegroundColor Green
			
		# Remove Exchange PSSession.
		Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And ( $PSItem.Name -Like 'ExchangeSession*' -Or $PSItem.Name -Like 'Session*' ) } | Remove-PSSession -Confirm:$FALSE -WhatIf:$FALSE -Verbose:$FALSE -Debug:$FALSE
		
		For ( $i=1; $i -LE $sleepLength / $sleepProgressLength; $i++ ) {
			Write-Progress -Activity "Test-ExchSessionState: Sleeping" -Status "$($i * $sleepProgressLength) out of $sleepLength seconds" -PercentComplete ($i * $sleepProgressLength / $sleepLength * 100)
			Start-Sleep -Seconds $sleepProgressLength	
		}
		Write-Progress -Activity "Test-ExchSessionState: Sleeping" -Completed
		
		# Create Exchange PSSession.  
		$exchSession = New-PSSession @NewExchPSSessionParameters

		# Update ImportExchPSSessionParameters' Session parameter with new PSSession value.  
		$ImportExchPSSessionParameters.Session = $exchSession

		# Import session module.  
		$verbosePreferencePush = $VerbosePreference 
		$VerbosePreference = 'SilentlyContinue' # $VerbosePreference is overriding -Verbose:$FALSE
		$exchModuleInfo = Import-PSSession @importExchPSSessionParameters
		$VerbosePreference = $verbosePreferencePush
		
		If ( $Debug -And $exchSession.TokenExpiryTime ) {
			Write-Debug "`t`$exchSession.TokenExpiryTime (LocalTime): $($exchSession.TokenExpiryTime.ToLocalTime())" 
		} Else {
			Write-Debug "`t`$exchSession.TokenExpiryTime (LocalTime): $($exchSession.TokenExpiryTime)" 
		}
		Write-Debug "`t`$exchSession.Name: $($exchSession.Name)"
		Write-Debug "`t`$exchSession.State: $($exchSession.State)"
		Write-Debug "`t`$exchSession.Availability: $($exchSession.Availability)"
		
		# Reset metrics.
		$exchExchangeConnectionTimePeriodLast = (Get-Date)
	}
	
	Write-Debug "`$MyInvocation.MyCommand.Name End: '$($MyInvocation.MyCommand.Name)'"
	Write-Debug "`t`$ExchExchangeConnectionTimePeriodLast: '$ExchExchangeConnectionTimePeriodLast'"
	$scriptEndTime = Get-Date
	Write-Debug "`t`$scriptEndTime: '$($scriptEndTime.ToString('s'))'" 
	$scriptElapsedTime =  $scriptEndTime - $scriptStartTime
	Write-Debug "`t`$scriptElapsedTime: '$scriptElapsedTime'"
	Return $exchExchangeConnectionTimePeriodLast 
	
}
