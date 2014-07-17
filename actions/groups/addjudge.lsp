{
	[[0x9]] "autopass" ; Default vote type
	
	;body section
	[0x0](LLL
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
			
			(when (= (calldataload 0 ) "getpoll") 
				{
					[0x0] @@0x9
					(return 0x0 32)
				}
			)
			
			[0x0] "get"
			[0x20] "actiontypes"
			(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
			
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
											
											(when (= (calldataload 0) "getpoll") ;Anyone can do this.
												{
													[0x0] @@0x9
													(return 0x0 32)
												}
											)
											
											(when (= (calldataload 0) "init") 
												{
													[0x0] "get"
													[0x20] "actions"
													(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
													
													(unless (= (CALLER) @0x0)
														{
															[0x0] 0
															(return 0x0 32)
														}
													) ; Only "actions" can do this.
													
													[0x0] "get"
													[0x20] "users"
													(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
													
													; Get user data to 0x20
													[0x20] "getuserdata"
													[0x40] (calldataload 32)
													(call (- (GAS) 100) @0x0 0 0x20 64 0x20 32)
													(unless @0x20 (return 0x20 32) ) ; If no user, stop.
													
													; Get Court address to 0x40
													[0x40] "getnickaddr"
													[0x60] "Court"
													(call (- (GAS) 100) @0x0 0 0x40 64 0x40 32)
													(unless @0x40 (return 0x40 32) ) ; If no group exists - cancel.
													
													[0x60] "capacity"
													(call (- (GAS) 100) @0x40 0 0x60 32 0x60 32)
													
													[0x80] "currentsize"
													(call (- (GAS) 100) @0x40 0 0x80 32 0x80 32)
													
													(when (>= @0x80 @0x60) ; If there is no more room - cancel.
														{
															[0x0] 0
															(return 0x0 32)
														}
													)
													
													; Check that the user is a citizen, and is not in any of the other groups.
													[0x60] "hasuser"
													[0x80] "Citizens"
													(call (- (GAS) 100) @0x20 0 0x60 64 0x60 32)
													(unless @0x60 (return 0x60 32) )
													
													[0x60] "hasuser"
													[0x80] "Senate"
													(call (- (GAS) 100) @0x20 0 0x60 64 0x60 32)
													(when @0x60 
														{
															[0x0] 0 
															(return 0x0 32)
														}
													)
													
													[0x60] "hasuser"
													[0x80] "SysAdmin"
													(call (- (GAS) 100) @0x20 0 0x60 64 0x60 32)
													(when @0x60 
														{
															[0x0] 0 
															(return 0x0 32)
														}
													)
													
													[[0x11]] (calldataload 32)
													
													[0x0] 1
													(return 0x0 32)
												}
											)
											
											(when (= (calldataload 0) "execute")
												{
													[0x0] "get"
													[0x20] "actions"
													(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
													
													(unless (= (CALLER) @0x0)
														{
															[0x0] 0
															(return 0x0 32)
														}
													) ; Only "actions" can do this.
													
													[0x0] "get"
													[0x20] "users"
													(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
													
													; Get user data to 0x20
													[0x20] "getuserdata"
													[0x40] @@0x11
													(call (- (GAS) 100) @0x0 0 0x20 64 0x20 32)
													(unless @0x20 (return 0x20 32) ) ; If no user, stop.
													
													; Get Court address to 0x40
													[0x40] "getnickaddr"
													[0x60] "Court"
													(call (- (GAS) 100) @0x0 0 0x40 64 0x40 32)
													(unless @0x40 (return 0x40 32) ) ; If no 'Court' group exists - cancel.
													
													; Check that the user is a citizen, and is not in any of the other groups.
													[0x60] "hasuser"
													[0x80] "Citizens"
													(call (- (GAS) 100) @0x20 0 0x60 64 0x60 32)
													(unless @0x60 (return 0x60 32) )
													
													[0x60] "hasuser"
													[0x80] "Senate"
													(call (- (GAS) 100) @0x20 0 0x60 64 0x60 32)
													(when @0x60 
														{
															[0x0] 0 
															(return 0x0 32)
														}
													)
													
													[0x60] "hasuser"
													[0x80] "SysAdmin"
													(call (- (GAS) 100) @0x20 0 0x60 64 0x60 32)
													(when @0x60 
														{
															[0x0] 0 
															(return 0x0 32)
														}
													)
													
													; Add the user to the group. Size constraints and 'double adding' will be resolved here.
													[0x60] "adduser"
													[0x80] @@0x11
													[0xA0] @0x20
													(call (- (GAS) 100) @0x40 0 0x60 96 0xC0 32)
													(unless @0xC0 (return 0xC0 32) )
													
													[0x60] "adduser"
													[0x40] "Court"
													[0x80] @0x40
													(call (- (GAS) 100) @0x20 0 0x60 96 0x40 32)
													(unless @0x40 (return 0x40 32) )
													
													[0x0] 1
													(return 0x0 32)
												}
											)
													
											[0x0] "get"
											[0x20] "actions"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32) ;Actions at 0x0
											
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
			
			(when (= (calldataload 0) "autoexecute")
				{
					[0x0] "get"
					[0x20] "actions"
					(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
					
					(unless (= (CALLER) @0x0)
						{
							[0x0] 0
							(return 0x0 32)
						}
					) ; Only "actions" can do this.
					
					[0x0] "get"
					[0x20] "users"
					(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
					
					; Get user data to 0x20
					[0x20] "getuserdata"
					[0x40] (calldataload 32)
					(call (- (GAS) 100) @0x0 0 0x20 64 0x20 32)
					(unless @0x20 (return 0x20 32) ) ; If no user, stop.
					
					; Get Court address to 0x40
					[0x40] "getnickaddr"
					[0x60] "Court"
					(call (- (GAS) 100) @0x0 0 0x40 64 0x40 32)
					(unless @0x40 (return 0x40 32) ) ; If no 'Court' group exists - cancel.
					
					; Check that the user is a citizen, and is not in any of the other groups.
					[0x60] "hasuser"
					[0x80] "Citizens"
					(call (- (GAS) 100) @0x20 0 0x60 64 0x60 32)
					(unless @0x60 (return 0x60 32) )
					
					[0x60] "hasuser"
					[0x80] "Senate"
					(call (- (GAS) 100) @0x20 0 0x60 64 0x60 32)
					(when @0x60 
						{
							[0x0] 0 
							(return 0x0 32)
						}
					)
					
					[0x60] "hasuser"
					[0x80] "SysAdmin"
					(call (- (GAS) 100) @0x20 0 0x60 64 0x60 32)
					(when @0x60 
						{
							[0x0] 0 
							(return 0x0 32)
						}
					)
					
					; Add the user to the group. Size constraints and 'double adding' will be resolved here.
					[0x60] "adduser"
					[0x80] (calldataload 32)
					[0xA0] @0x20
					(call (- (GAS) 100) @0x40 0 0x60 96 0xC0 32)
					(unless @0xC0 (return 0xC0 32) )
					
					[0x60] "adduser"
					[0x40] "Court"
					[0x80] @0x40
					(call (- (GAS) 100) @0x20 0 0x60 96 0x40 32)
					(unless @0x40 (return 0x40 32) )
					
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