; Set up a simple contract for start, that generates a poll that is accepted/rejected by one single admin.
	
	; Poll generator contracts has two functions:
	; "generate" - creates a poll contract, and returns the address.
	; "kill" - destroys the contract generator. Only 'polltypes' can do that.
	;
	; singleadm is an exception in that it cannot be voted away.

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
									
			(when (= (calldataload 0) "get")
				{
					[0x0](LLL
						{
						   ;[[0x1]] reserved for total number of citizens at poll creation.
						   ;[[0x2]] reserved for current number of votes
						   ;[[0x3]] reserved for current vote sum;
							[[0x4]] 0x12 
						   ;[[0x10]] reserved for DOUG address.
						   ;[[0x12]] and onwards is reserved for people.
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
									
									; 0 : "vote", 32 : vote value, 64 : voter (address)
									(when (= (calldataload 0) "vote")
										{	
											(unless (|| (= (calldataload 32) 1) (= (calldataload 32) 2) )  
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
											[0x20] "Court"
											(call (- (GAS) 100) @0x60 0 0x0 64 0x0 32)
											
											(unless @0x0 (return 0x0 32) )
											
											[0x0] (calldataload 32) 
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
			
			[0x0] "get"
			[0x20] "polltypes"
			(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
			
			; Only 'polltypes' can do this.
			(when (&& (= (CALLER) @0x40) (= (calldataload 0) "kill")) (suicide (CALLER)) )
					
		} 0x20 )
	(return 0x20 @0x0) ;Return body
}