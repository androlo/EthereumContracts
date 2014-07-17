{
	; Apartments
	[[0x11]] 0x10000000 ; Starting address
	[[0x12]] 0x10003E80 ; Highest address (5 per house, 20 houses per street)
	[[0x13]] 50	  		; Cost
	[[0x14]] 0x100A 	; Next street address pointer.
	
	; Houses
	[[0x21]] 0x20000000 ; Starting address
	[[0x22]] 0x20000C80 ; Highest address (20 per street)
	[[0x23]] 1000		; Cost
	[[0x24]] 0x200A 	; Next street address pointer.
	
	; Mansions
	[[0x31]] 0x30000000 ; Starting address
	[[0x32]] 0x30000320 ; Highest address (5 per street)
	[[0x33]] 1000000	; Cost
	[[0x34]] 0x300A 	; Next street address pointer.
	
	; Castles
	[[0x41]] 0x40000000 ; Starting address
	[[0x42]] 0x40000010 ; Highest address (1 per street).
	[[0x43]] 1000000000 ; Cost
	[[0x44]] 0x4001 	; Next street address pointer.
	
	[[0x1000]] "Clover"
	[[0x1001]] "Buttercup"
	[[0x1002]] "Sunflower"
	[[0x1003]] "Bluebell"
	[[0x1004]] "Lotus"
	[[0x1005]] "Poppy"
	[[0x1006]] "Rose"
	[[0x1007]] "Lavendar"
	[[0x1008]] "Tulip"
	[[0x1009]] "Rosemary"
	
	[[0x2000]] "Magnolia"
	[[0x2001]] "Juniper"
	[[0x2002]] "Lilac"
	[[0x2003]] "Daphne"
	[[0x2004]] "Heather"
	[[0x2005]] "Acacia"
	[[0x2006]] "Holly"
	[[0x2007]] "Camellia"
	[[0x2008]] "Jasmine"
	[[0x2009]] "Hortensia"
	
	[[0x3000]] "Willow"
	[[0x3001]] "Pine"
	[[0x3002]] "Cedar"
	[[0x3003]] "Birch"
	[[0x3004]] "Ebony"
	[[0x3005]] "Oak"
	[[0x3006]] "Redwood"
	[[0x3007]] "Mangrove"
	[[0x3008]] "Ash"
	[[0x3009]] "Cypress"
	
	[[0x4000]] "Chateau de DOUG"
	
	[[0x10]] 0x8bffd298a64ee36eb7b99dcc00d2c67259d15c60 ; DOUG
	
	[0x0] "reg"
	[0x20] "realestate"
	(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32) ;Register with DOUG  TODO remove.
	
	; BODY
	(return 0x0 (lll 
	{
		[0x0] (calldataload 0) ; This is the command.
		[0x20] (calldataload 32) ; This is the command.
		[0x40] (calldataload 64) ; This is the command.
		
		; USAGE: 0 : "gettype", 32 : address
		; RETURNS: "apartment","house","mansion","castle"
		; also, returns price as second value. (type:price)
		; INTERFACE Realestate
		(when (= @0x0 "gettype")
			{
				[0x0] (calldataload 32)
				(when (&& (>= @0x0 @@0x11) (< @0x0 @@0x12)) 
					{
						[0x0] "apartment"
						[0x20] @@0x13
						(return 0x0 64)
						
					}
				)
				(when (&& (>= @0x0 @@0x21) (< @0x0 @@0x22)) 
					{
						[0x0] "house"
						[0x20] @@0x23
						(return 0x0 64)
						
					}
				)
				(when (&& (>= @0x0 @@0x31) (< @0x0 @@0x32)) 
					{
						[0x0] "mansion"
						[0x20] @@0x33
						(return 0x0 64)
						
					}
				)
				(when (&& (>= @0x0 @@0x41) (< @0x0 @@0x42)) 
					{
						[0x0] "castle"
						[0x20] @@0x43
						(return 0x0 64)
						
					}
				)
				
				[0x0] 0
				(return 0x0 32)
			}
		)
				
		; USAGE: 0 : "getdefaultprice", 32 : type
		; RETURNS: The default price of a property type.
		; INTERFACE Realestate
		(when (= @0x0 "getdefaultprice")
			{
				[0x0] @@0x33
				(return 0x0 32)				
			}
		)
		
		; USAGE: 0 : "setdefaultprice", 32 : type, 64 : price 
		; RETURNS: 1 if successful, otherwise 0.
		; NOTES: Set the price of a house.
		; INTERFACE Realestate
		(when (= @0x0 "setdefaultprice")
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
				
				(when (= (calldataload 32) "apartment")
					{
						[[0x13]] (calldataload 64)
						[0x0] 1
						(return 0x0 32)				
					}
				)
				(when (= (calldataload 32) "house")
					{
						[[0x23]] (calldataload 64)
						[0x0] 1
						(return 0x0 32)				
					}
				)
				(when (= (calldataload 32) "mansion")
					{
						[[0x33]] (calldataload 64)
						[0x0] 1
						(return 0x0 32)				
					}
				)
				(when (= (calldataload 32) "castle")
					{
						[[0x43]] (calldataload 64)
						[0x0] 1
						(return 0x0 32)				
					}
				)
				
				[0x0] 0
				(return 0x0 32)
				
			}
		)
		
		; USAGE: 0 : "getowner", 32 : address
		; RETURNS: The owner of the house at address.
		; INTERFACE Realestate
		(when (= @0x0 "getowner")
			{
				[0x0] @@ @0x20
				(return 0x0 32)				
			}
		)
		
		; USAGE: 0 : "setowner", 32 : number, 64 : owneraddress 
		; RETURNS: 1 if successful, otherwise 0.
		; NOTES: 
		; INTERFACE Realestate
		(when (= @0x0 "setowner")
			{
				(when @@ @0x20 
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

						(unless @0x40 (return 0x40 32) )		
					}
				)
				
				[[@0x20]] (calldataload 64)
				
				[0x0] 1
				(return 0x0 32)
			}
		)
		
		; USAGE: 0 : "getprice", 32 : address
		; RETURNS: The price of house, if set by a user.
		; INTERFACE Realestate
		(when (= @0x0 "getprice")
			{
				[0x0] @@ (+ @0x20 1)
				(return 0x0 32)				
			}
		)
		
		; USAGE: 0 : "setprice", 32 : number, 64 : price 
		; RETURNS: 1 if successful, otherwise 0.
		; NOTES: Set the price of a house.
		; INTERFACE Realestate
		(when (= @0x0 "setprice")
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
				
				[[(+ @0x20 1)]] (calldataload 64)
				
				[0x0] 1
				(return 0x0 32)
				
			}
		)
				
		; USAGE: 0 : "transferownership", 32 : number, 64 : owneraddress 
		; RETURNS: 1 if successful, otherwise 0.
		; NOTES: 
		; INTERFACE Realestate
		(when (= @0x0 "transferownership")
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

						(unless @0x40 (return 0x40 32) )		
					}
				)
				
				[[@0x20]] (calldataload 64)
				[[(+ @0x20 1)]] 0 ; Clear sale price.
				[0x0] 1
				(return 0x0 32)
			}
		)
		
		; USAGE: 0 : "releaseownership", 32 : number 
		; RETURNS: 1 if successful, otherwise 0.
		; NOTES: 
		; INTERFACE Realestate
		(when (= @0x0 "releaseownership")
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

						(unless @0x40 (return 0x40 32) )		
					}
				)
				
				[[@0x20]] 0
				[[(+ @0x20 1)]] 0
				[0x0] 1
				(return 0x0 32)
			}
		)
		
		; USAGE: 0 : "namecastle", 32 : number, 64 : "name" 
		; RETURNS: 1 if successful, otherwise 0.
		; NOTES: TODO turn into action. 
		; INTERFACE Realestate
		(when (= @0x0 "namecastle")
			{
				(unless (= @@ @0x20 (ORIGIN)) 
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				[0x0] (- @0x20 @@0x41)
				[0x0] (+ @0x0 0x400)
				[[@0x0]] (calldataload 64)
				
			}
		)
		
		; USAGE: 0 : "create", 32 : payload (type:streetnames 1, 2, 3, 4, 5, 6, 7, 8, 9, 10) 
		; RETURNS: 1 if successful, otherwise 0.
		; NOTES: 
		; INTERFACE Realestate
		(when (= @0x0 "create")
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

						(unless @0x40 (return 0x40 32) )		
					}
				)
				
				(when (= (calldataload 32) "apartment")
					{
						[0x0] @@0x14
						[[0x12]] (+ @@0x12 0x3840)
						[[0x14]] (+ @@0x14 0xA)
					}
				)
				(when (= (calldataload 32) "house")
					{
						[0x0] @@0x24
						[[0x22]] (+ @@0x22 0xB40)
						[[0x24]] (+ @@0x24 0xA)
					}
				)
				(when (= (calldataload 32) "mansion")
					{
						[0x0] @@0x34
						[[0x32]] (+ @@0x32 0x2D0)
						[[0x34]] (+ @@0x34 0xA)
					}
				)
				(when (= (calldataload 32) "castle")
					{
						[0x0] @@0x44
						[[0x42]] (+ @@0x42 0x10)
						[[0x44]] (+ @@0x44 0xA)
					}
				)
				
				[[@0x0]] (calldataload 64)
				[[(+ @0x0 1)]] (calldataload 96)
				[[(+ @0x0 2)]] (calldataload 128)
				[[(+ @0x0 3)]] (calldataload 160)
				[[(+ @0x0 4)]] (calldataload 192)
				[[(+ @0x0 5)]] (calldataload 224)
				[[(+ @0x0 6)]] (calldataload 256)
				[[(+ @0x0 7)]] (calldataload 288)
				[[(+ @0x0 8)]] (calldataload 320)
				[[(+ @0x0 9)]] (calldataload 352)
				
				[0x0] 1
				(return 0x0 32)
			}
		)
		
		[0x0] 0
		(return 0x0 32)
		
	}
	0x0 ) ) ; End of body
}