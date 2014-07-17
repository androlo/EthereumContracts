; Andreas' DOUG v1 (based on DOUG v3)
;
; This is a doug type contract. It lets you register contracts by name. It should
; normally be done through actions.

; INIT
{	
	[[0x1]] "PRODOUG"
	
	;List data section
	[[0x11]] 0x0										;Size of list
	[[0x12]] 0x0										;Tail address
	[[0x13]] 0x0										;Head address
	
	; BODY
	(return 0x0 (lll 
	{
	
		[0x0] (calldataload 0)		;This is the command
		[0x20] (calldataload 32)	;This is the name/address
	
		; Don't let people access the reserved addresses.
		(unless (> @0x20 0x40)
			{
				[0x0] 0
				(return 0x0 32)
			}
		)
		
		; USAGE: 0 : "get", 32 : "name"
		; RETURNS: The address of contract stored at name "name", or 0.
		; INTERFACE Doug
		(when (= @0x0 "get")
			{
				[0x0] @@ @0x20
				(return 0x0 32)
			}
		)
	
		[0x40] (calldataload 64) ; Contract address
	
		; USAGE: 0 : "reg", 32 : "name", < 64 : contract address >
		; RETURNS: 2 if successful, 1 if autopassed, 0 if fail.
		; INTERFACE: Doug
		(when (= @0x0 "reg") ;Command "reg" 
			{				
				;When there is an actions contract.
				(when @@"actions"
					{
						(unless (=(calldataload 32) "actions")
							{
								[0x60] "validate"
								[0x80] (CALLER)
								(call (- (GAS) 100) @@"actions" 0 0x60 64 0x60 32)
								(unless @0x60 (return @0x60 32) )		
							}
						)
					} ; when body
				)
				
				; If no address is provided in txdata, use the caller address.
				(unless @0x40
					{
						[0x40] (CALLER)
					}
				)
				
				; If the name is already registered, just overwrite. 
				(when @@ @0x20
					{
						
						; Dump (not implemented in most contracts yet)
						[0x80] "dump"	; Dump data from old contract to new
						[0xA0] @0x40 	; The address of the new contract
						(call (- (GAS) 100) @@ @0x20 0 0x80 64 0x80 32)
						
						; Suicide the de-regged contract. 
						; Don't suicide actions as it is currently running (TODO observe this).
						(unless (= @0x20 "actions")
							{
								[0x80] "kill"
								(call (- (GAS) 100) @@ @0x20 0 0x80 32 0x80 32)
							}
						)
						[[@0x20]] @0x40
						[0x0] 2
						(return 0x0 32)
					}
				)
				
				;Store sender at name.
				[[@0x20]] @0x40
				
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
				;Set this as the new head.
				[[0x13]] @0x20
				
				;Increase the list size by one.
				[[0x11]] (+ @@0x11 1)
				
				;Return the value 2 for a successful register
				[0x0] 2
				(return 0x0 0x20)
			} ;end body of when
		); end when
		
		; USAGE: 0 : "dereg", 32 : "name"
		; RETURNS: 1 if successful, otherwise 0
		; INTERFACE: Doug
		(when (= @0x0 "dereg")  
			{
				;When there is an actions contract.
				(when @@"actions"
					{
						[0x60] "validate"
						[0x80] (CALLER)
						(call (- (GAS) 100) @@"actions" 0 0x60 64 0x60 32)
						(unless @0x60 (return 0x60 32) )
					}
				)
				
				(when (= @0x20 "doug") ; If the contract name is "doug", suicide the contract.
					{
						(suicide (CALLER) )
					}
				)
								
				; Suicide the de-regged contract (TODO observe this)
				[0x80] "kill"
				(call (- (GAS) 100) @@ @0x20 0 0x80 32 0x80 32)
				
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
						
				;Decrease the size counter
				[[0x11]] (- @@0x11 1)
				[0x0] 1
				(return 0x0 32)

			} ; end when body
		) ;end when
		
		[0x0] 0
		(return 0x0 32)

	} 0x0 ) ) ; End of body 
}