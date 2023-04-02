Function Disconnect-M365Admin {
	<#

		.SYNOPSIS
			Disconnect from Microsoft 365 services and on-premises Exchange mailbox management server.

		.DESCRIPTION
			Disconnect from the following detected Microsoft 365 services as an administrator:
				Azure ActiveDirectory PowerShell (Az.Resources module)
				Exchange Online PowerShell V3 (ExchangeOnlineManagement module)
				Security & Compliance PowerShell via Exchange Online PowerShell V3 (ExchangeOnlineManagement module)
				Exchange Server PowerShell (Exchange Management Shell)
				SharePoint Online (Microsoft.Online.SharePoint.PowerShell module)
				Microsoft Teams (MicrosoftTeams module)
				PowerShell SDK for Microsoft Graph (Microsoft.Graph module)

			If none of the -Disconnect* parameters are specified (default), then all detected M365 services (workloads) will be implicitly disconnected.
			If any of the -Disconnect* parameters are specified, then only those specified will be explicitly disconnected, and the remaining connections are retained.

		.PARAMETER DisconnectAzAccount
			When specified any detected Azure ActiveDirectory is explicitly disconnected.  
			If no -Disconnect* parameter is specified (default) then Azure ActiveDirectory is implicitly disconnected.  
			If any -Disconnect* parameter is specified other than -DisconnectAzAccount then any Azure ActiveDirectory connection is retained.   

		.PARAMETER DisconnectExchangeOnline
			When specified any detected Exchange Online is explicitly disconnected.
			If no -Disconnect* parameter is specified (default) then Exchange Online is implicitly disconnected.  
			If any -Disconnect* parameter is specified other than -DisconnectExchangeOnline then any Exchange Online connection is retained.  

		.PARAMETER DisconnectExchangeServer
			When specified any detected on-premises Exchange Server is explicitly disconnected.
			If no -Disconnect* parameter is specified (default) then on-premises Exchange Server is implicitly disconnected.  
			If any -Disconnect* parameter is specified other than -DisconnectExchangeServer then any on-premises Exchange Server connection is retained.  

		.PARAMETER DisconnectIPPSSession
			When specified any detected Information Protection (Security and Compliance) is explicitly disconnected.
			If no -Disconnect* parameter is specified (default) then Information Protection is implicitly disconnected.
			If any -Disconnect* parameter is specified other than -DisconnectIPPSSession then any Information Protection connection is retained.  

		.PARAMETER DisconnectMgGraph
			When specified any detected Microsoft Graph is explicitly disconnected.
			If no -Disconnect* parameter is specified (default) then Microsoft Graph is implicitly disconnected.  
			If any -Disconnect* parameter is specified other than -DisconnectMgGraph then any Microsoft Graph connection is retained.  

		.PARAMETER DisconnectMicrosoftTeams
			When specified any detected Microsoft Teams is explicitly disconnected.
			If no -Disconnect* parameter is specified (default) then Microsoft Teams is implicitly disconnected.  
			If any -Disconnect* parameter is specified other than -DisconnectMicrosoftTeams then any Microsoft Teams connection is retained.  

		.PARAMETER DisconnectSPOService
			When specified any detected SharePoint Online is explicitly disconnected.
			If no -Disconnect* parameter is specified (default) then SharePoint Online is implicitly disconnected.  
			If any -Disconnect* parameter is specified other than -DisconnectSPOService then any SharePoint Online connection is retained.  

		.PARAMETER WhatIf
			Displays a message that describes the effect of the command, instead of executing the command.

		.EXAMPLE
			Disconnect-M365Admin

			Disconnects from all of the Microsoft 365 services list in the description.

		.EXAMPLE
			Disconnect-M365Admin -DisconnectExchangeServer

			Disconnects from on-premises Exchange Server, retaining all other detected Microsoft 365 service connections.

		.EXAMPLE
			Disconnect-M365Admin -WhatIf

			Shows detected connection status of Microsoft 365 services without any disconnections.

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

		[Switch] $DisconnectAzAccount,
		[Switch] $DisconnectExchangeOnline,
		[Switch] $DisconnectExchangeServer,
		[Switch] $DisconnectIPPSSession,
		[Switch] $DisconnectMgGraph,
		[Switch] $DisconnectMicrosoftTeams,
		[Switch] $DisconnectSPOService

	)

	Begin {

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

	}

	Process {
		# This block intentionally left blank.
	}

	End {

		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
		#region Clean up.
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

			# If no M365 service (workload) is explicitly specified to be disconnected, then assume to disconnect all/any.
			$disconnectAll = $NULL
			If ( $DisconnectAzAccount -Or $DisconnectExchangeOnline -Or $DisconnectExchangeServer -Or $DisconnectIPPSSession -Or $DisconnectMgGraph -Or $DisconnectMicrosoftTeams -Or $DisconnectSPOService ) {
				# One or more explicitly specified.
				$disconnectAll = $FALSE
			} Else {
				# None were explicitly specified.
				$disconnectAll = $TRUE
			}

			#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
			#region Disconnect from Azure Az PowerShell (Az.Accounts Module)
			#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

			# Check if currently connected.
			$isAzAccountConnected = $NULL
			Try {

				$isAzAccountConnected = [Bool] (Get-AzContext -ErrorAction Stop)

			} Catch {
				$isAzAccountConnected = $FALSE
			}
			Write-Debug "`$isAzAccountConnected: '$isAzAccountConnected'"

			# If connected and disconnect specified - disconnect.
			If ( $isAzAccountConnected ) {
				If ( $disconnectAll -Or $DisconnectAzAccount ) {
					Write-Host "$(Get-Date) Disconnecting from AzAccount."
					
					$pSAzureRmAccount = Disconnect-AzAccount -Confirm:$FALSE -WhatIf:$WhatIf -Verbose:$FALSE -Debug:$FALSE

				} Else {
					Write-Host "$(Get-Date) Connection to AzAccount retained."
				}
			}

			#endregion Disconnect from Azure Az PowerShell (Az.Accounts Module)

			#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
			#region Disconnect from Exchange Online PowerShell V3 (ExchangeOnlineManagement module)
			#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

			# Check if currently connected.
			$isExchangeOnlineConnected = $NULL
			Try {

				$isExchangeOnlineConnected = ( [Bool] (Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.ComputerName -Eq 'outlook.office365.com' } ) -Or [Bool] (Get-ConnectionInformation -ErrorAction Stop) ) # -And $PSItem.State -Eq 'Opened'

			} Catch {
				$isExchangeOnlineConnected = $FALSE
			}
			Write-Debug "`$isExchangeOnlineConnected: '$isExchangeOnlineConnected'"

			# Check if currently connected.
			$isIPConnected = [Bool] (Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And $PSItem.Name -Like 'ExchangeOnlineInternalSession*' -And $PSItem.ComputerName -Like '*.ps.compliance.protection.outlook.com' } ) # -And $PSItem.State -Eq 'Opened'
			Write-Debug "`$isIPConnected: '$isIPConnected'"

			# If connected and disconnect specified - disconnect.
			If ( $isExchangeOnlineConnected -Or $isIPConnected ) {
				If ( $disconnectAll -Or $DisconnectExchangeOnline -Or $DisconnectIPPSSession ) {
					Write-Host "$(Get-Date) Disconnecting from Exchange Online."
					
					Disconnect-ExchangeOnline -Confirm:$FALSE -WhatIf:$WhatIf -Verbose:$FALSE -Debug:$FALSE

				} Else {
					If ( $isExchangeOnlineConnected ) {
						Write-Host "$(Get-Date) Connection to Exchange Online retained."
					}
					If ( $isIPConnected ) {
						Write-Host "$(Get-Date) Connection to Information Protection (Security and Compliance) retained."
					}
				}
			}

			#endregion Disconnect from Exchange Online PowerShell V3 (ExchangeOnlineManagement module)

			#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
			#region Disconnect from on-premises Exchange Server PowerShell (Exchange Management Shell)
			#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

			# Check if currently connected.
			$psSessionExchangeServers = @( Get-PSSession | Where-Object { $PSItem.ConfigurationName -Eq 'Microsoft.Exchange' -And ( $PSItem.Name -Like 'ExchangeSession*' -Or $PSItem.Name -Like 'Session*' ) } ) # -And $PSItem.State -Eq 'Opened'
			Write-Debug "`$psSessionExchangeServers: '$psSessionExchangeServers'"
			$isExchangeServerConnected = [Bool] $psSessionExchangeServers
			Write-Debug "`$isExchangeServerConnected: '$isExchangeServerConnected'"

			# If connected and disconnect specified - disconnect.
			If ( $isExchangeServerConnected ) {
				If ( $disconnectAll -Or $DisconnectExchangeServer ) {
					If ( $Verbose -Or $Debug ) {
						Write-Host "$(Get-Date) Disconnecting from on-premises Exchange server '$psSessionExchangeServers.ComputerName'."
					} Else {
						Write-Host "$(Get-Date) Disconnecting from on-premises Exchange server."
					}
					
					$psSessionExchangeServers |
						Remove-PSSession -Confirm:$FALSE -WhatIf:$WhatIf -Verbose:$FALSE -Debug:$FALSE

				} Else {
					Write-Host "$(Get-Date) Connection to on-premises Exchange server retained."
				}
			}

			#endregion Disconnect from on-premises Exchange Server PowerShell (Exchange Management Shell)

			#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
			#region Disconnect from SharePoint Online Administration Center Management Shell (Microsoft.Online.SharePoint.PowerShell Module)
			#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

			# Check if currently connected.
			$isSpoServiceConnected = $NULL
			Try {

				Get-SPOTenant -ErrorAction Stop | Out-Null

				$isSpoServiceConnected = $TRUE
			} Catch {
				$isSpoServiceConnected = $FALSE
			}
			Write-Debug "`$isSpoServiceConnected: '$isSpoServiceConnected'"

			# If connected and disconnect specified - disconnect.
			If ( $isSpoServiceConnected ) {
				If ( $disconnectAll -Or $DisconnectSPOService ) {
					Write-Host "$(Get-Date) Disconnecting from SharePoint Online."
					
					If ( -Not $WhatIf ) {
						Disconnect-SpoService -Verbose:$FALSE -Debug:$FALSE
					} 

				} Else {
					Write-Host "$(Get-Date) Connection to SharePoint Online retained."
				}
			}

			#endregion Disconnect from SharePoint Online Administration Center Management Shell (Microsoft.Online.SharePoint.PowerShell Module)

			#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
			#region Disconnect from Microsoft Teams (MicrosoftTeams Module)
			#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

			# Check if currently connected.
			$isMicrosoftTeamsConnected = $NULL
			Try {

				Get-CsTenant -ErrorAction Stop | Out-Null

				$isMicrosoftTeamsConnected = $TRUE
			} Catch {
				$isMicrosoftTeamsConnected = $FALSE
			}
			Write-Debug "`$isMicrosoftTeamsConnected: '$isMicrosoftTeamsConnected'"

			# If connected and disconnect specified - disconnect.
			If ( $isMicrosoftTeamsConnected ) {
				If ( $disconnectAll -Or $DisconnectMicrosoftTeams ) {
					Write-Host "$(Get-Date) Disconnecting from Microsoft Teams."
					
					Disconnect-MicrosoftTeams -Confirm:$FALSE -WhatIf:$WhatIf -Verbose:$FALSE -Debug:$FALSE

				} Else {
					Write-Host "$(Get-Date) Connection to Microsoft Teams retained."
				}
			}

			#endregion Disconnect from Microsoft Teams (MicrosoftTeams Module)

			#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10
			#region Disconnect from PowerShell SDK for Microsoft Graph (Microsoft.Graph Module)
			#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10

			# Check if currently connected.
			$isMgGraphConnected = $NULL
			Try {

				$isMgGraphConnected = [Bool] (Get-MgContext -ErrorAction Stop)

			} Catch {
				$isMgGraphConnected = $FALSE
			}
			Write-Debug "`$isMgGraphConnected: '$isMgGraphConnected'"

			# If connected and disconnect specified - disconnect.
			If ( $isMgGraphConnected ) {
				If ( $disconnectAll -Or $DisconnectMgGraph ) {
					Write-Host "$(Get-Date) Disconnecting from MgGraph."
					
					If ( -Not $WhatIf ) {
						$authContext = Disconnect-MgGraph -Verbose:$FALSE -Debug:$FALSE
					}

				} Else {
					Write-Host "$(Get-Date) Connection to MgGraph retained."
				}
			}

			#endregion Disconnect from PowerShell SDK for Microsoft Graph (Microsoft.Graph Module)

		#endregion Clean up.

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
