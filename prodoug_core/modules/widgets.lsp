; INIT
{	
	;For DOUG integration
	[[0x10]] 0x07a03c311f07ad616e551daaee83e330c702559b ;Doug Address
	;List data section
	[[0x11]] 0x0										;Size of list
	[[0x12]] 0x0										;Tail address
	[[0x13]] 0x0										;Head address
	
	[0x0] "reg"
	[0x20] "widgets"
	(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32) ;Register with DOUG  TODO remove.
	
	(return 0x0 (lll 
	{
		
		[0x0] (calldataload 0)	;This is the command
		[0x20] (calldataload 32)	;This is the name
				
		; USAGE: 0: "haswidget" 32: "name"
		; RETURNS: Pointer to the widget data with name "name", or null.
		; INTERFACE: WidgetManager
		(when (= @0x0 "haswidget")  
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
		
		; USAGE: 0: "reg" 32: "name", 64: address
		; RETURNS: 1 if successful, otherwise 0.
		; INTERFACE WidgetManager
		(when (= @0x0 "reg") 
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
				(call (- (GAS) 100) @@0x10 0 0x60 64 0xA0 32) ; Check if there is an actions contract.
				
				(when @0xA0 ; If so, validate the caller to make sure it's a proper action.
					{
						
						[0x60] "validate"
						[0x80] (CALLER)
						(call (- (GAS) 100) @0xA0 0 0x60 64 0x60 32)
				
						(unless @0x60 (return 0x60 32) )		
					}
				)
				
				;If the name address is non-empty (name already taken) - cancel.
				(when @@ @0x20 
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[0x40] 64
				[0x80] (calldataload @0x40)
				[0xA0] 0
				(while (< @0x40 (calldatasize))
					{
						[[(- @0x20 @0xA0)]] @0x80
						[0x40] (+ @0x40 32)
						[0x80] (calldataload @0x40)
						[0xA0] (+ @0xA0 1)
					}
				)
	
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
	
		; USAGE: 0: "dereg" 32: "name"
		; RETURNS: 1 if successful, otherwise 0.
		; INTERFACE WidgetManager
		(when (= @0x0 "dereg")
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
	
				[0x40] @@ @0x20
				;If the name has no address (does not exist) - cancel.
				(unless @0x40 
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
				
				[0x40] @@ @0x20
				[0x60] 0
				
				(while @0x40
					{
						[[(- @0x20 @0x60)]] 0
						[0x60] (+ @0x60 1)
						[0x40] @@ (- @0x20 @0x60)
					}
				)
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
	}
	0x0))
}