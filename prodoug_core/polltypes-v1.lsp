; INIT
{
	;For DOUG integration
	[[0x10]] 0x07a03c311f07ad616e551daaee83e330c702559b ;Doug Address
	;List data section
	[[0x11]] 0x0										;Size of list
	[[0x12]] 0x0										;Tail address
	[[0x13]] 0x0										;Head address
	
	[0x0] "reg"
	[0x20] "polltypes"
	(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32) ;Register with DOUG  TODO remove.
	
	[0x0](LLL
	{
		[[0x10]] 0x07a03c311f07ad616e551daaee83e330c702559b
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
				
				; USAGE: 0 : "doautopass", 32 : action creator address
				; RETURNS: 1 if successful, otherwise 0.
				; INTERFACE Poll
				(when (= (calldataload 0) "doautopass") 
					{
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
		0x20 
	)
	[0x0](create 0 0x20 @0x0)
	
	; Add "autopass" as the first poll in the list.
	[["autopass"]] @0x0
	
	[[0x11]] 1
	[[0x12]] "autopass"
	[[0x13]] "autopass"
	
	;BODY
	(return 0x0 (lll 
	{
		[0x0] (calldataload 0)	;This is the command
		[0x20] (calldataload 32)	;This is the name
	
		; USAGE: 0: "kill"
		; RETURNS: -
		; NOTES: Suicides the contract if called by DOUG
		(when (= @0x0 "kill")
			{
				(when (= (CALLER) @@0x10) 
					(suicide (CALLER))
				
				)
			} 
		) ;Kill option
		
		[0x40] (calldataload 64)
		
		; USAGE: 0: "reg" 32: "name", 64: address
		; RETURNS: 1 if successful, otherwise 0.
		; INTERFACE FactoryManager<Factory<Poll>>
		(when (= @0x0 "reg")
			{
				
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 64)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x60] "get"
				[0x80] "actions"
				(call (- (GAS) 100) @@0x10 0 0x60 64 0xA0 32) ; Check if there is a votes contract.
				
				(when @0xA0 ; If so, validate the caller to make sure it's a proper action.
					{					
						[0x60] "validate"
						[0x80] (CALLER)
						(call (- (GAS) 100) @0xA0 0 0x60 64 0x60 32)
				
						(unless @0x60 (return 0x60 32) )		
					}
				)
				
				;Stop if the name address is non-empty (name already taken)
				(when @@ @0x20 
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x60] "setdoug"
				[0x80] @@0x10
				(call (- (GAS) 100) @0x40 0 0x60 64 0xA0 32)
				(unless @0xA0 (return 0xA0 32) )
				
				;Store poll address at poll name
				[[@0x20]] @0x40
	
				(if @@0x11 ; If there are elements in the list. 
					{
						;Update the list. First set the 'next' of the current head to be this one.
						[[(+ @@0x13 2)]] @0x20
						;Now set the current head as this ones 'previous'.
						[[(+ @0x20 1)]] @@0x13	
					} 
					{
						;If no elements, add this as tail
						[[0x12]] @0x20
					}
				
				)
				;And set this as the new head.
				[[0x13]] @0x20
				;Increase the list size by one.
				[[0x11]] (+ @@0x11 1)
				
				;Return the value 1 for a successful register
				[0x0] 1
				(return 0x0 0x20)
			} ;end body of when
		); end when
	
		
		; USAGE: 0: "dereg" 32: "name"
		; RETURNS: 1 if successful, otherwise 0.
		; INTERFACE FactoryManager<Factory<Poll>>
		(when  (= @0x0 "dereg")
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 64)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x60] "get"
				[0x80] "actions"
				(call (- (GAS) 100) @@0x10 0 0x60 64 0x40 32) ; Check if there is an actions contract.
				
				(when @0x40 ; If so, validate the caller to make sure it's a proper action.
					{
						[0x60] "validate"
						[0x80] (CALLER)
						(call (- (GAS) 100) @0x40 0 0x60 64 0x60 32)
				
						(unless @0x60 (return 0x60 32) )		
					}
				)
				
				[0x40] @@ @0x20
				;If the name has no address (does not exist) - cancel.
				(unless @0x40
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x60] "kill"
				(call (- (GAS) 100) @0x40 0 0x60 32 0x60 32) ; Suicide generator
	
				[0x40] @@(+ @0x20 1) ; Here we store the this ones 'previous' (which always exists).
				[0x60] @@(+ @0x20 2) ; And next
			
				;Change previous elements 'next' to this ones 'next', if this one has a next (this could be the head..)
				(if @0x60
					{
						(if @0x40
							{
								;Change next elements 'previous' to this ones 'previous'.
								[[(+ @0x60 1)]] @0x40
								;Change previous elements 'next' to this ones 'next'.
								[[(+ @0x40 2)]] @0x60		
							}
							{
								; We are tail. Set next elements previous to 0
								[[(+ @0x60 1)]] 0
								; Set next element as current tail.
								[[0x12]] @0x60
							}
							
						)
					}
					
					{
						(if @0x40
							{
								;This element is the head - unset 'next' for the previous element making it the head.
								[[(+ @0x40 2)]] 0
								;Set previous as head
								[[0x13]] @0x40	
							}
							{
								; This element is the tail. Reset head and tail.
								[[0x12]] 0
								[[0x13]] 0
							}					
						)
					}
				)
	
				;Now clear out this element and all its associated data.
				
				[[@0x20]] 0			;The address of the name
				[[(+ @0x20 1)]] 0	;The address for its 'previous'
				[[(+ @0x20 2)]] 0	;The address for its 'next'
						
				;Decrease the size counter
				[[0x11]] (- @@0x11 1)
				[0x0] 1
				(return 0x0 32)
			} ; end when body
		) ;end when
		
		
		; USAGE: 0: "haspoll" 32: "name"
		; RETURNS: Pointer to the Poll generator contract with name "name", or null.
		; INTERFACE: FactoryManager<Factory<Poll>>
		; DEPRECATED: Will be replaced with a command that is the same for all factory managers.
		(when (= @0x0 "haspoll")  
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 64)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x0] @@ (calldataload 32)
				(return 0x0 32)
			} ; end when body
		) ;end when
		
		; USAGE: 0: "create" 32: "name"
		; RETURNS: Address to the newly created Poll, or null.
		; INTERFACE FactoryManager<Factory<Poll>>
		(when  (= @0x0 "create")
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 64)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x0] @@ (calldataload 32)
				[0x20] "get"
				(call (- (GAS) 100) @0x0 0 0x20 32 0x40 32) ; Get the address of the newly generated poll contract.
				
				; If this is not autopass, set the doug address of the returned contract.
				(unless (= @0x40 @0x0)
					{
						[0x0] "setdoug"
						[0x20] @@0x10
						(call (- (GAS) 100) @0x40 0 0x0 64 0x60 32) ; Set doug
				
						(unless @0x60 (return 0x60 32) )
						
						[0x0] "settimelimit"
						[0x20] @@ (- (calldataload 32) 1)
						(call (- (GAS) 100) @0x40 0 0x0 64 0x60 32) ; Set the time limit.
						
						; Initialize the contract.
						[0x0] "init"
						(call (- (GAS) 100) @0x40 0 0x0 32 0x0 32) ; Init		
					}
				)
				
				(return 0x40 32)
			} ; end when body
		) ;end when
		
		; USAGE: 0: "gettimelimit" 32: "pollname"
		; RETURNS: The time limit used for the poll with name "pollname", or null.
		; NOTES: Only applicable to non-auto polls.
		; INTERFACE: PollFactoryManager
		(when (= @0x0 "gettimelimit")
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 0x40)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x0] @@ @0x20
				(unless @0x0 (return 0x0 32) )
				[0x20] @@ (- @0x20 1)
				(return 0x20 32)
			}
		)	
		
		[0x40] (calldataload 64)
		
		; USAGE: 0: "settimelimit" 32: "pollname", 64 : timelimit
		; RETURNS: 1 if successful, 0 if not.
		; NOTES: Set the time limit used for the poll "pollname".
		; INTERFACE: PollFactoryManager 
		(when (= @0x0 "settimelimit") 
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 0x40)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
								
				[0x60] "get"
				[0x80] "actions"
				(call (- (GAS) 100) @@0x10 0 0x60 64 0xA0 32) ; Check if there is an action contract.
				
				(when @0xA0 ; If so, validate the caller to make sure it's a proper action.
					{					
						[0x60] "validate"
						[0x80] (CALLER)
						(call (- (GAS) 100) @0xA0 0 0x60 64 0x60 32)
				
						(unless @0x60 (return 0x60 32) )		
					}
				)
				
				[[(- (calldataload 32) 1)]] (calldataload 64)
				
				[0x0] 1
				(return 0x0 32)
			}
		)
		
		[0x0] 0
		(return 0x0 32)
	}
	0x0 ))
}