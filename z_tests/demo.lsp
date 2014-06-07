{
  ;; Give caller a whole bunch of cash.
  [[ (caller) ]] 0x1000000000000000000000000
  
  ;; Register with the NameReg contract.
  [0x0] "GavCoin"
  
  (call 
  		(- (gas) 100) 
  		0x2d0aceee7e5ab874e22ccf8d1a649f59106d74e8 
  		0 
  		0x0 7 
  		0x0 0
  )
  
  

  (return 0 (lll {
  	
  	
    (when (!= (calldatasize) 64) (stop))      ; stop if there's not enough data passed.
    
    [fromBal] @@(caller)
    
    [toBal] @@(calldataload 0)
    
    [value] (calldataload 32)
    
    (when (< @fromBal @value) (stop))         ; stop if there's not enough for the transfer.
    
    [[ (caller) ]] (- @fromBal @value)       ; subtract amount from caller's account.
    
    [[ (calldataload 0) ]] (+ @toBal @value) ; add amount on to recipient's account.
    
  } 0))
}