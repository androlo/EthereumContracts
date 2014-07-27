; Actions contract
;
; This contract is used to manage actions.
;

; INIT
{
	;For DOUG integration
	[[0x10]] 0x8bffd298a64ee36eb7b99dcc00d2c67259d15c60 ;Doug Address
	;List data section
	[[0x11]] 0x0										;Size of list
	[[0x12]] 0x0										;Tail address
	[[0x13]] 0x0										;Head address
	
	[[0x14]] 64 ; Pending action number (counter).
	
	[[0x15]] 0 ; Actions is blocked.
	
	;[[0x16]] log address
	
	[[0x17]] 1 ; Do logging? (0 off, 1 on).

	[0x0] "reg"
	[0x20] "actions"
	(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32) ;Register with DOUG  TODO remove.
	
	[0x0](LLL
	{
		[[0x10]] 0x8bffd298a64ee36eb7b99dcc00d2c67259d15c60
		
		[[0x11]] 0x20 ; 8 slots per action, starting at 0x20.
		
		;body section
		[0x0](LLL
			{
				; USAGE_0:  0 : "addentry", 32 : type, 64 : actiontype, 96 : creator, 128 : timestamp
				; USAGE_1: 0 : "addentry", 32 : type, 64 : actiontype, 96 : polltype, 128 : creator, 160 : timestamp, 192 : vote result, 224 : issueNr
				; RETURNS: 
				(when (= (calldataload 0) "addentry")
					{
						[0x0] "get"
						[0x20] "actions"
						(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32) ; Get actions to 0x0
						
						(unless @0x0 (return 0x0 32) )
						
						[0x0] @@0x11
						
						[[@0x0]] (calldataload 32)
						
						(when (= (calldataload 32) "auto")
							{
								[[(+ @0x0 1)]] (calldataload 64)
								[[(+ @0x0 2)]] (calldataload 96)
								[[(+ @0x0 3)]] (calldataload 128)
								[[(+ @0x0 4)]] (NUMBER)
							}
						)
						
						(when (= (calldataload 32) "vote")
							{
								[[(+ @0x0 1)]] (calldataload 64)
								[[(+ @0x0 2)]] (calldataload 96)
								[[(+ @0x0 3)]] (calldataload 128)
								[[(+ @0x0 4)]] (calldataload 160)
								[[(+ @0x0 5)]] (calldataload 192)
								[[(+ @0x0 6)]] (calldataload 224)
								[[(+ @0x0 7)]] (NUMBER)
								
							}
						)
						
						[[0x11]] (+ @@0x11 8)
						
						[0x0] 1
						(return 0x0 32)
					}
				)
						
				[0x0] "get"
				[0x20] "actions"
				(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
				
				; Only 'actions' can do this. Suicide the generator contract.
				(when (&& (= (CALLER) @0x40) (= (calldataload 0) "kill"))
					{ 
						[0x0] "kill"
						(call (- (GAS) 100) @@0x16 0 0x0 32 0x0 0) ; Get actions to 0x0
						(suicide (CALLER))
					}
				)
						
			} 0x20 )
		(return 0x20 @0x0) ;Return body
		}	
		0x20 
	)
	[0x0](create 0 0x20 @0x0)
	
	; Add log address to 0x16
	[[0x16]] @0x0
	
	;BODY
	(return 0x0 (lll 
	{	
		[0x0] (calldataload 0)	;This is the command
		
		; USAGE:  0 : "kill"
		; RETURNS: 
		; NOTES: Sucicides contract.
		; TODO observe DOUG killing, assess.
		(when (= @0x0 "kill")
			{
				(when (= (CALLER) @@0x10) 
					
					(suicide (CALLER))
				
				)
			} 
		)
		
		[0x20] (calldataload 32)
		
		; USAGE: 0 : "take", 32 : "actionname", 64: sizeOfData 96: data, 
		;			 (96 + sizeofData) : sizeofComment, (128 + sizeofData) : commentdata
		; NOTES: TODO decide on a maximum sizeofData value. Comment data has a max size already.
		; RETURNS:
		;	0 - fail
		;	1 - autopass (not used)
		; 	2 - success
		; INTERFACE: ActionManager
		(when  (= @0x0 "take")
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 0x40)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x40] @@0x15 ; Check that the system is not locked.
				
				(when @0x40
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
					
				[0x40] "get"
				[0x60] "actiontypes"
				(call (- (GAS) 100) @@0x10 0 0x40 64 0xA0 32) ; Get actiontypes to 0x20
				
				(unless @0xA0 (return 0xA0 32) ) ; No actiontypes contract - cancel.
				
				;[[0x1000]] @0xA0 ;TODO remove
				
				[0x20] "getactnpoll"
				[0x40] (calldataload 32)
				(call (- (GAS) 100) @0xA0 0 0x20 64 0x20 32) ; Get poll type of the action.
				
				(unless @0x20 (return 0x20 32) ) ; No poll type - cancel.
				
				;[[0x1001]] @0x20 ;TODO remove
				
				[0x40] "get"
				[0x60] "polltypes"
				(call (- (GAS) 100) @@0x10 0 0x40 64 0x80 32) ;Get polltypes contract to 0x80
				
				(unless @0x80 (return 0x80 32) ) ; No polltypes contract - no vote
				
				;[[0x1002]] @0x80 ;TODO remove
				
				; Get the appropriate poll contract.
				[0x40] "create"
				[0x60] @0x20
				(call (- (GAS) 100) @0x80 0 0x40 64 0x0 32)
								
				(unless @0x0 (return 0x0 32) )
				
				;[[0x1003]] @0x0 ;TODO remove
						
				; Check if it is an autopass vote.
				[0xC0] 0 ; Set this to 0, to be sure.
				[0x40] "isautopass"
				(call (- (GAS) 100) @0x0 0 0x40 32 0xC0 32)
				
				;[[0x1004]] @0xC0 ;TODO remove
					
				; Get action
				[0x40] "create"
				[0x60] (calldataload 32)
				[0x80] @0xC0 ; Autopass or not.
				(call (- (GAS) 100) @0xA0 0 0x40 96 0x40 32)
								
				(unless @0x40 (return 0x40 32) ) ; No such action - cancel.
				
				;[[0x1005]] @0x40 ;TODO remove
				
				; Initialize the poll
				[0x60] "init"
				(call (- (GAS) 100) @0x0 0 0x60 32 0x60 32)
				
				(unless @0x60 (return 0x60 32)) ; If vote init fails - cancel.
				
				; Now it must be decided how the action is run - autopass or not.
				(if @0xC0
					{ ; In the case of auto-pass.
						
						[0x60] "doautopass"
						[0x80] (CALLER)
						(call (- (GAS) 100) @0x0 0 0x60 64 0x60 32) ; Run the poll.
						
						(unless @0x60 (return 0x60 32) ) ; If autopass fails - cancel.
						
						;[[0x1006]] @0x60 ;TODO remove
						
						; Temporarily add the action to this contract, so that validation works.
						[[@0x40]] (calldataload 32)
						
						[0x60] "autoexecute"
						(calldatacopy 0x80 96 (calldataload 64))
						(call (- (GAS) 100) @0x40 (CALLVALUE) 0x60 ( + (calldataload 64) 32) 0x60 32) 
						
						; Now remove the validation entry.
						[[@0x40]] 0
						
						(unless @0x60 (return 0x60 32) ) ; If autoexecute fails - cancel.
						
						;[[0x1007]] @0x60 ;TODO remove
												
						; If logging
						(when @@0x17 
							{								
								[0x60] "addentry"
								[0x80] "auto"
								[0xA0] (calldataload 32)
								[0xC0] (ORIGIN)
								[0xE0] (TIMESTAMP)
								(call (- (GAS) 100) @@0x16 0 0x60 160 0x0 0) ; Call log contract
							}
						)
						
						[0x0] 1
						(return 0x0 32) ; Return 1 for successful autopass.
					}
					
					{ ; In the case of a vote.
						
						; Initialize the action
						[0x60] "init"
						(calldatacopy 0x80 96 (calldataload 64)) ;send "init", "payload" to the action.
						(call (- (GAS) 100) @0x40 (CALLVALUE) 0x60 ( + (calldataload 64) 32) 0x60 32) 
						
						(unless @0x60 (return 0x60 32) ) ; If action init fails - cancel.
						
						;[[0x1006]] @0x60
						
						; Now store the pending action in the list.
						[[@@0x14]] @0x40 					; Action address
						[[@0x40]] @@0x14
						[[(- @@0x14 1)]] @0x0 				; Poll address
						[[(- @@0x14 2)]] (calldataload 32)	; Action name
						[[(- @@0x14 3)]] @0x20 				; Poll name
						[[(- @@0x14 4)]] (CALLER)			; Caller
						[[(- @@0x14 5)]] (TIMESTAMP)		; Timestamp
						
						[0x40] (+ (calldataload 64) 96) ; Get the address where the comment size is stored.
						[0x60] (calldataload @0x40)
						[[(- @@0x14 6)]] @0x60 ; Store size of comment (in memory slots).
						
						(when @0x60 ; If we have comments, we include these with the action.
							{
								(when (> @0x60 30) ; Don't let users add arbitrarily large comments. Max is 960 chars.
									[0x60] 30;
								)
								
								[0x40] (+ @0x40 32) ; Move ahead to where comment data starts.
								
								(for [0x80] 0 (< @0x80 @0x60) [0x80](+ @0x80 1)
									{
									[[(- @@0x14 (+ @0x80 7))]] (calldataload @0x40)
										[0x40] (+ @0x40 32)
									}
								)
							}
						)
			
						(if @@0x11 ; If there are elements in the list. 
							{
								;Update the list. First set the 'next' of the current head to be this one.
								[[(+ @@0x13 2)]] @@0x14
								;Now set the current head as this ones 'previous'.
								[[(+ @@0x14 1)]] @@0x13	
							} 
							{
								;If no elements, add this as tail
								[[0x12]] @@0x14
							}
						
						)
						
						;And set this as the new head.
						[[0x13]] @@0x14
						;Increase the list size by one.
						[[0x11]] (+ @@0x11 1)
						
						[[0x14]] (+ @@0x14 64)
						
						[0x0] 2
						(return 0x0 32) ;Return 2 for successful vote registration.
					}
				)		
				
				
			}
		)
		
		; USAGE 0 : "validate", 32 : action address
		; RETURNS: Issue number if successful, 0 otherwise.
		; NOTES: This is called from contracts if they want to ensure that another contract trying to modify
		;		 it is an action that has passed through the proper channels.
		; INTERFACE: ActionManager
		(when  (= @0x0 "validate")
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
		
		[0x40] (calldataload 64) ; Voting value.
		
		; USAGE 0 : "vote", 32 : issue, 64 : voting value
		; RETURNS: 
		; NOTES: This is how you vote - by passing the issue number and vote value to this
		;			contract. The calls could be done directly to the poll contracts, and have
		;			this contract act as a listener for completed polls instead, but this works
		;			just as well for the time being.
		; INTERFACE: ActionManager
		(when (= @0x0 "vote") 
			{
				(when (< @0x20 64)  ; If the issue is not within the range of possible issue numbers - cancel.
					{
						[0x0] 0
						(return 0x0 0)
					}
				)
				; If this issue does not exist - cancel.
				(when (= @@ @0x20 0)
					{
						[0x0] 0
						(return 0x0 0)
					}
				)
				
				[0x0] @@ (- @0x20 1) ; get the poll address
				
				; Vote and get the return value.
				[0x20] "vote"
				[0x40] (calldataload 64)
				[0x60] (CALLER)
				(call (- (GAS) 100) @0x0 0 0x20 96 0x40 32 )
				
				; When return value is non-zero.
				(when (> @0x40 0)
					{
						(unless (< @0x40 3) 
							{
								[0x0] 0
								(return 0x0 32)
							}
						) ; We want result 1 or 2 for this.
						
						; Only execute if return value is 2, but clean up regardless of if it succeeded or failed.
						(when (= @0x40 2)
							{
								[0x20] @@(calldataload 32) ; Get action address		
								[0x60] "execute"
								(call (- (GAS) 100) @0x20 0 0x60 32 0x40 32 )
							}
						)
						
						[0x60] @0x40
						; Now clean up.
						[0x20] "_remove" ; Recursive call. Kill the poll contract, and clear the pending issue.
						[0x40] (calldataload 32) ; Note 0x60 is sent.
						(call (- (GAS) 100) (ADDRESS) 0 0x20 96 0x40 32) ; Store at 0x40 
						[0x0] 1
						(return 0x0 32)
					}
				)
				;Otherwise do nothing.
				(return 0x0 32)
				
			} ; end when body
		) ;end when
		
		; USAGE 0 : "startpoll", 32 : issue
		; RETURNS: 1 if successful, 0 otherwise.
		; NOTES: This is how you start a poll.
		; INTERFACE: ActionManager
		(when (= @0x0 "startpoll")
			{
				(unless @@(CALLER)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				(when (< @0x20 64)  ; If the issue is not within the range of possible issue numbers - cancel.
					{
						[0x0] 0
						(return 0x0 0)
					}
				)
				; If this issue does not exist - cancel.
				(when (= @@ @0x20 0)
					{
						[0x0] 0
						(return 0x0 0)
					}
				)
				
				[0x0] @@ (- @0x20 1) ; get the poll address
				
				[[0x2000]] @0x0 ; TODO remove
				
				; Finalize and get the return value.
				[0x20] "start"
				(call (- (GAS) 100) @0x0 0 0x20 32 0x40 32 )
				
				(return 0x40 32)
				
			} ; end when body
		) ;end when
		
		; USAGE 0 : "finalizepoll", 32 : issue
		; RETURNS: 
		; NOTES: This is how you manually finalize a poll that has expired.
		; INTERFACE: ActionManager
		(when (= @0x0 "finalizepoll") 
			{
				(unless @@(CALLER)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				(when (< @0x20 64)  ; If the issue is not within the range of possible issue numbers - cancel.
					{
						[0x0] 0
						(return 0x0 0)
					}
				)
				
				; If this issue does not exist - cancel.
				(when (= @@ @0x20 0)
					{
						[0x0] 0
						(return 0x0 0)
					}
				)
				
				[0x0] @@ (- @0x20 1) ; get the poll address
				
				; Finalize and get the return value.
				[0x20] "finalize"
				(call (- (GAS) 100) @0x0 0 0x20 32 0x40 32 )
				
				; When return value is non-zero.
				(when (> @0x40 0)
					{
						(unless (< @0x40 3) 
							{
								[0x0] 0
								(return 0x0 32)
							}
						) ; We want result 1 or 2 for this.
						
						; Only execute if return value is 2, but clean up regardless of if it succeeded or failed.
						(when (= @0x40 2)
							{
								[0x20] @@(calldataload 32) ; Get action address		
								[0x60] "execute"
								(call (- (GAS) 100) @0x20 0 0x60 32 0x40 32 )
							}
						)
						[0x60] @0x40
						; Now clean up. TODO log functionality.
						[0x20] "_remove" ; Recursive call. Kill the poll contract, and clear the pending issue.
						[0x40] (calldataload 32) ; Note 0x60 is also sent.
						(call (- (GAS) 100) (ADDRESS) 0 0x20 96 0x40 32) ; Store at 0x40 
						[0x0] 1
						(return 0x0 32)
					}
				)
				;Otherwise do nothing.
				[0x0] 0
				(return 0x0 32)
				
			} ; end when body
		) ;end when
		
		; USAGE: 0 : "_remove", 32 : issue number, 64 : vote result (1 or 2, fail or success respectively)
		; RETURNS: 1 if successful, 0 otherwise.
		; NOTES: Private.
		(when (= @0x0 "_remove") ;Remove a poll from the list, and kill the poll contract.
			{
				(unless (= (CALLER) (ADDRESS) ) 
					{
						[0x0] 0
						(return 0x0 32)
					}
				) ; Only actions itself can do this.
				
				[0x60] @@ @0x20
				[0x40] "kill"
				(call (- (GAS) 100) @0x60 0 0x40 32 0x40 32 ) ;Kill action contract
				
				[0x60] @@ (- @0x20 1)
				[0x40] "kill"
				(call (- (GAS) 100) @0x60 0 0x40 32 0x40 32 ) ;Kill poll contract
				
				[0x40] @@(+ @0x20 1) ; Here we store the this ones 'previous'.
				[0x60] @@(+ @0x20 2) ; And next
				
				; If we have a next (we're not head).
				(if @0x60
					{
						(if @0x40 ; If we have a tail.
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
					; If we have no 'next'
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
				(when @@0x17 ; If logging
					{
						[0x60] "addentry"
						[0x80] "vote"
						[0xA0] @@(- @0x20 2) 		; Action name
						[0xC0] @@(- @0x20 3) 		; Poll name
						[0xE0] @@(- @0x20 4) 		; Creator
						[0x100] @@(- @0x20 5)		; Timestamp
						[0x120] (calldataload 64)	; Vote result (0 or 1), fail or success)
						[0x140] (calldataload 32)	; Old issue number
						
						(call (- (GAS) 100) @@0x16 0 0x60 256 0x0 0) ; Call log contract		
					}
				)
				
				;Now clear out this element and all its associated data.
				[[@@ @0x20]] 0		;The actual address
				[[@0x20]] 0			;The address of the name
				[[(+ @0x20 1)]] 0	;The address for its 'previous'
				[[(+ @0x20 2)]] 0	;The address for its 'next'
				[[(- @0x20 1)]] 0	;The address for poll address.
				[[(- @0x20 2)]] 0	;The address for action name.
				[[(- @0x20 3)]] 0	;The address for poll name.
				[[(- @0x20 4)]] 0	;The address for action taker (caller).
				[[(- @0x20 5)]] 0	;The address for timestamp.
				[0x40] @@(- @0x20 6) ; Get comment size before removing.
				[[(- @0x20 6)]] 0	;The address for comment size.
				
				(when @0x40 ; If we have comments - remove.
					{					
						(for [0x80] 0 (< @0x80 @0x40) [0x80](+ @0x80 1)
							{
								[[(- @0x20 (+ @0x80 7))]] 0
							}
						)
					}
				)
	
				;Decrease the size counter
				[[0x11]] (- @@0x11 1)
				[0x0] 1
				(return 0x0 32)
			} ; end when body
		) ;end when
		
		
		; This should perhaps not be added.
		
		; USAGE: 0 : "remove", 32 : issue number
		; RETURNS: 1 if successful, 0 otherwise.
		(when (= @0x0 "remove") ;Remove a poll from the list, and kill the poll contract.
			{
				[0x60] @@(CALLER)
				(unless @0x60 (return 0x60 32) )
				
				(when @@0x17 ; If logging - turn it off.
					{
						[[0x17]] 0
						[0x80] 1		
					}
				)
				
				[0x20] "_remove" ; Recursive call. Kill the poll contract, and clear the pending issue.
				[0x40] (calldataload 32)
				(call (- (GAS) 100) (ADDRESS) 0 0x20 64 0x40 32) ; Store at 0x40 
				
				(when @0x80 [[0x17]] 1)
				
				[0x0] 1
				(return 0x0 32)
			} ; end when body
		) ;end when
		
		; USAGE: 0 : "logenable"
		; RETURNS: 1 if successful, 0 otherwise.
		(when (= @0x0 "logenable")
			{
				[0x60] @@(CALLER)
				(unless @0x60 (return 0x60 32) )
				
				[[0x17]] 1
								
				[0x0] 1
				(return 0x0 32)
			} ; end when body
		) ;end when
		
		; USAGE: 0 : "logdisable"
		; RETURNS: 1 if successful, 0 otherwise.
		(when (= @0x0 "logdisable")
			{
				[0x60] @@(CALLER)
				(unless @0x60 (return 0x60 32) )
				
				[[0x17]] 0
								
				[0x0] 1
				(return 0x0 32)
			} ; end when body
		) ;end when
		
		; USAGE: 0 : "lock"
		; RETURNS: 1 if successful, 0 otherwise.
		; NOTES: Locking and unlocking of the action queue should not be done with actions, but
		;		 rather something else. This has to be configured for each individual DAO.
		; INTERFACE: ActionManager
		(when (= @0x0 "lock")
			{
				;Check that action taker is a member.
				[0x40] "get"
				[0x60] "users"
				(call (- (GAS) 100) @@0x10 0 0x40 64 0x0 32) ;Get users to 0x20
				
				[0x40] "getuserdataaddr"
				[0x60] (CALLER)
				(call (- (GAS) 100) @0x0 0 0x40 64 0x20 32)
				
				[0x40] "getuser"
				[0x60] "SysAdmin"
				(call (- (GAS) 100) @0x20 0 0x40 64 0x0 32)
				
				(unless @0x0 (return 0x0 32) )
				
				[[0x15]] 1
			}
		)
		
		; USAGE: 0 : "unlock"
		; RETURNS: 1 if successful, 0 otherwise.
		; NOTES: Locking and unlocking of the action queue should not be done with actions, but
		;		 rather something else. This has to be configured for each individual DAO.
		; INTERFACE: ActionManager
		(when (= @0x0 "unlock")
			{
				;Check that action taker is a member.
				[0x40] "get"
				[0x60] "users"
				(call (- (GAS) 100) @@0x10 0 0x40 64 0x0 32) ;Get users to 0x20
				
				[0x40] "getuserdataaddr"
				[0x60] (ORIGIN)
				(call (- (GAS) 100) @0x0 0 0x40 64 0x20 32)
				
				[0x40] "getuser"
				[0x60] "SysAdmin" ;TODO change
				(call (- (GAS) 100) @0x20 0 0x40 64 0x0 32)
				
				(unless @0x0 (return 0x0 32) )
				
				[[0x15]] 0
			}
		)
		
		; USAGE: 0 : "flush"
		; RETURNS: 1 if successful, 0 otherwise.
		; NOTES: This, like lock/unlock, can't/shouldn't be done with actions.
		; INTERFACE: ActionManager
		(when (= @0x0 "flush")
			{
				;Check that action taker is a member.
				[0x40] "get"
				[0x60] "users"
				(call (- (GAS) 100) @@0x10 0 0x40 64 0x0 32) ;Get users to 0x20
				
				[0x40] "getuserdataaddr"
				[0x60] (ORIGIN)
				(call (- (GAS) 100) @0x0 0 0x40 64 0x20 32)
				
				[0x40] "getuser"
				[0x60] "SysAdmin" ;TODO change
				(call (- (GAS) 100) @0x20 0 0x40 64 0x0 32)
				
				(unless @0x0 (return 0x0 32) )
				
				; If the pending list is empty, return.
				(unless @@0x11 
					{
						[0x0] 1
						(return 0x0 32)
					}
				)
				
				(when (= @@0x17 1) ; Don't log these issues.
					{
						[[0x17]] 0
						[0xA0] 1		
					}
				)
																
				;Start at tail
				[0x20] @@0x12
				
				; While we have a next element.
				(while @0x20
					{
						[0x60] "_remove" ; Recursive call. Kill the poll contract, and clear the pending issue.
						[0x80] @0x20
						(call (- (GAS) 100) (ADDRESS) 0 0x60 64 0x40 32) ; Store at 0x40
														
						;Do a little thing.
						[0x40] @0x20
						[0x20] @@ (+ @0x20 2)
						;Now clear this entry.
						[[@0x40]] 0
						[[(+ @0x40 1)]] 0
						[[(+ @0x40 2)]] 0
					}	
				)
				
				; Clear size, head and tail.
				[[0x11]] 0
				[[0x12]] 0
				[[0x13]] 0
				
				(when @0xA0 [[0x17]] 1) ; If logging was on - turn it back on.
												
				[0x0] 1
				(return 0x0 32)
			}
		)
		
		[0x0] 0
		(return 0x0 32)
	}
	0x0 )) ; End of body
}