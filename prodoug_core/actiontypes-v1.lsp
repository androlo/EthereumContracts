; INIT
{	
	;For DOUG integration
	[[0x10]] 0x8bffd298a64ee36eb7b99dcc00d2c67259d15c60 ;Doug Address
	;List data section
	[[0x11]] 0x0										;Size of list
	[[0x12]] 0x0										;Tail address
	[[0x13]] 0x0										;Head address
	
	[0x0] "reg"
	[0x20] "actiontypes"
	(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32) ;Register with DOUG  TODO remove.
	
	[0x0](LLL
	{
		[[0x9]] "autopass" ; Default vote type
		[[0x10]] 0x8bffd298a64ee36eb7b99dcc00d2c67259d15c60
		
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
						; If autopass, return this contract, otherwise return a newly generated one.
						(if (calldataload 32)
							{
								[0x0] (ADDRESS)
								(return 0x0 32)	
							}
							{
								[0x0](LLL
									{												
										;body section
										[0x0](LLL
											{
												; USAGE: 0 : "setdoug", 32 : dougaddress
												; RETURNS: 1 if successful, 0 if not.
												; NOTES: Set the DOUG address. This can only be done once.
												; INTERFACE Action
												(when (= (calldataload 0) "setdoug") 
													{
														(when @@0x10 
															{
																[0x0] 0
																(return 0x0 32)
															}
														) ; Once doug has been set, don't let it be changed externally.
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
												
												; USAGE: 0 : "setpoll", 32 : "pollname"
												; RETURNS: 1 if successful, 0 if not.
												; NOTES: Set the poll that should be used. Must be done by actiontypes.
												; INTERFACE Action
												(when (= (calldataload 0) "setpoll") 
													{											
														[0x0] "get"
														[0x20] "actiontypes"
														(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
														
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
												
												; USAGE: 0 : "getpoll"
												; RETURNS: The name of the poll used (or null if unset, which is a bug).
												; INTERFACE Action
												(when (= (calldataload 0) "getpoll") ;Anyone can do this.
													{
														[0x0] @@0x9
														(return 0x0 32)
													}
												)
												
												; USAGE: 0 : "init", 32: params
												; RETURNS: 1 if successful, 0 if not.
												; NOTES: Initializes the action. Init must do all checks necessary to make sure
												;		 that this action can actually be executed.
												; INTERFACE Action
												(when (= (calldataload 0) "init") 
													{
														[0x0] "get"
														[0x20] "actions"
														(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
																
														(unless (&& (= (CALLER) @0x0) (> (calldataload 64) 0x40) (calldataload 32) ) 
															{
																[0x0] 0
																(return 0x0 32)
															}
														) ; Only "actions" can do this.
														
														[0x0] "get"
														[0x20] "actiontypes"
														(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
														
														[0x0] "hasaction"
														[0x20] (calldataload 64)
														(call (- (GAS) 100) @0x40 0 0x0 64 0x0 32)
														
														; Don't let an action be added if an action with
														; the same name already exists.
														(when @0x0
															{
																[0x0] 0
																(return 0x0 32)
															}
														)
														
														[[0x11]] (calldataload 32) ; address
														[[0x12]] (calldataload 64) ; name
														
														[0x0] 1
														(return 0x0 32)
													}
												)
												
												; USAGE: 0 : "execute"
												; RETURNS: 1 if successful, 0 if not.
												; NOTES: Executes the action. This is normally done after a successful vote.
												;		 Checks must be made again, as the DAO might have changed while
												;		 the vote was pending, so succeeding the init checks is no guarantee
												;		 that execute will also succeed.
												; INTERFACE Action
												(when (= (calldataload 0) "execute")
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
														[0x20] "actiontypes"
														(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
														
														[0x20] "hasaction"
														[0x40] @@0x12
														(call (- (GAS) 100) @0x0 0 0x20 64 0x20 32)
														
														; Don't let an action be added if an action with
														; the same name already exists.
														(when @0x20
															{
																[0x0] 0
																(return 0x0 32)
															}
														)
														
														[0x40] "reg"
														[0x60] @@0x12
														[0x80] @@0x11
														(call (- (GAS) 100) @0x0 0 0x40 96 0x0 32) ; Reg contract as a new action.
														
														[0x0] 1
														(return 0x0 32)
													}
												)
														
												[0x0] "get"
												[0x20] "actions"
												(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32) ;Actions at 0x0
												
												; USAGE: 0 : "kill"
												; RETURNS: 0 if fail.
												; NOTES: Suicide the contract if 'actions' is the calling contract.
												(when (&& (= (CALLER) @0x0) (= (calldataload 0) "kill")) ;clean up
													(suicide (CALLER))
												)
												
												[0x0] 0
												(return 0x0 32)
														
											} 0x20 )
										(return 0x20 @0x0) ;Return body
									} 0x20 )
								[0x0](create 0 0x20 @0x0)
								(return 0x0 32)		
							}
						)
					
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
				
				; USAGE: 0 : "autoexecute", 32: params
				; RETURNS: 1 if successful, 0 if not.
				; NOTES: Initializes the action. Init must do all checks necessary to make sure
				;		 that this action can actually be executed.
				; INTERFACE Action
				(when (= (calldataload 0) "autoexecute")
					{
						
						[0x0] "get"
						[0x20] "actions"
						(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
								
						(unless (&& (= (CALLER) @0x0) (> (calldataload 64) 0x40) (calldataload 32) ) 
							{
								[0x0] 0
								(return 0x0 32)
							}
						) ; Only "actions" can do this.
						
						[0x0] "get"
						[0x20] "actiontypes"
						(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
						
						[0x0] "hasaction"
						[0x20] (calldataload 64)
						(call (- (GAS) 100) @0x40 0 0x0 64 0x0 32)
						
						; Don't let an action be added if an action with
						; the same name already exists.
						(when @0x0
							{
								[0x0] 0
								(return 0x0 32)
							}
						)
						
						[0x60] "reg"
						[0x80] (calldataload 64)
						[0xA0] (calldataload 32)
						(call (- (GAS) 100) @0x40 0 0x60 96 0x0 32) ; Reg contract as a new action.
						
						(unless @0x0 (return 0x0 32) )
												
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
		
	} 0x20 )
	[0x0](create 0 0x20 @0x0)
	
	; Add "autopass" as the first poll in the list.
	[["addaction"]] @0x0
	[[(- "addaction" 1)]] "autopass"
	
	[[0x11]] 1
	[[0x12]] "addaction"
	[[0x13]] "addaction"
	
	(return 0x0 (lll 
	{
		
		[0x0] (calldataload 0)	;This is the command
		[0x20] (calldataload 32)	;This is the name
		
		; USAGE: 0: "create" 32: "name", 64: autopass (1 or 0)
		; RETURNS: Address to the newly created Action, or null.
		; INTERFACE FactoryManager<Factory<Action>>
		(when (= @0x0 "create") 
			{	
				
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 0x40)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x0] @@ (calldataload 32)
				[0x20] "get"
				[0x40] (calldataload 64)
				(call (- (GAS) 100) @0x0 0 0x20 64 0x40 32) ; Get the address of the action contract.
				
				; If this is not autopass, set the doug value of the returned contract.
				(unless (calldataload 64)
					{
						[0x0] "setdoug"
						[0x20] @@0x10
						(call (- (GAS) 100) @0x40 0 0x0 64 0x60 32) ; Set doug
				
						(unless @0x60 (return 0x60 32) )		
					}
				)
				
				[0x0] "setpoll"
				[0x20] @@ (- (calldataload 32) 1)
				(call (- (GAS) 100) @0x40 0 0x0 64 0x60 32) ; Set the poll type to the designated one.
				
				(return 0x40 32)
			}
		)
		
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
		
		; USAGE: 0: "getactnpoll" 32: "actionname"
		; RETURNS: The poll used for the action with name "actionname", or null.
		; INTERFACE: ActionFactoryManager
		(when (= @0x0 "getactnpoll")
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
		
		; USAGE: 0: "getactnpoll" 32: "actionname", 64 : "pollname"
		; RETURNS: 1 if successful, 0 if not.
		; NOTES: Set the poll type used for the action "actionname".
		; INTERFACE: ActionFactoryManager 
		(when (= @0x0 "setactnpoll") 
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
				(call (- (GAS) 100) @@0x10 0 0x60 64 0xA0 32) ; Check if there is a votes contract.
				
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
		
		; USAGE: 0: "hasaction" 32: "name"
		; RETURNS: Pointer to the Action generator contract with name "name", or null.
		; INTERFACE: FactoryManager<Factory<Action>>
		; DEPRECATED: Will be replaced with a command that is the same for all factory managers.
		(when (= @0x0 "hasaction")  
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 0x40)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x0] @@ (calldataload 32)
				(return 0x0 32)
			}
		)
		
		; USAGE: 0: "reg" 32: "name", 64: address
		; RETURNS: 1 if successful, otherwise 0.
		; INTERFACE FactoryManager<Factory<Action>>
		(when (= @0x0 "reg") 
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
				(call (- (GAS) 100) @@0x10 0 0x60 64 0xA0 32) ; Check if there is an actions contract.
				
				(when @0xA0 ; If so, validate the caller to make sure it's a proper action.
					{
						
						[0x60] "validate"
						[0x80] (CALLER)
						(call (- (GAS) 100) @0xA0 0 0x60 64 0x60 32)
				
						(unless @0x60 (return 0x60 32) )		
					}
				)
				
				;If the name address is non-empty (name already taken) - cancel.
				(when @@ @0x20 
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				
				; Start by setting the doug address
				[0x60] "setdoug"
				[0x80] @@0x10
				(call (- (GAS) 100) @0x40 0 0x60 64 0xA0 32)
								
				(unless @0xA0 (return 0xA0 32) )
				
				[0x60] "getpoll"
				(call (- (GAS) 100) @0x40 0 0x60 64 0xA0 32) ; Get hard coded poll type.
				
				[0x60] "get"
				[0x80] "polltypes"
				(call (- (GAS) 100) @@0x10 0 0x60 64 0xC0 32) ; Get poll types contract.
				
				(unless @0xC0 (return 0xC0 32) )
				
				[0x60] "haspoll"
				[0x80] @0xA0
				(call (- (GAS) 100) @0xC0 0 0x60 64 0xC0 32) ; Check if provided poll exists in the system.
				
				(unless @0xC0 (return 0xC0 32) ) ; If no such poll exists - cancel.
			
				; Store address at name.
				[[@0x20]] @0x40
				; Store polltype at name - 1
				[[(- @0x20 1)]] @0xA0
	
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
		; INTERFACE FactoryManager<Factory<Action>>
		(when (= @0x0 "dereg")
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
				(call (- (GAS) 100) @@0x10 0 0x60 64 0xA0 32) ; Check if there is a votes contract.
				
				(when @0xA0 ; If so, validate the caller to make sure it's a proper action.
					{
						[0x60] "validate"
						[0x80] (CALLER)
						(call (- (GAS) 100) @0xA0 0 0x60 64 0x60 32)
				
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
				[[(- @0x20 1)]] 0	;The address for the polltype
				[[(+ @0x20 1)]] 0	;The address for its 'previous'
				[[(+ @0x20 2)]] 0	;The address for its 'next'
						
				;Decrease the size counter
				[[0x11]] (- @@0x11 1)
				[0x0] 1
				(return 0x0 32)
			} ; end when body
		) ;end when	
		
		[0x0] 0
		(return 0x0 32)
	}
	0x0))
}