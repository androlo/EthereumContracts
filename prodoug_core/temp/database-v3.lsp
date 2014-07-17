; Database

; This contract is used to register entries into a database. Entries are stored in a linked list, and
; are given addresses in two different ways. If no entries has been deleted previously, it will just
; keep increasing an address counter (by the size of an entry), and give the new entry space.
; If an entry has been previously deleted, its address is added to a pool. The pool makes it possible 
; to re-use the memory released when deleting entries.
;
; Based on the database-v2.lsp by DennisMcKinnon
; (https://github.com/dennismckinnon/Ethereum-Contracts/blob/master/DOUG/Database-v2.lsp)
;

; Data format
;
; 0 - 31		Meta: address to tail (address, 1 seg)
; 32 - 63		Meta: address to head (address, 1 seg)
; 64 - 95: 	User nick (string, 1 seg)
; 96 - 127: 	Date of creation (string, 1 seg)
; 128 - 159:	Last update date (string, 1 seg)
; 160 - 223:	Title (string, 2 seg)
; 224 - 255   Size of data field.
; 256 - 1279: Text (string, 32 segs (1024 bytes)).
;
; Total size: 40 segments (max 1,279 kb)

;INIT
{
	;For DOUG integration
	[[0x10]] 0x0c542ddea93dae0c2fcb2cf175f03ad80d6be9a0 ;Doug Address

	;Pooled address section
	[[0x11]] 0x0   	;Size of pool list
	[[0x12]] 0x19	;Pointer to last added address (0x20 is the real start, 0x19 is "faux", and is never referenced)

	[[0x13]] 0x10020	;Current next address. If pool is empty, add new entries to this address.
						;this allows for 2^16 memory pool addresses (starting at 0x20).
	[[0x14]] 2			;Data contents offset from address (data and data + 1 contains meta stuff)
	;Data section
	[[0x15]] 1000		;Size of a data element (in storage addresses).
	[[0x16]] 0x0		;Number of data entries
	[[0x17]] 0x0		;Current tail
	[[0x18]] 0x0		;Current head
	
	[0x0] "reg"
	[0x20] "database"
	(call (- (GAS) 100) @@0x10 0 0x0 0x40 0x0 0x20) ;Register with DOUG TODO remove after beta
	
	(return 0x0 (lll 
	{
		; Call doug to get the address to the user level.
		[0x40] "get"
		[0x60] "users"
		; Store the address of "users" at 0x80
		(call (- (GAS) 100) @@0x10 0 0x40 64 0x80 32)
	
		
		[0x0] (calldataload 0)	;This is the command
		
		[0x20] (calldataload 32)
	
		; USAGE: 0 : "kill"
		; RETURNS: -
		; NOTES: Only doug can do this.
		; INTERFACE: Doug
		(when (&& (= @0x0 "kill") (= (CALLER) @@0x10) ) (suicide (CALLER)) ) ;Kill option
		
		; USAGE: 0 : "insert", 32 : payload
		; RETURNS: 1 if successful, 0 if fail.
		; INTERFACE: Database
		(when (&& (= @0x0 "insert") (> @0x20 0x40) ) ;When inserting an entry.
			{
				;Call the nick contract to get the user nick.
				[0x40] "getnick"
				[0x60] (caller)
				(call (- (GAS) 100) @0x80 0 0x40 64 0xA0 32)
				
				(unless @0xA0 (return 0xA0 32) ) ;If caller does not have registered nick, they can't add data.
				
				
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
				[[(+ @0x60 2)]] @0xA0
				;Created
				[[(+ @0x60 3)]] (TIMESTAMP)
				;Updated
				[[(+ @0x60 4)]] (TIMESTAMP)
				;Title
				(if (calldataload 32)
					{
						[[(+ @0x60 5)]] (calldataload 32)
						[[(+ @0x60 6)]] (calldataload 64)
					}
					{
						[[(+ @0x60 5)]] "No Title"
					}
				)
				
				;Now the big chunk of data. at (96) we find the size of the description. 
				[0x0] (calldataload 96)
				(when (> @0x0 32) 
					[0x0] 32
				) ; Don't allow larger entries then 900 memory addresses (28,8 kb).
				
				[0xA0] 96
				[0x60] (+ @0x60 7)
				[[@0x60]] @0x0 ; Add size to size slot.
				
				(for [0x80]0 (< @0x80 @0x0) [0x80](+ @0x80 1)
					{
						[0x60] (+ @0x60 1)
						[0xA0] (+ @0xA0 32)
						[[@0x60]] (calldataload @0xA0) ; grab from calldataload
					}
				)
				
				[0x0] 1
				(return 0x0 32)
				
			} ;end body of when
		); end when
	
		; USAGE: 0 : "modify", 32 : address, 64:  payload
		; RETURNS: 1 if successful, 0 if fail.
		; INTERFACE: Database
		(when (&& (= @0x0 "modify") (>= @0x20 0x10020) )
			{
				;Call the nick contract to get the user nick.	
				[0x40] "getnick"
				[0x60] (CALLER)
				(call (- (GAS) 100) @0x80 0 0x40 64 0x40 32)
				
				; No nick = no modification
				(unless @0x40 (return @0x40 32))
				
				;If caller nick is not the same as uploader - cancel. This is also a nullcheck for the database entry.
				(unless (= @@(+ @0x20 2) @0x40) 
					{
						[0x0] 0
						(return 0x0 32)
					}	
				)
				
				[0x60] @0x20
							
				;Updated
				[[(+ @0x60 4)]] (TIMESTAMP)
				;Title
				(if (calldataload 64)
					{
						[[(+ @0x60 5)]] (calldataload 64)
						[[(+ @0x60 6)]] (calldataload 96)
					}
					{
						[[(+ @0x60 5)]] "No Title"
					}
				)
				;Now the big chunk of data. We find the size of the description. 
				
				[0x0] (calldataload 128)
				(when (> @0x0 32) 
					[0x0] 32
				) ; Don't allow larger entries then 900 memory addresses (28,8 kb).
				
				[0xA0] 128
				[0x60] (+ @0x60 7)
				[0xC0] @@ @0x60 ; Current size of database text (in storage addresses).
				[[@0x60]] @0x0
				
				(for [0x80]0 (< @0x80 @0x0) [0x80](+ @0x80 1)
					{
						[0x60] (+ @0x60 1)
						[0xA0] (+ @0xA0 32)
						[[@0x60]] (calldataload @0xA0) ; grab from calldataload
					}
				)
				; If the old database text took up more storage addresses, clear those.
				(when (> @0xC0 @0x0)
					{
						[0x0] (- @0xC0 @0x0) ; Difference in size
						(for [0x80]0 (< @0x80 @0x0) [0x80](+ @0x80 1)
							{
								[0x60] (+ @0x60 1)
								[[@0x60]] 0
							}
						)		
					}
				)
	
			} ;end body of when
		); end when
	
		; USAGE: 0 : "delete", 32 : address
		; RETURNS: 1 if successful, 0 if fail.
		; INTERFACE: Database
		(when (&& (= @0x0 "delete") (>= @0x20 0x10020) )  ; When deleting a post.
			{
				;Call the userdata contract to get the user nick.
				[0x100] "getnick"
				[0x120] (caller)
				(call (- (GAS) 100) @0x80 0 0x100 64 0x40 32)
				
				; If caller didn't post this - cancel. Also functions as a null-check.
				; TODO make database admin group that are allowed to delete documents.
				(unless (= @0x40 @@(+ @0x20 2))
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
	
				; clear the data
				[0x40] @@(+ @0x20 7) ;Size of text
				
				[0x80] (+ @0x40 8) ; 0x80 is now where the text ends.
				
				;loop from (address + 2) to (address + @0x80), to clear all data except head and tail slots.
				(for [0x60]2 (< @0x60 @0x80) [0x60](+ @0x60 1)
					{		
						[[(+ @0x20 @0x60)]] 0
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
				
				[[@0x20]] 0			;The address (containing 'previous')
				[[(+ @0x20 1)]] 0	;The address for its 'next'
				
				[0x0] 1
				(return 0x0 0x20)
	
			} ; end when body
		) ;end when
		
		[0x0] 0
		(return 0x0 32)
	} 
	0x0 ))
	
}