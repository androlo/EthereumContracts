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
					[[0x999]] (ORIGIN) ;TODO REMOVE
					[[0x1000]] (calldataload 32) ;TODO REMOVE
					
					[0x0] "get"
					[0x20] "actions"
					(call (- (GAS) 100) @@0x10 0 0x0 64 0x20 32)
					
					; Only the actions contract can execute.
					(unless (= @0x20 (CALLER)) 
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					
					[0x0] "get"
					[0x20] "users"
					(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
					
					(unless @0x0 (return 0x0 32))
					
					[0x20] "get"
					[0x40] "marketplace"
					(call (- (GAS) 100) @@0x10 0 0x20 64 0x20 32)
					
					(unless @0x20 (return 0x20 32))
					
					[[0x1001]] 1 ;TODO remove
					
					[0x40] "getentry"
					[0x60] (calldataload 32)
					(call (- (GAS) 100) @0x20 0 0x40 64 0x40 160)
					;[0x40] poster address
					;[0x60] ts
					;[0x80] item
					;[0xA0] amount
					;[0xC0] price
					
					(unless @0x40 (return 0x40 32)) ; No such posting - cancel.
					
					[[0x1002]] @0x40 ;TODO REMOVE
					[[0x1003]] @0x80 ;TODO REMOVE
					[[0x1004]] @0xA0 ;TODO REMOVE
					
					[0x100] "get"
					[0x120] "items"
					(call (- (GAS) 100) @@0x10 0 0x100 64 0x100 32) ; items at 0x100
					
					(unless @0x100 (return 0x100 32))
					
					[[0x1005]] @0x100 ;TODO REMOVE
					
					[0x120] "getitemfull"
					[0x140] @0x80
					(call (- (GAS) 100) @0x100 0 0x120 64 0x120 160)
					;[0x120] type
					;[0x140] stacksize
					;[0x160] address
					
					; If the item is not in the database it cannot be sold.
					(unless @0x120 (return 0x120 32))
					
					[[0x1006]] @0x120 ;TODO REMOVE
					[[0x1007]] @0x140 ;TODO REMOVE
					[[0x1008]] @0x160 ;TODO REMOVE
					
					[0x180] "getuserdataaddr"
					[0x1A0] (ORIGIN)
					(call (- (GAS) 100) @0x0 0 0x180 64 0x180 32) ; Buyer user data
					
					(unless @0x180 (return 0x180 32)) ; Not necessary
					
					[0x1A0] "gettokens"
					(call (- (GAS) 100) @0x180 0 0x1A0 32 0x1A0 32) ; Get buyer token amount
					
					[[0x1009]] @0x1A0 ;TODO REMOVE
					
					(when (< @0x1A0 0xC0)
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					
					[0x1A0] "getholdings"
					(call (- (GAS) 100) @0x180 0 0x1A0 32 0x1A0 32) ; Get buyer holdings
					
					[0x1C0] "getitem"
					[0x1E0] @0x80
					(call (- (GAS) 100) @0x1A0 0 0x1C0 64 0x1C0 32) ; Check how many user already have.
					
					[[0x1010]] @0x1C0 ;TODO REMOVE
					
					[0x200] 0
					(when @0x140 (unless (<= (+ @0x1C0 @0xA0) @0x140) (return 0x200 32) ) )
					
					[0x200] "getuserdataaddr"
					[0x220] @0x40
					(call (- (GAS) 100) @0x0 0 0x200 64 0x200 32) ; Seller user data
					
					[[0x1011]] @0x200 ;TODO REMOVE
					
					; We made sure that buyer has the sovereigns needed to buy, and that he
					; can receive the items on sale (that he doesn't already have to many or something).
					
					
					; Unless caller = poster, charge the buyer. Otherwise it is the  
					; poster canceling the sale (we just give him the posted items back).
					(unless (= @0x40 (ORIGIN))
						{
							[0x220] "removetokens"
							[0x240] @0xC0
							(call (- (GAS) 100) @0x180 0 0x220 64 0x220 32) ; Buyer
							
							[0x220] "addtokens"
							[0x240] @0xC0
							(call (- (GAS) 100) @0x200 0 0x220 64 0x220 32) ; Buyer
						}
					)
					
					; Now add the items to the buyer holdings, and remove the market posting.
					
					;USAGE: "additem" 32: "name", 64: amount, 96 : type, 128 : subtype, 160 : address (optional)
					[0x220] "additem"
					[0x240] @0x80
					[0x260] @0xA0
					[0x280] "personal"
					[0x2A0] @0x120
					[0x2C0] @0x160
					(call (- (GAS) 100) @0x1A0 0 0x220 192 0x220 32)
					
					[0x220] "remove"
					[0x240] (calldataload 32)
					(call (- (GAS) 100) @0x20 0 0x220 64 0x220 32) ; Remove from market
					
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