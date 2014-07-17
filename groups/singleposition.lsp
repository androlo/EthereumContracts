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
							[[0x1]] "singleposition"
							[[0x2]] 1 ; capacity
						   ;[[0x3]] currentsize
						   ;[[0x4]] holdername
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
											
											; Make sure user exists.
											[0x40] "get"
											[0x60] "users"
											(call (- (GAS) 100) @@0x10 0 0x40 64 0x80 32)
											
											(unless @0x80 (return 0x80 32) )
											
											[0x40] "getuserdata"
											[0x60] @0x20
											(call (- (GAS) 100) @0x80 0 0x40 64 0x40 32)
											
											(unless @0x40 (return 0x40 32) )
											
											; Current size = 1
											[[0x3]] 1
											; If there is a member being pushed out, clear its name->user data binding.
											(when @@0x4 [[@@0x4]] 0 )
											; Current user = username
											[[0x4]] (calldataload 32)
											; Store user data at user name.
											[[(calldataload 32)]] @0x40
											
											; Current size is 1.
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
											
											[0x0] "get"
											[0x20] "actions"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
											
											(when @0x0 ; If so, validate the caller to make sure it is a proper action.
												{
													[0x20] "validate"
													[0x40] (CALLER)
													(call (- (GAS) 100) @0x0 0 0x20 64 0x20 32)
			
													(unless (|| @0x20 (= (CALLER) @@ (calldataload 32) ) ) (return 0x20 32) )		
												}
											)
											[[0x3]] 0
											[[0x4]] 0
											[[(calldataload 32)]] 0
											[0x0] 1 
											(return 0x0 32)
										} ; end when body
									) ;end when
									
									
									; USAGE: 0 : "hasuser", 32 : "username"
									; RETURNS: Returns the address coupled with the user "username", or null.
									; INTERFACE: Group
									(when (= @0x0 "hasuser") 
										{
											[0x0] @@ (calldataload 32)
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
									
									; USAGE: 0 : "setcapacity"
									; RETURNS: 0 - this is not allowed in UserData
									; INTERFACE: Group
									(when (= (calldataload 0) "setcapacity")
										{
											[0x0] 0
											(return 0x0 32)
										}
									)
									
									; USAGE: 0 : "currentsize"
									; RETURNS: Returns the current number of users in the group.
									; INTERFACE: Group
									(when (= (calldataload 0) "currentsize")
										{		
											[0x0] @@0x3 
											(return 0x0 32)
										}
									)
									
									; USAGE: 0 : "clear"
									; RETURNS: Returns 0 (not allowed in single position)
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
											(unless @@0x3
												{
													[0x0] 1
													(return 0x0 32)
												}
											)
											
											;Get users to 0x0
											[0x0] "get"
											[0x20] "users"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
											
											; Remove this group from the userdata of the current
											; group member.
											[0x40] "getuserdata"
											[0x60] @@0x4
											(call (- (GAS) 100) @0x0 0 0x40 64 0x40 32)
											
											[0x60] "removeuser"
											[0x80] @@0x8
											(call (- (GAS) 100) @0x40 0 0x60 64 0x40 32)
											
											[[0x3]] 0
											[[@@0x4]] 0
						   					[[0x4]] 0
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