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
			
			; USAGE: 0 : "isautopass"
			; RETURNS: 1 if autopass, otherwise 0.
			; INTERFACE Poll
			(when (= (calldataload 0) "isautopass") 
				{
					[0x0] 0
					(return 0x0 32)
				}
			)
			
			; USAGE: 0 : "gettimelimit"
			; RETURNS: 1 if success, otherwise 0.
			; NOTE set the time limit (in seconds) before the poll expires.
			; INTERFACE Poll
			(when (= (calldataload 0) "gettimelimit") 
				{
					[0x0] @@0x1
					(return 0x0 32)
				}
			)
			
			[0x0] "get"
			[0x20] "polltypes"
			(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
			
			; USAGE: 0 : "settimelimit", 32 : timelimit
			; RETURNS: 1 if success, otherwise 0.
			; NOTE set the time limit (in seconds) before the poll expires.
			; INTERFACE Poll
			(when (= (calldataload 0) "settimelimit") 
				{
					(unless (= (CALLER) @0x40)
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					[[0x1]] (calldataload 32)
					[0x0] 0
					(return 0x0 32)
				}
			)
			
			(when (= (calldataload 0) "get")
				{
					[0x0](LLL
						{
						   ;[[0x1]] reserved for total number of eligible voters at poll creation.
						   ;[[0x2]] reserved for current number of votes
						   ;[[0x3]] reserved for current vote sum;
							[[0x4]] 0x12
						   ;[[0x5]] reserved for timestamp
						   ;[[0x6]] reserved for time limit
						   ;[[0x7]] reserved for state (started/finalized)
						   ;[[0x8]] reserved for quorum
						   ;[[0x10]] reserved for DOUG address.
						   ;[[0x12]] and onwards is reserved for voters.
							;body section
							[0x0](LLL
								{
											
									; USAGE: 0 : "setdata", 32 : timelimit, 64 : quorum
									; RETURNS: 1 if success, otherwise 0.
									; NOTE set the time limit (in seconds) before the poll expires.
									; INTERFACE Poll
									(when (= (calldataload 0) "setdata") 
										{
											
											(when @@0x10
												{
													[0x0] 0
													(return 0x0 32)
												}
											)
											
											[[0x10]] (calldataload 32)
											
											[0x0] "get"
											[0x20] "polltypes"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
											
											(unless (= (CALLER) @0x40)
												{
													[0x0] 0
													(return 0x0 32)
												}
											)
											[[0x6]] (calldataload 64)
											[[0x8]] (calldataload 96)
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
									
									; USAGE: 0 : "init"
									; RETURNS: 1 if success, 0 otherwise.
									; NOTES: Initialize the poll.
									; INTERFACE Poll
									(when (= (calldataload 0) "init") 
										{
											[0x0] "get"
											[0x20] "actions"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
													
											; If the caller is not the actions contract, skip.
											(unless (= @0x40 (CALLER))  
												{
													[0x0] 0
													(return 0x0 0)
												}
											)
											
											; Basically just check that this is a non-empty
											; group, and store its size in the poll contract.
											
											[0x0] "get"
											[0x20] "users"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
											
											(unless @0x40 (return 0x40 32)) ; No users, no vote.
											
											[0x0] "getnickaddr"
											[0x20] "SysAdmin"
											(call (- (GAS) 100) @0x40 0 0x0 64 0x20 32)
											
											(unless @0x20 (return 0x20 32)) ; No citizens group, no vote.
																						
											[0x0] "currentsize"
											(call (- (GAS) 100) @0x20 0 0x0 32 0x0 32)
											
											(unless @0x0 (return 0x0 32)) ; No citizens - no vote.
											
											[[0x1]] @0x0
											
											[0x0] 1
											(return 0x0 32)
										}
									)
									
									; USAGE: 0 : "start"
									; RETURNS: 1 if success, 0 otherwise.
									; NOTES: Initialize the poll.
									; INTERFACE Poll
									(when (= (calldataload 0) "start") 
										{
											; If poll has already been started.
											(when @@0x7
												{
													[0x0] 0
													(return 0x0 32)
												}
											)
											
											[0x0] "get"
											[0x20] "actions"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
													
											; If the caller is not the actions contract, skip.
											(unless (= @0x40 (CALLER))  
												{
													[0x0] 0
													(return 0x0 0)
												}
											)
											
											[0x0] "get"
											[0x20] "users"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
											
											(unless @0x40 (return 0x40 32)) ; No users, no vote.
											
											[0x0] "getuserdataaddr"
											[0x20] (ORIGIN)
											(call (- (GAS) 100) @0x40 0 0x0 64 0x40 32)
											
											[0x0] "hasuser"
											[0x20] "SysAdmin"
											(call (- (GAS) 100) @0x40 0 0x0 64 0x40 32)
											
											(unless @0x40 (return 0x40 32))
											
											[[0x5]] (TIMESTAMP)
											[[0x7]] 1 ; The poll has now started.
																						
											[0x0] 1
											(return 0x0 32)
										}
									)
									
									; USAGE: 0 : "vote", 32 : vote value, 64 : voter (address)
									; RETURNS: 1 if success, 0 otherwise.
									; NOTES: This is how you vote.
									; INTERFACE Poll
									(when (= (calldataload 0) "vote")
										{	
											(unless (|| (= (calldataload 32) 1) (= (calldataload 32) 2) )  
												{
													[0x0] 0
													(return 0x0 32)
												}
											)
											
											; If poll is not started - cancel.
											(unless ( = @@0x7 1)
												{
													[0x0] 0
													(return 0x0 32)
												}
											)
													
											[0x0] "get"
											[0x20] "actions"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
													
											; If the caller is not the actions contract, skip.
											(unless (= @0x40 (CALLER))  
												{
													[0x0] 0
													(return 0x0 0)
												}
											)
											; If voting time has expired - cancel.
											(unless (< (TIMESTAMP) (+ @@0x6 @@0x5) )
												{
													[0x0] 0
													(return 0x0 32)
												}
											)
											
											[0x0] "get"
											[0x20] "users"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
											
											[0x0] "getuserdataaddr"
											[0x20] (calldataload 64)
											(call (- (GAS) 100) @0x40 0 0x0 64 0x60 32)
											
											; If user does not exist - skip.
											(unless @0x60 
												{
													[0x0] 0
													(return 0x0 32)
												}
											)
											
											[0x0] "hasuser"
											[0x20] "SysAdmin"
											(call (- (GAS) 100) @0x60 0 0x0 64 0x0 32)
											
											(unless @0x0 (return 0x0 32) ) ; Unless user is a citizen - cancel.
											
											; Now the user is confirmed to be a senator.
											
											(when @@(calldataload 64) ; If user has already voted - quit.
												{
													[0x0] 0
													(return 0x0 32)
												}
											)
											
											[0x0] @@0x4
											;Add user address/slot address, and vote result.
											[[(calldataload 64)]] @0x0
											[[@0x0]] (calldataload 64)
											[[(+ @0x0 1)]] (calldataload 32)
											
											[[0x2]] (+ @@0x2 1) ; Increase number of voters.
											[[0x3]] (+ @@0x3 (* (- (calldataload 32) 1) 2)) ; Increase vote sum by 0 or 1.
											[[0x4]] (+ @@0x4 2) ; Increase next slot pointer
											
											; Check if vote is done.
											(when (= @@0x2 @@0x1)
												{
													(if (> @@0x3 @@0x2)
														{ ; If vote is successful.
															[0x0] 2
														}
														{ ; Else
															[0x0] 1
														}
													)
													(return 0x0 32)
												}
											)
											
											; If it reaches this point, voting is not done.
											[0x0] 0 
											(return 0x0 32)
										}
									)
									
									; 0 : "finalize"
									(when (= (calldataload 0) "finalize")
										{
											(unless (= @@0x7 1) 
												{
													[0x0] 0
													(return 0x0 32)
												}
											)
											; If voting time has not expired - cancel.
											(when (< (TIMESTAMP) (+ @@0x6 @@0x5) )
												{
													[0x0] 0
													(return 0x0 32)
												}
											)
											
											;Check against quorum
											(when @@0x8
												{
													(when (< (* 100 @@0x2) (* @@0x1 @@0x8))
														{
															[0x0] 1
															(return 0x0 32)
														}
													)
												}
											)
											
											(if (> @@0x3 @@0x2)
												{ ; If vote is successful.
													[0x0] 2
												}
												{ ; Else
													[0x0] 1
												}
											)
											[[0x7]] 2 ; Done
											(return 0x0 32)
											
										}
									)
									
									(when (= (calldataload 0) "kill") ;clean up
										{
											[0x0] "get"
											[0x20] "actions"
											(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32) ;Votes at 0x0
											
											(unless (= (CALLER) @0x0) 
												{
													[0x0] 0
													(return 0x0 32)
												} 
											) ; Only 'actions' can do this.
											(suicide (CALLER))
										}
									)
											
								} 0x20 )
							(return 0x20 @0x0) ;Return body
						} 0x20 )
					[0x0](CREATE 0 0x20 @0x0)
					(return 0x0 32)
				}
			)
			
			; Only 'polltypes' can do this.
			(when (&& (= (CALLER) @0x40) (= (calldataload 0) "kill")) (suicide (CALLER)) )
					
		} 0x20 )
	(return 0x20 @0x0) ;Return body
}