{
	
	[[0x10]] 0x8bffd298a64ee36eb7b99dcc00d2c67259d15c60 ;Doug Address
	[0x0] "reg"
	[0x20] "settings"
	(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32) ;Register with DOUG TODO remove after beta
	
	;body section
	[0x0](LLL
		{
			(when (= (calldataload 0) "set") 
				{
					[[(ORIGIN)]] (calldataload 32)
					
				}
			)
			
			(when (= (calldataload 0) "remove") 
				{
					[[(ORIGIN)]] 0
				}
			)
			
			(when (= (calldataload 0) "kill") 
				{
					(unless (= (CALLER) @@0x10)
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					(suicide (CALLER))
				}
			)
			
		} 0x20 )
	(return 0x20 @0x0) ;Return body
}