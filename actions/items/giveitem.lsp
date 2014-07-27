;INIT
{
	[[0x8]] 1; Type (0 mixed, 1 auto only, 2 vote only)
	[[0x9]] "autopass" ; Default vote type
	
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
			
			; USAGE: 0 : "gettype"
			; RETURNS: The type of poll this action supports.
			; INTERFACE Factory<Action>
			(when (= (calldataload 0 ) "gettype") 
				{
					[0x0] 1
					(return 0x0 32)
				}
			)
			
			; USAGE: 0 : "getpoll"
			; RETURNS: The hard-coded poll type.
			; INTERFACE Factory<Action>
			(when (= (calldataload 0 ) "getpoll") 
				{
					[0x0] @@0x9
					(return 0x0 32)
				}
			)
			
			[0x0] "get"
			[0x20] "actiontypes"
			(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
			
			; USAGE: 0 : "get", 32 : autopass (1 or 0)
			; RETURNS: Pointer to an Action contract.
			; INTERFACE Factory<Action>
			(when (= (calldataload 0) "get")
				{
					(unless (= (CALLER) @0x0) 
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					[0x0] (ADDRESS)
					(return 0x0 32)
				}
			)
			
			; USAGE: 0 : "setpoll", 32 : "pollname"
			; RETURNS: 1 if successful, 0 if not.
			; NOTES: Set the poll that should be used. Must be done by actiontypes.
			; INTERFACE Action
			(when (= (calldataload 0) "setpoll") 
				{
					(unless (= @0x0 (CALLER)) ; Only actiontypes can do this.
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					; Set the new poll.
					[[0x9]] (calldataload 32)
					[0x0] 1
					(return 0x0 32)
				}
			)
			
			; USAGE: 0 : "autoexecute", 32: params (item name, amount, recipient address)
			; RETURNS: 1 if successful, 0 if not.
			; NOTES: Autoexecutes the action
			; INTERFACE Action
			(when (= (calldataload 0) "autoexecute")
				{					
					[0x0] "get"
					[0x20] "actions"
					(call (- (GAS) 100) @@0x10 0 0x0 64 0x20 32)
					
					; Only the actions contract can execute.
					(unless (= @0x20 (CALLER)) 
						{
							[0x0] 0
							(return 0x0 0)
						}
					)
					
					[0x0] "get"
					[0x20] "users"
					(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
					
					(unless @0x0 (return 0x0 32))
					
					[0x20] "getuserdataaddr"
					[0x40] (calldataload 96)
					(call (- (GAS) 100) @0x0 0 0x20 64 0x20 32)
					
					(unless @0x20 (return 0x20 32))
					
					[0x40] "get"
					[0x60] "items"
					(call (- (GAS) 100) @@0x10 0 0x40 64 0x40 32)
					
					(unless @0x40 (return 0x40 32))
					
					[0x60] "getitemfull"
					[0x80] (calldataload 32)
					(call (- (GAS) 100) @0x40 0 0x60 64 0x60 128)
					;0x60 -> type
					;0x80 -> stacksize
					;0xA0 -> contract address
					;0xC0 -> creator/owner address
										
					(unless @0x60 (return 0x60 32));If no such item exists - cancel
					
					[[0x1007]] (ORIGIN) ; TODO Remove
					
					(unless (= (ORIGIN) @0xC0) ; Unless the giver owns the item - cancel.
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					
					;Now go to user
					[0x0] "getholdings"
					(call (- (GAS) 100) @0x20 0 0x0 32 0x0 32)
					
					(when @0x80 
						{
							[0x20] "getitem"
							[0x40] (calldataload 32)
							(call (- (GAS) 100) @0x0 0 0x20 64 0x20 32)
							(unless (<= (+ @0x20 (calldataload 64)) @0x80)
								{
									[0x0] 0
									(return 0x0 32)
								}
							)
						}
					)
					
					[0x20] "additem"
					[0x40] (calldataload 32)
					[0xC0] @0xA0
					[0xA0] @0x60 				
					[0x60] (calldataload 64)
					[0x80] "personal"
					(call (- (GAS) 100) @0x0 0 0x20 160 0x0 32)
					
					(return 0x0 32)
				}
			)
			
			; Only 'actiontypes'can do this.
			(when (&& (= (calldataload 0) "kill") (= (CALLER) @0x0) ) (suicide (CALLER)) )
			
			[0x0] 0
			(return 0x0 32)
			
		} 0x20 )
	(return 0x20 @0x0) ;Return body
}