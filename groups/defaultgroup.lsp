{
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
			
			; USAGE: 0 : "generate"
			; RETURNS: Pointer to a Group contract.
			; INTERFACE Factory<Group>
			(when (= (calldataload 0) "generate")
				{
					
					[0x0](LLL
						{
							[[0x1]] "defaultgroup"
						   ;[[0x2]] capacity 
						   ;[[0x8]] group name
						   
							;body section
							[0x0](LLL
								{
									; USAGE: 0 : "setdoug", 32 : dougaddress
									; RETURNS: 1 if successful, 0 if not.
									; NOTES: Set the DOUG address. This can only be done once.
									; INTERFACE Group
									(when (= (calldataload 0) "setdoug")
										{
											(when @@0x10 
												{
													[0x0] 0
													(return 0x0 32)
												}
											) ; Once doug has been set, don't let it be changed.
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
									
									[0x0] (calldataload 0)		;This is the command
									[0x20] (calldataload 32)	;This is the name
									
									; USAGE: 0 : "adduser", 32 : "username", 64: user address
									; RETURNS: 1 if successful, otherwise 0
									; NOTES: Add a user to this group. If successful, it will add the
									;		 username and address. In the case of userdata, the addres
									;		 refers not to the user address, but the address of the
									; 		 users user-data.
									; INTERFACE Group
									(when (&& (= @0x0 "adduser") (> @0x20 0x40)) 
										{
											; If there is a size limit, make sure it is not exceeded.
											(when @@0x2
												{
													(unless (< @@0x11 @@0x2)
														{
															[0x0] 0
															(return 0x0 32)	
														}
													)
												}
											)
											
											(when @@ @0x20
												{
													[0x0] 0
													(return 0x0 32)	
												}
											)
											
											[0x40] "get"
											[0x60] "actions"
											(call (- (GAS) 100) @@0x10 0 0x40 64 0x80 32)
											
											(when @0x80 ; If so, validate the caller to make sure it's a proper action.
												{
													[0x40] "validate"
													[0x60] (CALLER)
													(call (- (GAS) 100) @0x80 0 0x40 64 0x40 32)
													
													(unless @0x40 (return 0x40 32) )		
												}
											)
											
											[0x40] (calldataload 64)							
											;Store user data address at name, and name at user data address.
											[[@0x20]] @0x40
											[[@0x40]] @0x20
			
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
									
									; USAGE: 0 : "removeuser", 32 : "username"
									; RETURNS: 1 if successful, otherwise 0.
									; NOTES: Removes the user "username" from the group (if he exists).
									; INTERFACE Group
									(when (&& (= @0x0 "removeuser") (> @0x20 0x40) ) ; When de-regging by name.
										{
											(unless @@ @0x20
												{
													[0x0] 0
													(return 0x0 32)
												}
											)
									
											[0x40] "get"
											[0x60] "actions"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x80 32)
											
											(when @0x80 ; If so, validate the caller to make sure it's a proper action.
												{
													[0x40] "validate"
													[0x60] (CALLER)
													(call (- (GAS) 100) @0x80 0 0x40 64 0x40 32)
													; Second part of || is because we want groups to 
													; be able to delete not just references, but 
													; whole cross references.
													(unless (|| @0x40 (= (CALLER) @@ @0x20) ) (return 0x40 32) )		
												}
											)
											
											(unless @@ @0x20 
												{
													[0x0] 0
													(return 0x0 32)
												}
											)
											
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
															; And set it as new tail.
															[[0x12]] @0x60
														}
													)
													
													;Don't change the head, as this cannot have been the head.
												}
												;If this element is the head - unset 'next' for the previous element making it the head.
												{
													(if @0x40
														{
															[[(+ @0x40 2)]] 0
															;Set previous as head
															[[0x13]] @0x40		
														}
														{
															;No more elements.
															[[0x12]] 0
															[[0x13]] 0
														}
													)
													
												}
											)

											;Now clear out this element and all its associated data.
											[[@0x20]] 0			;The address of the name
											[[@@ @0x20]] 0
											[[(+ @0x20 1)]] 0	;The address for its 'previous'
											[[(+ @0x20 2)]] 0	;The address for its 'next'
					
											;Decrease the size counter
											[[0x11]] (- @@0x11 1)
											[0x0] 1
											(return 0x0 32)

										} ; end when body
									) ;end when									
									
									
									; USAGE: 0 : "hasuser", 32 : "username"
									; RETURNS: Returns the address coupled with the user "username", or null.
									; INTERFACE: Group
									(when (&& (= @0x0 "hasuser") (> @0x20 0x40) )
										{
											[0x0] @@ @0x20
											(return 0x0 32)
										}
									)
							
									; USAGE: 0 : "gettype"
									; RETURNS: Returns the type of the group.
									; INTERFACE: Group
									(when (= (calldataload 0) "gettype") 
										{		
											[0x0] @@0x1
											(return 0x0 32)
										}
									)
									
									; USAGE: 0 : "capacity"
									; RETURNS: Returns the capacity of the group (0 means no limit)
									; INTERFACE: Group
									(when (= (calldataload 0) "capacity") ; 0 means no size limit.
										{		
											[0x0] @@0x2
											(return 0x0 32)
										}
									)
									
									; USAGE: 0 : "setcapacity", 32 : new capacity
									; RETURNS: 0 - this is not allowed in UserData
									; INTERFACE: Group
									(when (= (calldataload 0) "setcapacity")
										{
											[0x40] "get"
											[0x60] "actions"
											(call (- (GAS) 100) @@0x10 0 0x40 64 0x80 32)
											
											(when @0x80 ; If so, validate the caller to make sure it's a proper action.
												{
													[0x40] "validate"
													[0x60] (CALLER)
													(call (- (GAS) 100) @0x80 0 0x40 64 0x40 32)
													
													(unless @0x40 (return 0x40 32) )		
												}
											)
											
											(when (> @@0x11 (calldataload 32) ); If the group has more elements then new capacity - don't allow.
												{
													[0x0] 0
													(return 0x0 32)
												}
											) 
											
											[[0x2]] (calldataload 32)
											[0x0] 1
											(return 0x0 32)
										}
									)
									
									; USAGE: 0 : "currentsize"
									; RETURNS: Returns the current number of users in the group.
									; INTERFACE: Group
									(when (= (calldataload 0) "currentsize")
										{		
											[0x0] @@0x11 
											(return 0x0 32)
										}
									)
									
									; USAGE: 0 : "clear"
									; RETURNS: Returns 0 (not allowed in UserData)
									; INTERFACE: Group
									(when (= (calldataload 0) "clear")
										{		
											[0x40] "get"
											[0x60] "actions"
											(call (- (GAS) 100) @@0x10 0 0x40 64 0x80 32)
											
											(when @0x80 ; If so, validate the caller to make sure it's a proper action.
												{
													[0x40] "validate"
													[0x60] (CALLER)
													(call (- (GAS) 100) @0x80 0 0x40 64 0x40 32)
													
													(unless @0x40 (return 0x40 32) )		
												}
											)
											
											; If the group is empty, return.
											(unless @@0x11 
												{
													[0x0] 1
													(return 0x0 32)
												}
											)
											
											;Get users to 0x0
											[0x0] "get"
											[0x20] "users"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
											
											;Start at tail
											[0x20] @@0x12
											
											; While we have a next element.
											(while @0x20
												{
													; Remove this group from the userdata of the current
													; group member.
													[0x40] "getuserdata"
													[0x60] @0x20
													(call (- (GAS) 100) @0x0 0 0x40 64 0x40 32)
													
													[0x60] "removeuser"
													[0x80] @@0x8 ; This groups name
													(call (- (GAS) 100) @0x40 0 0x60 64 0x40 32)
													
													;Do a little thing.
													[0x40] @0x20
													[0x20] @@(+ @0x20 2)
													;Now clear this entry.
													[[@0x40]] 0
													[[(+ @0x40 1)]] 0
													[[(+ @0x40 2)]] 0
													[0x0] 9
												}	
											)
											; Clear size, head and tail.
											[[0x11]] 0
											[[0x12]] 0
											[[0x13]] 0
											
											[0x0] 1
											(return 0x0 32)
										}
									)
									
									; USAGE: 0 : "setname" "name"
									; RETURNS: 0 (not allowed in UserData)
									; INTERFACE: Group
									(when (&& (= (calldataload 0) "setname") (> (calldataload 32) 0x20) );clean up
										{
											[0x40] "get"
											[0x60] "actions"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x80 32)
											
											(when @0x80 ; If so, validate the caller to make sure it's a proper action.
												{
													[0x40] "validate"
													[0x60] (CALLER)
													(call (- (GAS) 100) @0x80 0 0x40 64 0x40 32)
													(unless @0x40 (return 0x40 32) )		
												}
											)
									
											[[0x8]] (calldataload 32)
										}
									)
									
									; USAGE: 0 : "kill"
									; RETURNS: -
									; NOTE: suicides the contract if called by "actions".	
									(when (= (calldataload 0) "kill")
										{
											[0x40] "get"
											[0x60] "actions"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x80 32)
											
											(when @0x80 ; If so, validate the caller to make sure it's a proper action.
												{
													[0x40] "validate"
													[0x60] (CALLER)
													(call (- (GAS) 100) @0x80 0 0x40 64 0x40 32)
													(unless @0x40 (return 0x40 32) )		
												}
											)
									
											(suicide (CALLER))
										}
									)
									
								} 0x20 
							)
							(return 0x20 @0x0) ;Return body
						} 0x20 
					)
					[0x0](CREATE 0 0x20 @0x0)
					(return 0x0 32)
				}
			)
			
			[0x0] "get"
			[0x20] "usertypes"
			(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
			
			; Only 'usertypes' can do this.
			(when (&& (= (CALLER) @0x40) (= (calldataload 0) "kill")) (suicide (CALLER)) )
					
		} 0x20 )
	(return 0x20 @0x0) ;Return body
}