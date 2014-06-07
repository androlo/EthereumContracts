{
	
	;body section
	[0x0](LLL
		{
			; USAGE: 0 : "setdoug", 32 : dougaddress
			; RETURNS: -
			; NOTES: Set the DOUG address. This can only be done once.
			; INTERFACE Factory<?>
			(when (= (calldataload 0) "setdoug") 
				{
					(when @@0x10
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					[[0x10]] (calldataload 32)
					[0x0] 1
					(return 0x0 32)
				}
			)
			
			; Cancel unless doug is set.
			(unless @@0x10
				{
					[0x0] 0
					(return 0x0 32)
				}
			)
			
			; USAGE: 0 : "isautopass"
			; RETURNS: 1 if autopass, otherwise 0.
			; INTERFACE Poll
			(when (= (calldataload 0) "isautopass") 
				{
					[0x0] 1
					(return 0x0 32)
				}
			)
			
			; USAGE: 0 : "init"
			; RETURNS: 1 if success, 0 otherwise.
			; NOTES: Initialize the poll.
			; INTERFACE Poll
			(when (= (calldataload 0) "init") 
				{
					[0x0] 1
					(return 0x0 32)
				}
			)
			
			; USAGE: 0 : "generate"
			; RETURNS: Pointer to a Poll contract.
			; INTERFACE Poll
			(when (= (calldataload 0) "get")
				{
					[0x0] (ADDRESS)
					(return 0x0 32)
				}
			)
			
			; USAGE: 0 : "doautopass", 32 : user address
			; RETURNS: 1 if successful, otherwise 0.
			; INTERFACE Poll
			(when (= (calldataload 0) "doautopass") 
				{
					
					[0x0] "get"
					[0x20] "users"
					(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
					
					; If no user contract - cancel.
					(unless @0x0 (return 0x0 32) )
					
					[0x20] "getuserdataaddr"
					[0x40] (calldataload 32)
					(call (- (GAS) 100) @0x0 0 0x20 64 0x20 32)
					
					; If no such user - cancel.
					(unless @0x20 (return 0x20 32) )
					
					[0x40] "hasuser"
					[0x60] "Citizens"
					(call (- (GAS) 100) @0x20 0 0x40 64 0x20 32)
					
					; If user is not in group - cancel.
					(unless @0x20 (return 0x20 32) )
					
					[0x0] 1
					(return 0x0 32)
				}
			)
					
			[0x0] "get"
			[0x20] "polltypes"
			(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
			
			; Only 'polltypes' can do this. Suicide the generator contract.
			(when (&& (= (CALLER) @0x40) (= (calldataload 0) "kill")) (suicide (CALLER)) )
					
		} 0x20 )
	(return 0x20 @0x0) ;Return body
}