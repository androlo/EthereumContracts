;INIT
{
	;[[0x10]] DOUG
	;[[0x11]] owner address
	;[[0x12]] item name
	
	;[[0x20]] infoURL_0
	;[[0x21]] infoURL_1
	;[[0x22]] infoURL_2
	;[[0x23]] infoURL_3
	
	;body section
	[0x0](LLL
		{
			
			; USAGE: 0: "postconst", 32: dougaddress, 64: owner address, 96: Item name 
			; RETURNS: -
			; NOTES: Post constructor.
			; INTERFACE Factory<?>
			(when (= (calldataload 0) "postconst")
				{
					(when @@0x10 
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					
					[[0x10]] (calldataload 32)
					[[0x11]] (calldataload 64)
					[[0x12]] (calldataload 96)
					
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
			
			; USAGE: 0 : "setdescURL", 32-128: descURL
			; RETURNS: 1 if successful, 0 if not.
			; NOTES: Set url to the file containing the description of this item.
			; INTERFACE GoodContract
			(when (= (calldataload 0) "setdescURL")
				{
					(unless (= (CALLER) @@0x11)
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					
					[[0x20]] (calldataload 32)
					[[0x21]] (calldataload 64)
					[[0x22]] (calldataload 96)
					[[0x23]] (calldataload 128)

					[0x0] 1
					(return 0x0 32)
				}
			)
						
			; USAGE: 0 : "kill"
			; NOTES: Suicides. Done automatically when an item type is removed.
			; RETURNS: -
			(when (= @0x0 "kill")
				{
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
					
					(suicide (ORIGIN))
				}
			)
			
			[0x0] 0
			(return 0x0 32)
			
		} 0x20 )
	(return 0x20 @0x0) ;Return body
}