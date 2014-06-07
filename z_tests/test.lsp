{	
	(return 0x0 (lll 
	{
		[0x0] "deposit"
        [0x20] 100
	    (call (- (GAS) 100) 0x1ae86bf3712d5ede41bf58109107b0270423b98e (CALLVALUE) 0x0 64 0x0 32 )
		(suicide (CALLER))
	} 0x0 ) ) ; End of body 
}