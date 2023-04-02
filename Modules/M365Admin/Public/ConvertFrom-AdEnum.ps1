Function ConvertFrom-AdEnum {
	<#
		.SYNOPSIS
			Convert Active Directory attributes with enumeration values into a pair of description and explanation strings.
			
		.DESCRIPTION
			Return the composite description and explanation strings from an enumeration hashtable.  
			Treat $Value is a bitmask defined as flags in the enumeration hashtable, and for each enumeration flag

		.PARAMETER Value <Long[]>
			Active Directory enumeration flag value. Can be either Int32 or Int64.  
			
		.PARAMETER Table <HashTable>
			$table = @{ 
				[Int32] 0x00000001 = @( 'Description1', 'Explanation1' ) # 1
				[Int32] 0x80000000 = @( 'Description2', 'Explanation2' ) # -2147483648
				...
			}
			
			or 
			
			$table = @{ 
				[Int64] 0x0000000000000001L = @( 'Description1', 'Explanation1' ) # 1
				[Int64] 0x0000000080000000L = @( 'Description2', 'Explanation2' ) # 2147483648
				[Int64] 0x8000000000000000L = @( 'Description2', 'Explanation2' ) # -9223372036854775808
				...
			}
			
		.PARAMETER SimpleMatch <Switch>
			When enabled collect descriptions when the value is an exact match with a table entry.  
			When not enabled collect descriptions for all table entry's bitmask that matches the value.  
			
		.PARAMETER IntraValueDelimiter <String>
			The string used to joing array properties values together.  Default is a semicolon (;).  Use "`n" (with the double-quotes) for a newline.  
		
	#>
	Param (
		[Long[]] $Value,
		[HashTable] $Table,
		[Switch] $SimpleMatch,
		[String] $IntraValueDelimiter = ';'
	)

	Begin {
		
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12
		#region Define Active Directory/Exchange enumerations.
		#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+---10----+---11----+---12
		
		# Group-Type flags https://docs.microsoft.com/en-us/windows/win32/adschema/a-grouptype (GROUP_TYPE_*)
		# https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-adts/11972272-09ec-4a42-bf5e-3e99b321cf55
		$GroupTypeDescriptions = @{ # adminDisplayName:Group-Type; lDAPDisplayName:groupType; attributeSyntax:2.5.5.9 (INTEGER) 
			#MatchType = 'Bitmask'
			[Int32] 0x00000001 = @( 'BUILTIN_LOCAL_GROUP', 'Specifies a group that is created by the system.' ) # 1
			[Int32] 0x00000002 = @( 'ACCOUNT_GROUP', 'Specifies a group with global scope.' ) # 2 
			[Int32] 0x00000004 = @( 'RESOURCE_GROUP', 'Specifies a group with domain local scope.' ) # 4
			[Int32] 0x00000008 = @( 'UNIVERSAL_GROUP', 'Specifies a group with universal scope.' ) # 8
			[Int32] 0x00000010 = @( 'APP_BASIC_GROUP', 'Specifies an APP_BASIC group for Windows Server Authorization Manager.' ) # 16
			[Int32] 0x00000020 = @( 'APP_QUERY_GROUP', 'Specifies an APP_QUERY group for Windows Server Authorization Manager.' ) # 32
			[Int32] 0x80000000 = @( 'SECURITY_ENABLED', 'Specifies a security group. If this flag is not set, then the group is a distribution group.' ) # -2147483648
		}
		If ( $Debug ) {
			$GroupTypeDescriptions.Keys |
				Sort-Object |
				ForEach-Object {
					Write-Debug "`$GroupTypeDescriptions[$PSItem]`:,$($GroupTypeDescriptions[$PSItem])"
				}
		}

		# Instance-Type enum https://docs.microsoft.com/en-us/windows/win32/adschema/a-instancetype
		$InstanceTypeDescriptions = @{ # adminDisplayName:Instance-Type; lDAPDisplayName:instanceType; attributeSyntax:2.5.5.9 (INTEGER) 
			#MatchType = 'Bitmask'
			[Int32] 0x00000001 = @( '', 'The head of naming context.' ) # 1
			[Int32] 0x00000002 = @( '', 'This replica is not instantiated.' ) # 2 
			[Int32] 0x00000004 = @( '', 'The object is writable on this directory.' ) # 4
			[Int32] 0x00000008 = @( '', 'The naming context above this one on this directory is held.' ) # 8
			[Int32] 0x00000010 = @( '', 'The naming context is in the process of being constructed for the first time by using replication.' ) # 16
			[Int32] 0x00000020 = @( '', 'The naming context is in the process of being removed from the local DSA.' ) # 32
		}
		If ( $Debug ) {
			$InstanceTypeDescriptions.Keys |
				Sort-Object |
				ForEach-Object {
					Write-Debug "`$InstanceTypeDescriptions[$PSItem]`:,$($InstanceTypeDescriptions[$PSItem])"
				}
		}

		# msExchRecipientDisplayType enum 
		# http://www.mistercloudtech.com/2016/05/18/reference-to-msexchrecipientdisplaytype-msexchrecipienttypedetails-and-msexchremoterecipienttype-values
		# https://answers.microsoft.com/en-us/msoffice/forum/all/recipient-type-values/7c2620e5-9870-48ba-b5c2-7772c739c651
		#	Exchange Server: msExchRecipientDisplayType
		#	Exchange Online: RecipientType
		$msExchRecipientDisplayTypeDescriptions = @{ # adminDisplayName:ms-Exch-Recipient-Display-Type; lDAPDisplayName:msExchRecipientDisplayType; attributeSyntax:2.5.5.9 (INTEGER)
			#MatchType = 'Simple'
			[Int32] 0x00000000 = @( 'MailboxUser', 'Mailbox User' ) # 0
			[Int32] 0x00000001 = @( 'MailUniversalDistributionGroup', 'Distribution Group' ) # 1
			[Int32] 0x00000002 = @( 'PublicFolder', 'Public Folder' ) # 2
			[Int32] 0x00000003 = @( 'DynamicDistributionGroup', 'Dynamic Distribution Group' ) # 3
			[Int32] 0x00000004 = @( 'Organization', 'Organization' ) # 4
			[Int32] 0x00000005 = @( 'PrivateDistributionList', 'Private Distribution List' ) # 5
			[Int32] 0x00000006 = @( 'MailContact', 'Remote Mail User' ) # 6
			[Int32] 0x00000007 = @( 'RoomMailbox', 'Conference Room Mailbox' ) # 7
			[Int32] 0x00000008 = @( 'EquipmentMailbox', 'Equipment Mailbox' ) # 8
			[Int32] 0x0000000A = @( 'ArbitrationMailbox', 'ArbitrationMailbox' ) # 10
			[Int32] 0x0000000B = @( 'MailboxPlan', 'Mailbox Plan' ) # 11
			[Int32] 0x0000000C = @( 'LinkedUser', 'Linked User' ) # 12
			[Int32] 0x0000000F = @( 'RoomList', 'Room List' ) # 15
			[Int32] 0x40000000 = @( 'ACLableMailboxUser', 'ACL able Mailbox User' ) # 1073741824
			[Int32] 0x40000009 = @( 'SecurityDistributionGroup', 'Security Distribution Group' ) # 1073741833
			[Int32] 0x80000006 = @( 'SyncedMailboxUser', 'Synced Mailbox User' ) # -2147483642
			[Int32] 0x80000101 = @( 'SyncedUDGasUDG', 'Synced UDG as UDG' ) # -2147483391
			[Int32] 0x80000106 = @( 'SyncedUDGasContact', 'Synced UDG as Contact' ) # -2147483386
			[Int32] 0x80000206 = @( 'SyncedPublicFolder', 'Synced Public Folder' ) # -2147483130
			[Int32] 0x80000306 = @( 'SyncedDynamicDistributionGroup', 'Synced Dynamic Distribution Group' ) # -2147482874
			[Int32] 0x80000606 = @( 'SyncedRemoteMailUser', 'Synced Remote Mail User' ) # -2147482106
			[Int32] 0x80000706 = @( 'SyncedConferenceRoomMailbox', 'Synced Conference Room Mailbox' ) # -2147481850
			[Int32] 0x80000806 = @( 'SyncedEquipmentMailbox', 'Synced Equipment Mailbox' ) # -2147481594
			[Int32] 0x80000901 = @( 'SyncedUSGasUDG', 'Synced USG as UDG' ) # -2147481343
			[Int32] 0x80000906 = @( 'SyncedUSGasContact', 'Synced USG as Contact' ) # -2147481338
			[Int32] 0xC0000006 = @( 'ACLableSyncedMailboxUser', 'ACL able Synced Mailbox User' ) # -1073741818
			[Int32] 0xC0000606 = @( 'ACLableSyncedRemoteMailUser', 'ACL able Synced Remote Mail User' ) # -1073740282
			[Int32] 0xC0000906 = @( 'ACLableSyncedUSGasContact', 'ACL able Synced USG as Contact' ) # -1073739514
			[Int32] 0xC0000909 = @( 'SyncedUSGasUSG', 'Synced USG as USG' ) # -1073739511
		}
		If ( $Debug ) {
			$msExchRecipientDisplayTypeDescriptions.Keys |
				Sort-Object |
				ForEach-Object {
					Write-Debug "`$msExchRecipientDisplayTypeDescriptions[$PSItem]`:,$($msExchRecipientDisplayTypeDescriptions[$PSItem])"
				}
		}

		# msExchRecipientTypeDetails enumeration
		# http://www.mistercloudtech.com/2016/05/18/reference-to-msexchrecipientdisplaytype-msexchrecipienttypedetails-and-msexchremoterecipienttype-values
		# https://docs.microsoft.com/en-us/previous-versions/office/exchange-server-api/ff344739(v=exchg.150)
		# https://github.com/felsokning/CSharp/blob/master/Public.CSharp.Research/Public.Exchange.Research/Objects/TypeEnums.cs
		#	Exchange Server: msExchRecipientTypeDetails
		#	Exchange Online: RecipientTypeDetails
		$msExchRecipientTypeDetailsDescriptions = @{ # adminDisplayName:ms-Exch-Recipient-Type-Details; lDAPDisplayName:msExchRecipientTypeDetails; attributeSyntax:2.5.5.16 (LargeInteger)
			#MatchType = 'Bitmask'
			[Int64] 0x0000000000000001L = @( 'UserMailbox', 'User Mailbox' ) # 1
			[Int64] 0x0000000000000002L = @( 'LinkedMailbox', 'Linked Mailbox' ) # 2
			[Int64] 0x0000000000000004L = @( 'SharedMailbox', 'Shared Mailbox' ) # 4
			[Int64] 0x0000000000000008L = @( 'LegacyMailbox', 'Legacy Mailbox' ) # 8
			[Int64] 0x0000000000000010L = @( 'RoomMailbox', 'Room Mailbox' ) # 16
			[Int64] 0x0000000000000020L = @( 'EquipmentMailbox', 'Equipment Mailbox' ) # 32
			[Int64] 0x0000000000000040L = @( 'MailContact', 'Mail Contact' ) # 64
			[Int64] 0x0000000000000080L = @( 'MailUser', 'Mail User' ) # 128
			[Int64] 0x0000000000000100L = @( 'MailUniversalDistributionGroup', 'Mail-Enabled Universal Distribution Group' ) # 256
			[Int64] 0x0000000000000200L = @( 'MailNonUniversalGroup', 'Mail-Enabled Non-Universal Distribution Group' ) # 512
			[Int64] 0x0000000000000400L = @( 'MailUniversalSecurityGroup', 'Mail-Enabled Universal Security Group' ) # 1024
			[Int64] 0x0000000000000800L = @( 'DynamicDistributionGroup', 'Dynamic Distribution Group' ) # 2048
			[Int64] 0x0000000000001000L = @( 'PublicFolder', 'Public Folder' ) # 4096
			[Int64] 0x0000000000002000L = @( 'SystemAttendantMailbox', 'System Attendant Mailbox' ) # 8192
			[Int64] 0x0000000000004000L = @( 'SystemMailbox', 'System Mailbox' ) # 16384
			[Int64] 0x0000000000008000L = @( 'MailForestContact', 'Cross-Forest Mail Contact' ) # 32768
			[Int64] 0x0000000000010000L = @( 'User', 'User' ) # 65536
			[Int64] 0x0000000000020000L = @( 'Contact', 'Contact' ) # 131072
			[Int64] 0x0000000000040000L = @( 'UniversalDistributionGroup', 'Universal Distribution Group' ) # 262144
			[Int64] 0x0000000000080000L = @( 'UniversalSecurityGroup', 'Universal Security Group' ) # 524288
			[Int64] 0x0000000000100000L = @( 'NonUniversalGroup', 'Non-Universal Group' ) # 1048576
			[Int64] 0x0000000000200000L = @( 'DisabledUser', 'Disabled User' ) # 2097152
			[Int64] 0x0000000000400000L = @( 'MicrosoftExchange', 'Microsoft Exchange' ) # 4194304
			[Int64] 0x0000000000800000L = @( 'ArbitrationMailbox', 'Arbitration Mailbox' ) # 8388608
			[Int64] 0x0000000001000000L = @( 'MailboxPlan', 'Mailbox Plan' ) # 16777216
			[Int64] 0x0000000002000000L = @( 'LinkedUser', 'Linked User' ) # 33554432
			[Int64] 0x0000000010000000L = @( 'RoomList', 'Room List' ) # 268435456
			[Int64] 0x0000000020000000L = @( 'DiscoveryMailbox', 'Discovery Mailbox' ) # 536870912
			[Int64] 0x0000000040000000L = @( 'RoleGroup', 'Role Group' ) # 1073741824
			[Int64] 0x0000000080000000L = @( 'RemoteUserMailbox', 'Remote User Mailbox' ) # 2147483648
			[Int64] 0x0000000100000000L = @( 'Computer', '' ) # 4294967296
			[Int64] 0x0000000200000000L = @( 'RemoteRoomMailbox', '' ) # 8589934592
			[Int64] 0x0000000400000000L = @( 'RemoteEquipmentMailbox', '' ) # 17179869184
			[Int64] 0x0000000800000000L = @( 'RemoteSharedMailbox', '' ) # 34359738368
			[Int64] 0x0000001000000000L = @( 'PublicFolderMailbox', '' ) # 68719476736
			[Int64] 0x0000002000000000L = @( 'TeamMailbox', 'Team Mailbox' ) # 137438953472
			[Int64] 0x0000004000000000L = @( 'RemoteTeamMailbox', '' ) # 274877906944
			[Int64] 0x0000008000000000L = @( 'MonitoringMailbox', '' ) # 549755813888
			[Int64] 0x0000010000000000L = @( 'GroupMailbox', '' ) # 1099511627776
			[Int64] 0x0000020000000000L = @( 'LinkedRoomMailbox', '' ) # 2199023255552
			[Int64] 0x0000040000000000L = @( 'AuditLogMailbox', '' ) # 4398046511104
			[Int64] 0x0000080000000000L = @( 'RemoteGroupMailbox', '' ) # 8796093022208
			[Int64] 0x0000100000000000L = @( 'SchedulingMailbox', '' ) # 17592186044416
			[Int64] 0x0000200000000000L = @( 'GuestMailUser', '' ) # 35184372088832
			[Int64] 0x0000400000000000L = @( 'AuxAuditLogMailbox', '' ) # 70368744177664
			[Int64] 0x0000800000000000L = @( 'SupervisoryReviewPolicyMailbox', '' ) # 140737488355328
		}
		If ( $Debug ) {
			$msExchRecipientTypeDetailsDescriptions.Keys |
				Sort-Object |
				ForEach-Object {
					Write-Debug "`$msExchRecipientTypeDetailsDescriptions[$PSItem]`:,$($msExchRecipientTypeDetailsDescriptions[$PSItem])"
				}
		}

		# msExchRemoteRecipientType enumeration
		# http://www.mistercloudtech.com/2016/05/18/reference-to-msexchrecipientdisplaytype-msexchrecipienttypedetails-and-msexchremoterecipienttype-values
		# https://docs.microsoft.com/en-us/previous-versions/office/exchange-server-api/ff443320(v=exchg.150)
		# https://answers.microsoft.com/en-us/msoffice/forum/all/recipient-type-values/7c2620e5-9870-48ba-b5c2-7772c739c651?msclkid=9244a137c59d11ecadddb3f79dd20884
		#	Exchange Server: msExchRemoteRecipientType
		$msExchRemoteRecipientTypeDescriptions = @{ # adminDisplayName:ms-Exch-Remote-Recipient-Type; lDAPDisplayName:msExchRemoteRecipientType; attributeSyntax:2.5.5.16 (LargeInteger)
			#MatchType = 'Bitmask'
			[Int64] 0x0000000000000001L = @( 'ProvisionMailbox', '' ) # 1
			[Int64] 0x0000000000000002L = @( 'ProvisionArchive', '' ) # 2 
			[Int64] 0x0000000000000004L = @( 'Migrated', '' ) # 4
			[Int64] 0x0000000000000008L = @( 'DeprovisionMailbox', '' ) # 8
			[Int64] 0x0000000000000010L = @( 'DeprovisionArchive', '' ) # 16
			[Int64] 0x0000000000000020L = @( 'RoomMailbox', '' ) # 32
			[Int64] 0x0000000000000040L = @( 'EquipmentMailbox', '' ) # 64
			[Int64] 0x0000000000000060L = @( 'SharedMailbox', '' ) # 96
		}
		If ( $Debug ) {
			$msExchRemoteRecipientTypeDescriptions.Keys |
				Sort-Object |
				ForEach-Object {
					Write-Debug "`$msExchRemoteRecipientTypeDescriptions[$PSItem]`:,$($msExchRemoteRecipientTypeDescriptions[$PSItem])"
				}
		}
		
		# SAM-Account-Type enum 
		# https://docs.microsoft.com/en-us/windows/win32/adschema/a-samaccounttype (SAM_*)
		$SAMAccountTypeDescriptions = @{ # adminDisplayName:SAM-Account-Type; lDAPDisplayName:sAMAccountType; attributeSyntax:2.5.5.9 (INTEGER)
			#MatchType = 'Simple'
			#[Int32] 0x00000000 = @( 'DOMAIN_OBJECT', '' ) # 0
			[Int32] 0x10000000 = @( 'GROUP_OBJECT', '' ) # 268435456
			[Int32] 0x10000001 = @( 'NON_SECURITY_GROUP_OBJECT', '' ) # 268435457
			[Int32] 0x20000000 = @( 'ALIAS_OBJECT', '' ) # 536870912
			[Int32] 0x20000001 = @( 'NON_SECURITY_ALIAS_OBJECT', '' ) # 536870913
			[Int32] 0x30000000 = @( 'NORMAL_USER_ACCOUNT', '' ) # 805306368
			[Int32] 0x30000001 = @( 'MACHINE_ACCOUNT', '' ) # 805306369
			[Int32] 0x30000002 = @( 'TRUST_ACCOUNT', '' ) # 805306370
			[Int32] 0x40000000 = @( 'APP_BASIC_GROUP', '' ) # 1073741824
			[Int32] 0x40000001 = @( 'APP_QUERY_GROUP', '' ) # 1073741825
			[Int32] 0x7fffffff = @( 'ACCOUNT_TYPE_MAX', '' ) # 2147483647
		}
		If ( $Debug ) {
			$SAMAccountTypeDescriptions.Keys |
				Sort-Object |
				ForEach-Object {
					Write-Debug "`$SAMAccountTypeDescriptions[$PSItem]`:,$($SAMAccountTypeDescriptions[$PSItem])"
				}
		}
		
		# User-Account-Control bits https://docs.microsoft.com/en-us/windows/win32/adschema/a-useraccountcontrol (ADS_UF_*)
		# https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-adts/dd302fd1-0aa7-406b-ad91-2a6b35738557
		$UserAccountControlDescriptions = @{ # adminDisplayName:User-Account-Control; lDAPDisplayName:userAccountControl; attributeSyntax:2.5.5.9 (INTEGER)
			#MatchType = 'Bitmask'
			[Int32] 0x00000001 = @( 'SCRIPT', 'The logon script is executed.' ) # 1
			[Int32] 0x00000002 = @( 'ACCOUNTDISABLE', 'The user account is disabled.' ) # 2
			[Int32] 0x00000008 = @( 'HOMEDIR_REQUIRED', 'The home directory is required.' ) # 8
			[Int32] 0x00000010 = @( 'LOCKOUT', 'The account is currently locked out.' ) # 16
			[Int32] 0x00000020 = @( 'PASSWD_NOTREQD', 'No password is required.' ) # 32
			[Int32] 0x00000040 = @( 'PASSWD_CANT_CHANGE', 'The user cannot change the password.' ) # 64
			[Int32] 0x00000080 = @( 'ENCRYPTED_TEXT_PASSWORD_ALLOWED', 'The user can send an encrypted password.' ) # 128
			[Int32] 0x00000100 = @( 'TEMP_DUPLICATE_ACCOUNT', 'This is an account for users whose primary account is in another domain. This account provides user access to this domain, but not to any domain that trusts this domain. Also known as a local user account.' ) # 256
			[Int32] 0x00000200 = @( 'NORMAL_ACCOUNT', 'This is a default account type that represents a typical user.' ) # 512
			[Int32] 0x00000800 = @( 'INTERDOMAIN_TRUST_ACCOUNT', 'This is a permit to trust account for a system domain that trusts other domains.' ) # 2048
			[Int32] 0x00001000 = @( 'WORKSTATION_TRUST_ACCOUNT', 'This is a computer account for a computer that is a member of this domain.' ) # 4096
			[Int32] 0x00002000 = @( 'SERVER_TRUST_ACCOUNT', 'This is a computer account for a system backup domain controller that is a member of this domain.' ) # 8192
			[Int32] 0x00010000 = @( 'DONT_EXPIRE_PASSWD', 'The password for this account will never expire.' ) # 65536
			[Int32] 0x00020000 = @( 'MNS_LOGON_ACCOUNT', 'This is an MNS logon account.' ) # 131072
			[Int32] 0x00040000 = @( 'SMARTCARD_REQUIRED', 'The user must log on using a smart card.' ) # 262144
			[Int32] 0x00080000 = @( 'TRUSTED_FOR_DELEGATION', 'The service account (user or computer account), under which a service runs, is trusted for Kerberos delegation. Any such service can impersonate a client requesting the service.' ) # 524288
			[Int32] 0x00100000 = @( 'NOT_DELEGATED', 'The security context of the user will not be delegated to a service even if the service account is set as trusted for Kerberos delegation.' ) # 1048576
			[Int32] 0x00200000 = @( 'USE_DES_KEY_ONLY', 'Restrict this principal to use only Data Encryption Standard (DES) encryption types for keys.' ) # 2097152
			[Int32] 0x00400000 = @( 'DONT_REQUIRE_PREAUTH', 'This account does not require Kerberos pre-authentication for logon.' ) # 4194304
			[Int32] 0x00800000 = @( 'PASSWORD_EXPIRED', 'The user password has expired. This flag is created by the system using data from the Pwd-Last-Set attribute and the domain policy.' ) # 8388608
			[Int32] 0x01000000 = @( 'TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION', 'The account is enabled for delegation. This is a security-sensitive setting; accounts with this option enabled should be strictly controlled. This setting enables a service running under the account to assume a client identity and authenticate as that user to other remote servers on the network.' ) # 16777216
			[Int32] 0x02000000 = @( 'NO_AUTH_DATA_REQUIRED', 'Used by the Kerberos protocol. This bit indicates that when the Key Distribution Center (KDC) is issuing a service ticket for this account, the Privilege Attribute Certificate (PAC) MUST NOT be included. For more information, see [RFC4120].' ) # 33554432
			[Int32] 0x04000000 = @( 'PARTIAL_SECRETS_ACCOUNT', 'The account is a read-only domain controller (RODC). This is a security-sensitive setting. Removing this setting from an RODC compromises security on that server.' ) # 67108864
		}
		If ( $Debug ) {
			$UserAccountControlDescriptions.Keys |
				Sort-Object |
				ForEach-Object {
					Write-Debug "`$UserAccountControlDescriptions[$PSItem]`:,$($UserAccountControlDescriptions[$PSItem])"
				}
		}
		
	}


	Process {
		
		$Value |
			ForEach-Object { 
				$valueItem = $PSItem
				
				# Initialize metrics.
				$description = @()
				$explanation = @()
				
				# For each enumeration hashtable key...
				$Table.Keys | 
					Sort-Object | 
					ForEach-Object { 
						
						If ( $SimpleMatch ) { 
							
							# ...if this simple matches the Value, then get the description and explanation.  
							If ( $valueItem -Eq $PSItem ) { 					
								$description += $Table[ $PSItem ][0] 
								$explanation += $Table[ $PSItem ][1] 
							} 
							
						} Else {
						
							# ...if this bitmask matches (Binary And) the Value, then collect the description and explanation.  
							If ( ( $valueItem -BAnd $PSItem ) -Eq $PSItem ) { 					
								$description += $Table[ $PSItem ][0] 
								$explanation += $Table[ $PSItem ][1] 
							} 
							
						}
					} 
				
				# If no matches, return the original value.  
				If ( -Not $description ) {
					$description += $valueItem
				}
				
				# Write composite results.  
				Write-Output ( [PSCustomObject] @{
					Description = $description -Join $IntraValueDelimiter
					Explanation = $explanation -Join $IntraValueDelimiter
				} )
			}
			
	}
	
}