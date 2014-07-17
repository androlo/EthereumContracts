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
			
			; USAGE: 0 : "autoexecute", 32: params (posting)
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
					[0x40] (ORIGIN)
					(call (- (GAS) 100) @0x0 0 0x20 64 0x20 32)
					
					(unless @0x20 (return 0x20 32))
					
					[0x40] "get"
					[0x60] "marketplace"
					(call (- (GAS) 100) @@0x10 0 0x40 64 0x0 32)
					
					(unless @0x0 (return 0x0 32))
					
					[0x60] "getposter"
					[0x80] (calldataload 32) 
					(call (- (GAS) 100) @0x0 0 0x60 64 0x60 64)
					
					(unless @0x60 (return 0x60 32))
					
					[0x80] "getamount"
					[0xA0] (calldataload 32) 
					(call (- (GAS) 100) @0x0 0 0x80 64 0x80 64)
					
					[0xA0] "getprice"
					[0xC0] (calldataload 32) 
					(call (- (GAS) 100) @0x0 0 0xA0 64 0xA0 64)
					
					;[[0x1002]] @0x60 ;TODO REMOVE
					;[[0x1003]] @0x80 ;TODO REMOVE
					;[[0x1004]] @0xA0 ;TODO REMOVE
					
					; Unless caller = poster, charge the buyer. Otherwise it is the  
					; poster canceling the sale, we just give him the posted sovereigns back.
					(if (= @0x60 (ORIGIN))
						{
							; If poster sent ether along with the transaction, refund him.
							(when (CALLVALUE)
								(call (- (GAS) 100) (ORIGIN) (CALLVALUE) 0x0 0 0x0 0)		
							)
						}
						{
							[0xC0] (* @0xA0 1ether)
					
							; Buyer did not send enough ether. Cancel.
							(when (< (CALLVALUE) @0xC0)
								{
									[0x0] 0
									(return 0x0 32)	
								}
							)
							
							[0x40] (- (CALLVALUE) @0xC0)
							
							;[[0x1007]] @0x40 ;TODO REMOVE
							
							; Refund any excess ether sent along with the transaction.
							(when @0x40
								{
									(call (- (GAS) 100) (ORIGIN) @0x40 0x0 0 0x0 0)		
								}
							)
							
							(call (- (GAS) 100) @0x60 @0xC0 0x0 0 0x0 0)
						}
					)
					
					[0x40] "addtokens"
					[0x60] @0x80
					(call (- (GAS) 100) @0x20 0 0x40 64 0x40 32)
					
					;[[0x1008]] @0x20 ;TODO REMOVE
					;[[0x1009]] @0x40 ;TODO REMOVE
					
					[0x40] "remove"
					[0x60] (calldataload 32)
					(call (- (GAS) 100) @0x0 0 0x40 64 0x40 32)
										
					[0x0] 1
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