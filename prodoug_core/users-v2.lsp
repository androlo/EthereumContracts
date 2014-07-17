; Users v2
;
; This contract lets people register user names.
;
; TODO implement the group interface (and add as just another group?).
; TODO make it possible to grab all current user data and shove it into the new contract when replaced.

; INIT
{
	;For DOUG integration
	[[0x10]] 0x8bffd298a64ee36eb7b99dcc00d2c67259d15c60 ;Doug Address
	;List data section
	[[0x11]] 0x0										;Size of list
	[[0x12]] 0x0										;Tail address
	[[0x13]] 0x0										;Head address
   
   ;[[0x15]] Reserved for lock
	
	[0x0] "reg"
	[0x20] "users"
	(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32) ;Register with DOUG  TODO remove.
	
	;BODY
	(return 0x0 (lll 
	{
		[0x0] (calldataload 0)		;This is the command
		
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
		
		[0x20] (calldataload 32)	;This is the name or address
		[0x40] (calldataload 64)
		
		; USAGE:  0 : "reg", 32: "nick", 64 : address
		; RETURNS: 1 if successful, 0 otherwise.
		; NOTES: Will use caller address if no address is provided in txdata
		; DEPRECATED: Will be changed to "adduser" when converted to a proper Group.
		(when (= @0x0 "reg")  
			{
				(when @@0x15 ; If locked.
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
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
				
				;Stop if the caller already has a nick.
				(when @@ @0x40 
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				;Stop if the name address is non-empty (nick already taken)
				(when @@ @0x20
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x60] "get"
				[0x80] "usertypes"
				(call (- (GAS) 100) @@0x10 0 0x60 64 0x60 32)
				
				(unless @0x60 (return 0x60 32) )
								
				;Validate name
				[0x80] "validatename"
				[0xA0] @0x20
				(call (- (GAS) 100) (ADDRESS) 0 0x80 64 0x80 32)
				
				(unless @0x80 (return 0x80 32) )
				
				[0x80] "create"
				[0xA0] "userdata"
				(call (- (GAS) 100) @0x60 0 0x80 64 0x60 32)
				
				(unless @0x60 (return 0x60 32) )
				
				[0x80] "setuser"
				[0xA0] (calldataload 64)
				(call (- (GAS) 100) @0x60 0 0x80 64 0x80 32)
				
				[0x80] "createholdings"
				(call (- (GAS) 100) (ADDRESS) 0 0x80 32 0x80 32)
				
				[0xA0] "postconst"
				[0xC0] @@0x10
				[0xE0] (calldataload 64)
				(call (- (GAS) 100) @0x80 0 0xA0 96 0xA0 32)
				
				[0xA0] "setholdings"
				[0xC0] @0x80
				(call (- (GAS) 100) @0x60 0 0xA0 64 0xC0 32)
				
				;Store caller at name, and name at caller.
				[[@0x20]] @0x40
				[[@0x40]] @0x20
				;Store userdata at @@(nick - 1)
				[[(- @0x20 1)]] @0x60
	
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
				(return 0x0 32)
			} ;end body of when
		); end when
	
		; USAGE:  0 : "dereg", 32: "nick"
		; RETURNS: 1 if successful, 0 otherwise.
		; NOTES: De-registers the user with nick 'nick'.
		; ACTION REQUIRED
		; DEPRECATED: Will be changed to "removeuser".
		(when (= @0x0 "dereg")
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 0x40)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				[0x40] @@ @0x20 ; Get nick address
				; If no user name corresponds to this name - cancel.
				(unless @0x40
					{
						[0x0] 0
						(return 0x0 32)	
					}
				)
				
				; Validate the action caller.					
				[0x40] "get"
				[0x60] "actions"
				(call (- (GAS) 100) @@0x10 0 0x40 64 0x80 32)
				
				(when @0x80
					{
						[0x40] "validate"
						[0x60] (CALLER)
						(call (- (GAS) 100) @0x80 0 0x40 64 0x40 32)
														
						(unless @0x40 (return 0x40 32) )		
					}
				)				

				
				[0x40] @@(+ @0x20 1) ; Here we store the this ones 'previous' (which always exists).
				[0x60] @@(+ @0x20 2) ; And next
			
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
				[0x40] (- @0x20 1);
				[0x60] "getholdings"
				(call (- (GAS) 100) @0x40 0 0x60 32 0x60 32)
				
				; Kill user data and holdings contracts.
				[0x80] "kill"
				(call (- (GAS) 100) @0x40 0 0x80 32 0x80 32)
				
				[0x80] "kill"
				(call (- (GAS) 100) @0x60 0 0x80 32 0x80 32)
				
				;Now clear out this element and all its associated data.
				[[@@ @0x20]] 0		;The actual address of the user
				[[@0x20]] 0			;The address of the name
				[[(+ @0x20 1)]] 0	;The address for its 'previous'
				[[(+ @0x20 2)]] 0	;The address for its 'next'
				[[(- @0x20 1)]] 0	;The user data
						
				;Decrease the size counter
				[[0x11]] (- @@0x11 1)
				[0x0] 1
				(return 0x0 32)
	
			} ; end when body
		) ;end when
		
		; USAGE: 0 : "getuserdata", 32: "nick"
		; RETURNS: Pointer to a UserData contract, or null.
		; NOTES: Returns a pointer to the user data associated with the username 'nick', 
		;		 or nullpointer if no such user exists.
		(when (= @0x0 "getuserdata") 
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 0x40)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				[0x0] @@ @0x20
				; No such user - cancel.
				(unless @0x0 (return 0x0 32) )
				
				[0x0] @@(- @0x20 1)
				(return 0x0 32)
	
			}
		)
		
		
		; USAGE: 0 : "getuserdataaddr", 32: address
		; RETURNS: Pointer to UserData contract, or null.
		; DEPRECATED: Will be renamed to 'getuserdatabyaddr"
		(when (= @0x0 "getuserdataaddr")
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
				[0x0] @@(- @0x0 1)
				(return 0x0 32)
	
			} ; end when body
		) ;end when
		
		; USAGE: 0 : "getnick", 32: address
		; RETURNS: The username associated with the given address, or null.
		; DEPRECATED: Will be renamed to "getusername"
		(when (= @0x0 "getnick")
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 0x40)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x0] @@ @0x20
				(return 0x0 32)
			} ; end when body
		) ;end when
		
		; USAGE: 0 : "getnickaddr", 32: "nick"
		; NOTES: Returns the address of the user with username 'nick', or null if user does not exist.
		; DEPRECATED: Will be renamed to "hasuser" when making into a proper Group.
		(when (= @0x0 "getnickaddr") ;Get nick holders address (if any)
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 0x40)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x0] @@ @0x20
				(return 0x0 32)
			} ; end when body
		) ;end when
		
		; USAGE: 0 : "isingroup", 32: "nick", 64 : "groupname"
		; RETURNS: 1 if user with name "nick" is member of the group "groupname".
		(when (= @0x0 "isingroup") 
			{
				; Don't let caller access the reserved addresses.
				(unless (&& (> (calldataload 32) 0x40) (> (calldataload 64) 0x40) )
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x40] @@(- (calldataload 32) 1)
				
				; If user does not exist
				(unless @0x40
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
								
				[0x0] "hasuser"
				[0x20] (calldataload 32)
				(call (- (GAS) 100) @0x40 0 0x0 64 0x20 32)
					
				(return 0x20 32)
			}
		)
		
		; USAGE: 0 : "isingroupaddr", 32: user address, 64 : "groupname"
		; RETURNS: 1 if user with the given address is member of the group "groupname".
		(when (= @0x0 "isingroupaddr") 
			{
				; Don't let caller access the reserved addresses.
				(unless (&& (> (calldataload 32) 0x40) (> (calldataload 64) 0x40) )
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x40] @@(- @@(calldataload 32) 1)
				
				; If user does not exist
				(unless @0x40
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
								
				[0x0] "hasuser"
				[0x20] (calldataload 32)
				(call (- (GAS) 100) @0x40 0 0x0 64 0x20 32)
					
				(return 0x20 32)
			}
		)
		
		; USAGE: 0 : "isgroup", 32: "nick"
		; RETURNS: 1 if user with name "nick" is a group.
		(when (= @0x0 "isgroup") 
			{
				; Don't let caller access the reserved addresses.
				(unless (&& (> (calldataload 32) 0x40) (> (calldataload 64) 0x40) )
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x40] @@(calldataload 32)
				
				; If user does not exist
				(unless @0x40
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
								
				[0x0] "gettype"
				[0x20] (calldataload 32)
				(call (- (GAS) 100) @0x40 0 0x0 64 0x20 32)
								
				(return 0x20 32)
			}
		)
		
		; USAGE: 0 : "lock"
		; NOTES: Locks the users contract, making it impossible to register new users.
		; RETURNS: 1 if successful, otherwise 0.
		(when (= @0x0 "lock") 
			{
				(when @@0x15 ; If already locked - cancel.
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
				
				[[0x15]] 1 ; Lock.
				
				[0x0] 1
				(return 0x0 32)
			}
		)
		
		; USAGE: 0 : "unlock"
		; NOTES: Unlocks the users contract.
		; RETURNS: 1 if successful, otherwise 0.
		(when (= @0x0 "unlock") 
			{
				(unless @@0x15 ; If registration is not locked - cancel.
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
				
				[[0x15]] 0 ; Lock.
				
				[0x0] 1
				(return 0x0 32)
			}
		)
		
		; USAGE:  0 : "validatename", 32 : "name"
		; RETURNS: 1 if successful, 0 if not.
		; NOTES: Does a regex-type check of a string. To pass, it may only contain
		;		 alphanumeric characters, no spaces, and be between 3 and 20 chars long (inclusive)
		(when (= @0x0 "islocked")  ;Check that string is a proper name
			{
				[0x0] @@0x15
				(return 0x0 32)
			}
		)
		
		; USAGE:  0 : "validatename", 32 : "name"
		; RETURNS: 1 if successful, 0 if not.
		; NOTES: Does a regex-type check of a string. To pass, it may only contain
		;		 alphanumeric characters, no spaces, and be between 3 and 20 chars long (inclusive)
		(when (= @0x0 "validatename")  ;Check that string is a proper name
			{
				; First three must be alphanumeric.
				[0x60] 0
				(while (< @0x60 3)
					{
						[0x80] (byte @0x60 @0x20)
						(unless (|| (&& (> @0x80 47) (< @0x80 58)  ) 
									(&& (> @0x80 64) (< @0x80 91)  ) 
									(&& (> @0x80 96) (< @0x80 123) ) 
									(&& (> @0x80 191) (< @0x80 215))
									(&& (> @0x80 215) (< @0x80 247))
									(&& (> @0x80 247) (< @0x80 256)) )
							{
								[0x0] 0
								(return 0x0 32)
							}
						)
						[0x60] (+ @0x60 1)
					}
				)
				(while (< @0x60 20)
					{
						[0x80] (byte @0x60 @0x20)
						(unless (|| (&& (> @0x80 47) (< @0x80 58)  )
									(&& (> @0x80 64) (< @0x80 91)  )
									(&& (> @0x80 96) (< @0x80 123) )
									(&& (> @0x80 191) (< @0x80 215))
									(&& (> @0x80 215) (< @0x80 247))
									(&& (> @0x80 247) (< @0x80 256))
									(= @0x80 0) )
							{
								[0x0] 0
								(return 0x0 32)
							}
						)
						; After a blank, the rest must be blanks too.
						(unless @0x80
							{
								[0x60] (+ @0x60 1) ; skip ahead by one.
								
								(while (< @0x60 20)
									{
										[0x80] (byte @0x60 @0x20)
										(when @0x80 ; If not blank - cancel.
											{
												[0x0] 0
												(return 0x0 32)
											}
										)
										[0x60] (+ @0x60 1)
									}
								)
								[0x60] (- @0x60 1) ; back one step since it will be incremented before escaping the loop.
							}
						)
						[0x60] (+ @0x60 1)
					}
				)
				(while (< @0x60 32)
					{
						[0x80] (byte @0x60 @0x20)
						(when @0x80 ; If not blank - cancel.
							{
								[0x0] 0
								(return 0x0 32)
							}
						)
						[0x60] (+ @0x60 1)
					}
				)
				
				[0x0] 1
				(return 0x0 32)
			}
		)
		
		; USAGE:  0 : "createholdings"
		; RETURNS: Address of the new contract.
		; NOTES: Creates an empty holdings contract.
		(when (= @0x0 "createholdings")  ;Check that string is a proper name
			{
				[0x0](LLL
				{
				
				; Get some stuff to start out with.
				[0x0] "Cardboard Box"
				[[@0x0]] 1
				[[(- @0x0 1)]] "personal"
				[[(- @0x0 2)]] "misc"
				
				[0x20] "3-wheeled Shopping Cart"
				[[@0x20]] 1
				[[(- @0x20 1)]] "personal"
				[[(- @0x20 2)]] "misc"
				
				[[0x11]] 2
				[[0x12]] @0x0
				[[0x13]] @0x20
				
				[[(+ @0x0 2)]] @0x20
				[[(+ @0x20 1)]] @0x0
				
				(call (- (GAS) 100) @0x80 0 0xA0 160 0xA0 32)
				
					;body section
					[0x0](LLL
						{
							
							; USAGE: 0 : "postconst", 32 : dougaddress, 64 : owneraddress
							; RETURNS: 1 if successful, 0 if not.
							; NOTES: Set the DOUG address and owner address. This can only be done once.
							; INTERFACE Holdings
							(when (= (calldataload 0) "postconst") 
								{
									(when @@0x10 
										{
											[0x0] 0
											(return 0x0 32)
										}
									) ; Once doug has been set, don't let it be changed externally.
									
									[[0x10]] (calldataload 32)
									[[0x9]] (calldataload 64)
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
							
							; USAGE: 0 : "getowneraddress"
							; RETURNS: The address of the owner.
							; INTERFACE Holdings
							(when (= (calldataload 0) "getowneraddress") ;Anyone can do this.
								{
									[0x0] @@0x9
									(return 0x0 32)
								}
							)
							
							[0x0] (calldataload 0)
							[0x20] (calldataload 32)
							
							; USAGE: 0: "getitem" 32: "name"
							; RETURNS: Pointer to the item with name "name", or null.
							; INTERFACE: Holdings
							(when (= @0x0 "getitem")
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
							
							; USAGE: 0: "getitem" 32: "name"
							; RETURNS: Pointer to the item with name "name", or null.
							; INTERFACE: Holdings
							(when (= @0x0 "getitemfull")
								{
									; Don't let caller access the reserved addresses.
									(unless (> @0x20 0x40)
										{
											[0x0] 0
											(return 0x0 32)
										}
									)
									[0x0] @@ (calldataload 32)
									[0x20] @@(- (calldataload 32) 1)
									[0x40] @@(- (calldataload 32) 2)
									[0x60] @@(- (calldataload 32) 3)
									(return 0x0 128)
								}
							)
							
							[0x40] (calldataload 64)
							
							; USAGE: 0: "additem" 32: "name", 64: amount, 96 : type, 128 : subtype, 160 : address (optional)
							; RETURNS: 1 if new registration, 2 if adding to an existing item, 0 if fail.
							; INTERFACE Holdings
							(when (= @0x0 "additem")
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
									
									;If the item already exists, add to the amount.
									(when @@ @0x20 
										{
											[[@0x20]] (+ @@ @0x20 @0x40)
											[0x0] 2
											(return 0x0 32)
										}
									)
									
									;Store amount at name.
									[[@0x20]] @0x40
									[[(- @0x20 1)]] (calldataload 96)  ; type
									[[(- @0x20 2)]] (calldataload 128) ; subtype
									[[(- @0x20 3)]] (calldataload 160) ; address
						
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
							
							; USAGE: 0: "removeitem" 32: "name", 64 : amount
							; RETURNS: 1 if removing, 2 if subtracting from amount, 0 if fail.
							; INTERFACE Holdings
							(when (= @0x0 "removeitem")
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
									
									;If the name has no address (does not exist) - cancel.
									[0x40] @@ @0x20
									(unless @0x40 
										{
											[0x0] 0
											(return 0x0 32)
										}
									)
									
									; Subtract from the current amount if it remains larger then 0
									(when (< (calldataload 64) @0x40)
										{
											[[@0x20]] (- @0x40 (calldataload 64))
											[0x0] 2
											(return 0x0 32)
										}
									)
									
									; If no items left - remove it entirely.
						
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
									[[(- @0x20 1)]] 0	;The address for its type
									[[(- @0x20 2)]] 0	;The address for its subtype
									[[(- @0x20 3)]] 0	;The address for the items optional contract address
											
									;Decrease the size counter
									[[0x11]] (- @@0x11 1)
									[0x0] 1
									(return 0x0 32)
								} ; end when body
							) ;end when
																
							; USAGE: 0 : "kill"
							; RETURNS: 0 if fail.
							; NOTES: Suicide the contract if 'actions' is the calling contract.
							(when (= (calldataload 0) "kill")
								{
									[0x0] "get"
									[0x20] "users"
									(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32);
									
									(unless (= (CALLER) @0x0) 
										{
											[0x0] 0
											(return 0x0 32)
										}
									)
									
									(suicide (CALLER))
								}
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
		
		[0x0] 0
		(return 0x0 32)
		
	} 0x0 ) ) ; End of body
}