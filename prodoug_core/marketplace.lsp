; Data format
;
; 0 - 31		Meta: address to tail (address, 1 seg)
; 32 - 63		Meta: address to head (address, 1 seg)
; 64 - 95: 		User address (address, 1 seg)
; 96 - 127: 	Date of creation (number, 1 seg)
; 128 - 159:	ItemName (string, 1 seg)
; 160 - 191:	Amount (number, 1 seg)
; 192 - 223:	Price (number, 1 seg)
;
; Total size: 7 segments (224 bytes)

;INIT
{
	;For DOUG integration
	[[0x10]] 0x8bffd298a64ee36eb7b99dcc00d2c67259d15c60 ;Doug Address

	;Pooled address section
	[[0x11]] 0x0   	;Size of pool list
	[[0x12]] 0x19	;Pointer to last added address (0x20 is the real start, 0x19 is "faux", and is never referenced)

	[[0x13]] 0x10020	;Current next address. If pool is empty, add new entries to this address.
						;this allows for 2^16 memory pool addresses (starting at 0x20).
	[[0x14]] 2			;Data contents offset from address (data and data + 1 contains meta stuff)
	;Data section
	[[0x15]] 7			;Size of a data element (in storage addresses).
	[[0x16]] 0x0		;Number of data entries
	[[0x17]] 0x0		;Current tail
	[[0x18]] 0x0		;Current head
	
	[0x0] "reg"
	[0x20] "marketplace"
	(call (- (GAS) 100) @@0x10 0 0x0 0x40 0x0 0x20) ;Register with DOUG TODO remove after beta
	
	(return 0x0 (lll 
	{
		
		[0x0] (calldataload 0)	;This is the command
		
		[0x20] (calldataload 32)
	
		; USAGE: 0 : "kill"
		; RETURNS: -
		; NOTES: Only doug can do this.
		(when (&& (= @0x0 "kill") (= (CALLER) @@0x10) ) (suicide (CALLER)) ) ;Kill option
		
		; USAGE: 0 : "post", 32 : payload (name:amount:price)
		; RETURNS: 1 if successful, 0 if fail.
		; INTERFACE: Marketplace
		(when (&& (= @0x0 "post") (> @0x20 0x40) ) ;When posting an entry.
			{
				[0x60] "get"
				[0x80] "actions"
				(call (- (GAS) 100) @@0x10 0 0x60 64 0xA0 32) ; Check if there is a votes contract.
				
				(when @0xA0 ; If so, validate the caller to make sure it's a proper action.
					{
						[0x60] "validate" ; TODO create a "secure validate", with more checks.
						[0x80] (CALLER)
						(call (- (GAS) 100) @0xA0 0 0x60 64 0x60 32)
				
						(unless @0x60 (return 0x60 32) )
					}
				)
						
				;Check if the address pool has any addresses in it that we can use.
				(if (> @@0x11 0) ; If pool list has elements in it
					{
						[0x60] @@ @@0x12 ;The address where this entry will be put.
						;Decrease pointer and size
						[[0x12]] (- @@0x12 1)
						[[0x11]] (- @@0x11 1)
					}
					{
						;If there are no pooled addresses, assign from 0x13 and increment by the size of a data entry.
						[0x60] @@0x13
						[[0x13]] (+ @@0x13 @@0x15)
					}
				)
	
				;Add this element as the current head to the data list.
				(if @@0x16 ; If the list of data is non-empty
					{
						;Update the list. First set the 'next' of the current head to be this one.
						[[(+ @@0x18 1)]] @0x60
						;Now set the current head as this ones 'previous'.
						[[@0x60]] @@0x18
						;And set this as the new head.
						[[0x18]] @0x60
						;Increase the list size by one.
						[[0x16]] (+ @@0x16 1)
					}
					{
						;If the data list is empty, add this as current head and tail.
						[[0x17]] @0x60
						[[0x18]] @0x60
						[[0x16]] 1
					}
				)
				
				;0x60 is the alloted address. Add uploader first.
				[[(+ @0x60 2)]] (ORIGIN)
				;Created
				[[(+ @0x60 3)]] (TIMESTAMP)
				;Name
				[[(+ @0x60 4)]] (calldataload 32)
				;Amount
				[[(+ @0x60 5)]] (calldataload 64)
				;Price
				[[(+ @0x60 6)]] (calldataload 96)
				
				[0x0] 1
				(return 0x0 32)
				
			} ;end body of when
		); end when
	
		; USAGE: 0 : "remove", 32 : address
		; RETURNS: 1 if successful, 0 if fail.
		; INTERFACE: Marketplace
		(when (&& (= @0x0 "remove") (>= @0x20 0x10020) )  ; When deleting a post.
			{
				[0x60] "get"
				[0x80] "actions"
				(call (- (GAS) 100) @@0x10 0 0x60 64 0xA0 32) ; Check if there is a votes contract.
				
				(when @0xA0 ; If so, validate the caller to make sure it's a proper action.
					{
						[0x60] "validate" ; TODO create a "secure validate", with more checks.
						[0x80] (CALLER)
						(call (- (GAS) 100) @0xA0 0 0x60 64 0x60 32)
				
						(unless @0x60 (return 0x60 32) )
					}
				)
	
				; Now remove the list entry.
	
				[0x40] @@ @0x20 ; Here we store the this ones 'previous'.
				[0x60] @@ (+ @0x20 1) ; And next
				
				(if (&& (= @0x40 0) (= @0x60 0)) ;If this is the only element in the list.
					{
						; Clear the list completely (decreasing list size at 0x16 later.
						[[0x17]] 0
						[[0x18]] 0 
					}
					{
						;If we have a 'next'
						(if @0x60
							{
								;If we also have a 'prev'
								(if @0x40 
									{
										;Change next elements 'previous' to this ones 'previous'.
										[[@0x60]] @0x40
										;Change previous elements 'next' to this ones 'next'.
										[[(+ @0x40 1)]] @0x60
									}
									; otherwise we are the tail. Change next element to tail.
									{
										; Clear the previous element of 'next'
										[[@0x60]] 0
										; Set it as tail.
										[[0x17]] @0x60
									}
								)
							}
							;This element is the head..
							{
								; If it has other elements behind it.
								(if @0x40 
									{
										; Set 'next' of previous element to 0
										[[(+ @0x40 1)]] 0
										;Set previous as head
										[[0x18]] @0x40
									}
									{
										; List is empty.
										[[0x17]] 0
										[[0x18]] 0
									}
								)
							}
						)
					}
				)
	
				;Decrease the size counter
				[[0x16]] (- @@0x16 1)
	
				;Clear out this element fully, and add its address to the address pool, and increase address pool size.
	
				[0x40] (+ @@0x12 1) ;The next address.
				[[@0x40]] @0x20 ;Set the contents of the next address to be this address
				[[0x12]] @0x40  ;Set the latest added address to be next.
				[[0x11]] (+ @@0x11 1) ;Increment the size of the memory pool.
				
				[[@0x20]] 0			; The address (containing 'previous')
				[[(+ @0x20 1)]] 0	; The address for its 'next'
				[[(+ @0x20 2)]] 0	; Poster address
				[[(+ @0x20 3)]] 0	; Timestamp
				[[(+ @0x20 4)]] 0	; Item Name
				[[(+ @0x20 5)]] 0	; Amount
				[[(+ @0x20 6)]] 0	; Price
				
				[0x0] 1
				(return 0x0 0x20)
	
			} ; end when body
		) ;end when
		
		; USAGE: 0 : "getposter", 32 : entry address
		; RETURNS: The address of the person that posted the entry.
		; INTERFACE: Marketplace
		(when (&& (= @0x0 "getposter") (>= @0x20 0x10020) ) 
			{
				[0x0] @@(+ @0x20 2)
				(return 0x0 32)
			}
		)
		
		; USAGE: 0 : "gettimestamp", 32 : entry address
		; RETURNS: The timestamp of the entry.
		; INTERFACE: Marketplace
		(when (&& (= @0x0 "gettimestamp") (>= @0x20 0x10020) ) 
			{
				[0x0] @@(+ @0x20 3)
				(return 0x0 32)
				
			}
		)
		
		; USAGE: 0 : "getitemname", 32 : entry address
		; RETURNS: The name of the item posted at entry address
		; INTERFACE: Marketplace
		(when (&& (= @0x0 "getitemname") (>= @0x20 0x10020) )
			{
				[0x0] @@(+ @0x20 4)
				(return 0x0 32)
				
			}
		)
		
		; USAGE: 0 : "getamount", 32 : entry address
		; RETURNS: The amount of items sold in this entry.
		; INTERFACE: Marketplace
		(when (&& (= @0x0 "getamount") (>= @0x20 0x10020) ) 
			{
				[0x0] @@(+ @0x20 5)
				(return 0x0 32)
				
			}
		)
		
		; USAGE: 0 : "getprice", 32 : entry address
		; RETURNS: The buying price for the entry.
		; INTERFACE: Marketplace
		(when (&& (= @0x0 "getprice") (>= @0x20 0x10020) ) 
			{
				[0x0] @@(+ @0x20 6)
				(return 0x0 32)
			}
		)
		
		; USAGE: 0 : "getentry", 32 : entry address
		; RETURNS: posteraddress:timestamp:item:amount:price (160 bytes)
		; INTERFACE: Exchange
		(when (&& (= @0x0 "getentry") (>= @0x20 0x10020) )
			{
				
				[0x0] @@(+ @0x20 2)
				[0x20] @@(+ @0x20 3)
				[0x40] @@(+ @0x20 4)
				[0x60] @@(+ @0x20 5)
				[0x80] @@(+ @0x20 6)
				(return 0x0 160)
			}
		)
		
		[0x0] 0
		(return 0x0 32)
	}
	0x0 )) ; Return body
	
}