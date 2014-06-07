; This is an action generator factory template. It has all the code needed to take instructions, package it in
; a generator contract, and make it a valid action that PRODOUG can run. 

; The 'init' and 'execute' sections has comments in them saying "TODO ADD CODE HERE"
; Init and Execute ADD CODE is on lines 166 and 197

; See action writing guide (same repo and folder as this file) for advice, and other actions as examples -
; addtodoug.lsp would be perhaps the simplest example.
{
	[0x0] 0
	(def 'CHECK (name)
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
			[0x20] name
			(call (- (GAS) 100) @0x40 0 0x0 64 0x0 32)
			
			; Don't let an action be added if an action with
			; the same name already exists.
			(when @0x0
				{
					[0x0] 0
					(return 0x0 32)
				}
			)
		}
	)
	
	; USAGE: 0 : "init", 32: params
	; RETURNS: 1 if successful, 0 if not.
	; NOTES: Initializes the action. Init must do all checks necessary to make sure
	;		 that this action can actually be executed.
	; INTERFACE Action
	(def 'INIT 
		(when (= (calldataload 0) "init") 
			{
				(CHECK (calldataload 64))
				
				[[0x11]] (calldataload 32) ; address
				[[0x12]] (calldataload 64) ; name
				
				[0x0] 1
				(return 0x0 32)
			}
		)
	)
	
	; USAGE: 0 : "execute"
	; RETURNS: 1 if successful, 0 if not.
	; NOTES: Executes the action. This is normally done after a successful vote.
	;		 Checks must be made again, as the DAO might have changed while
	;		 the vote was pending, so succeeding the init checks is no guarantee
	;		 that execute will also succeed.
	; INTERFACE Action
	(def 'EXECUTE 
		(when (= (calldataload 0) "execute")
			{													
				(CHECK @@0x12)
				
				[0x40] "reg"
				[0x60] @@0x12
				[0x80] @@0x11
				(call (- (GAS) 100) @0x0 0 0x40 96 0x0 32) ; Reg contract as a new action.
				
				[0x0] 1
				(return 0x0 32)
			}
		)
	)
	
	
	; USAGE: 0 : "init", 32: params
	; RETURNS: 1 if successful, 0 if not.
	; NOTES: Initializes the action. Init must do all checks necessary to make sure
	;		 that this action can actually be executed.
	; INTERFACE Action
	(def 'AUTOEXECUTE
		
		(when (= (calldataload 0) "autoexecute")
			{
				(CHECK (calldataload 64))
				
				[0x40] "reg"
				[0x60] (calldataload 64)
				[0x80] (calldataload 32)
				(call (- (GAS) 100) @0x0 0 0x40 96 0x0 32) ; Reg contract as a new action.

				[0x0] 1
				(return 0x0 32)
			}
		)
	)
	
	; USAGE: 0 : "setdoug", 32 : dougaddress
	; RETURNS: -
	; NOTES: Set the DOUG address. This can only be done once.
	; INTERFACE Factory<?>
	(def 'SETDOUG 
		{
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
		}
	)
	
	; USAGE: 0 : "setpoll", 32 : "pollname"
	; RETURNS: 1 if successful, 0 if not.
	; NOTES: Set the poll that should be used. Must be done by actiontypes.
	; INTERFACE Action
	(def 'SETPOLL 
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
	)
	
	(def 'CREATEACTION 
		{
			[0x0](LLL
				{												
					;body section
					[0x0](LLL
						{
							SETDOUG
																		
							[0x0] "get"
							[0x20] "doug"
							(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
							[[0x10]] @0x0 ;Copy doug
							
							
							SETPOLL
							
							; USAGE: 0 : "getpoll"
							; RETURNS: The name of the poll used (or null if unset, which is a bug).
							; INTERFACE Action
							(when (= (calldataload 0) "getpoll") ;Anyone can do this.
								{
									[0x0] @@0x9
									(return 0x0 32)
								}
							)
							
							INIT
							
							EXECUTE
							
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
	
	; *********************************** START ************************************
	
	[[0x9]] "autopass" ; Default vote type
	
		;body section
	[0x0](LLL
		{
			SETDOUG ; <- SET DOUG
			
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
			[0x20] "doug"
			(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
			[[0x10]] @0x40
			
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
							CREATEACTION
						}
					)
				
				}
			)
			
			SETPOLL
			
			AUTOEXECUTE
					
			; Only 'actiontypes'can do this.
			(when (&& (= (calldataload 0) "kill") (= (CALLER) @0x0) ) (suicide (CALLER)) )
			
			[0x0] 0
			(return 0x0 32)
			
		} 0x20 )
	(return 0x20 @0x0) ;Return body
}