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
			
			; USAGE: 0 : "autoexecute", 32: params (houseaddress,useraddress)
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
					[0x40] (calldataload 64)
					(call (- (GAS) 100) @0x0 0 0x20 64 0x20 32) ; Buyer data at 0x20
					
					(unless @0x20 (return 0x20 32))
					
					[0x40] "get"
					[0x60] "realestate"
					(call (- (GAS) 100) @@0x10 0 0x40 64 0x40 32) ; RE at 0x40
					
					(unless @0x40 (return 0x40 32))
										
					[0x60] "getowner"
					[0x80] (calldataload 32) 
					(call (- (GAS) 100) @0x40 0 0x60 64 0x60 32) ; Seller at 0x60
					
					(when (= @0x60 (calldataload 64)) ; Don't buy from yourself.
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
										
					(if @0x60 
						{
						
							[0x80] "getprice"
							[0xA0] (calldataload 32) 
							(call (- (GAS) 100) @0x40 0 0x80 64 0x80 32) ; Price at 0x80
							
							(unless @0x80 ; If price is 0 then it is not for sale.
								{
									[0x0] 0
									(return 0x0 32)
								}
							)
						}
						{
							[0x60] "gettype"
							[0x80] (calldataload 32) 
							(call (- (GAS) 100) @0x40 0 0x60 64 0x60 64) ; Price at 0x80
							[0x60] 0
						}
					)
					
					[0xA0] "gettokens"
					(call (- (GAS) 100) @0x20 0 0xA0 32 0xA0 32) ; Buyer tokens at 0xA0
										
					(when (< @0xA0 @0x80) ; Must have more tokens then the cost. 
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					
					; Buyer has enough money. Start the transaction.
					(when @0x60 
						{
							[0xC0] "getuserdataaddr"
							[0xE0] @0x60
							(call (- (GAS) 100) @0x0 0 0xC0 64 0xC0 32) ; Get seller data to 0xC0
							
							(unless @0xC0 (return 0xC0 32) )			
						}
					)
					
					[0xE0] "removetokens"
					[0x100] @0x80
					(call (- (GAS) 100) @0x20 0 0xE0 64 0xE0 32)
										
					; Buyer has enough money. Start the transaction.
					(when @0x60 
						{
							[0xE0] "addtokens"
							[0x100] @0x80
							(call (- (GAS) 100) @0xC0 0 0xE0 64 0xE0 32)
							
							; Money changed hands. Now transfer ownership.
					
							[0xE0] "getholdings"
							(call (- (GAS) 100) @0xC0 0 0xE0 32 0x0 32)
							
							[0xE0] "removeitem"
							[0x100] (calldataload 32)
							[0x120] 1
							(call (- (GAS) 100) @0x0 0 0xE0 96 0x0 32)				
						}
					)
					[0xE0] "getholdings"
					(call (- (GAS) 100) @0x20 0 0xE0 32 0xE0 32) ; Get buyer holdings to 0xE0
					
					
					[0x0] @0x40 ; Switch RE address to 0x0
										
					[0x20] "gettype"
					[0x40] (calldataload 32)
					(call (- (GAS) 100) @0x0 0 0x20 64 0x20 64)
					
					[0x100] @0x60
					
					; Add to user holdings
					[0x40] "additem"
					[0x60] (calldataload 32)
					[0x80] 1
					[0xA0] "realestate"
					[0xC0] @0x20
					(call (- (GAS) 100) @0xE0 0 0x40 160 0x20 32)
					
					(if @0x100
						{
							; Transfer ownership
							[0x20] "transferownership"
							[0x40] (calldataload 32)
							[0x60] (calldataload 64)
							(call (- (GAS) 100) @0x0 0 0x20 96 0x20 32)		
						}
						{
							; Set owner
							[0x20] "setowner"
							[0x40] (calldataload 32)
							[0x60] (calldataload 64)
							(call (- (GAS) 100) @0x0 0 0x20 96 0x20 32)	
						}
					)
					
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