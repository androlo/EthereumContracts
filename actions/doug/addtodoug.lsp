;INIT
{
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
													
													; Get the address of contract with name (calldataload 64) from doug.
													[0x0] "get"
													[0x20] (calldataload 64)
													(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
													
													; If this returns a non-zero value, there is already a contract with this name.
													; We don't let an already existing contract be overwritten.
													(when @0x40
														{
															[0x0] 0
															(return 0x0 32)
														}
													)
													
													; Store name and address of this contract.
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
													
													; Get the contract with name @@0x12 from doug.
													[0x0] "get"
													[0x20] @@0x12
													(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
													
													; Don't let an already existing contract be overwritten.
													(when @0x0
														{
															[0x0] 0
															(return 0x0 32)
														}
													)
													
													; If no contract with name @@0x12 in doug, register this one. @@0x11 is address.
													[0x40] "reg"
													[0x60] @@0x12
													[0x80] @@0x11
													(call (- (GAS) 100) @@0x10 0 0x40 96 0x0 32) ; Reg contract as a new action.
													
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
			
			; USAGE: 0 : "init", 32: params
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
					
					; Get the contract with name @@0x12 from doug.
					[0x0] "get"
					[0x20] (calldataload 64)
					(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
					
					; Don't let an already existing contract be overwritten.
					(when @0x0
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					
					; If no contract with name @@0x12 in doug, register this one. @@0x11 is address.
					[0x40] "reg"
					[0x60] (calldataload 64)
					[0x80] (calldataload 32)
					(call (- (GAS) 100) @@0x10 0 0x40 96 0x0 32) ; Reg contract as a new action.
					
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