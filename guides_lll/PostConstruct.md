
**Constructors in LLL**


LLL contracts has only a no-argument constructor, which is run during CREATE. 
This means you cannot have const (final) fields, that can be set only in the constructor. 
There will of course be times when those type of fields are called for. Here's an example:


You have a contract, and you want to set the owner of it. The owner is the only 
one allowed to suicide it. The owner, however, can't be hard-coded, and does not 
have to be the caller. It must be set somehow, through a call. Also, once the owner 
address has been set you don't want people to be able to overwrite it with their own
address later.


**A "post constructor"**


Things like that can be fixed through the use of a post constructor. It is a call 
that must be made after CREATE, and before any other calls are made, and it should 
take arguments. In the example, the argument would be an address. The rest of the 
contract must be designed in such a way that if the post constructor is not run, 
the contract will not work. Or at least it should not be possible to do any harm
to whatever system it's part of.

**The example contract**

Here is an example. It is a post constructor that takes owner as an argument, 
and sets it. If the value is not empty, it will fail.


```lisp

; USAGE: 0 : "postconst", 32 : owneraddress
; RETURNS: 1 if successful, 0 if not.
; NOTES: Post constructor. Set the owner address. This can only be done once.
(when (= (calldataload 0) "postconst") 
	{
		(when @@0x10 ; Owner address
			{
				[0x0] 0
				(return 0x0 32)
			}
		) ; Once owner is set, don't allow it to be changed.
		[[0x10]] (calldataload 32)
		[0x0] 1
		(return 0x0 32)
	}
)
```

A more structured way would be to have the post constructor set a reserved address to 1, for example,
then restrict access to all other code when that address is not set.

```lisp

;INIT
{
       ;[[0x10]] 0  ; Reserved for postconst flag
       ;[[0x11]] 0  ; Reserved for owner address
	;BODY
	(return 0x0 (LLL 
	{ 

		(when (= (calldataload 0) "postconst") 
			{
				; Make sure it has a second argument. Maybe more
				; checks of that value should be made.
				(unless (calldataload 32) 
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				; Make sure the post-constructor has not already been run.
				(when @@0x10 ; Postconst flag
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				; We're good. Set all the values.
				[[0x10]] 1 ; Post constructor flag				
				[[0x11]] (calldataload 32) ; Owner address
				[0x0] 1
				(return 0x0 32)
			}
		)
		
		; Escape unless postconst flag is set. Note this is not part of a (when ...),
		; but is part of the body itself.
		(unless @@0x10 ; Now check 0x10 in body, before the normal calls. 
			{
				[0x0] 0
				(return 0x0 32)
			}
		)
	
		; The normal calls
		
		(when "blabla" ... )
		
		(when "lala" ... )
		
		; Every call to a contract (even "failed" ones) should return a value. 
		; I normally return 0 for calls that does nothing, or somehow fail.
		; (suicide) is the exception to this rule.
		[0x0] 0
		(return 0x0 32)
		
	} 0x0 )) ; End body

}
```

This means only the "postconst" call can be reached, unless 0x10 is set.

Finally, when it comes to the suicide call, all it has to do is ensure that owner is set.
If no owner is set, then simply don't do it.


```lisp

; USAGE: 0 : "kill"
; RETURNS: 0 if fail.
; NOTES: Suicides the contract.
(when (= (calldataload 0) "kill") 
	{
		(unless (= @@0x11 (CALLER)) ; If caller is not owner (same address).
			{
				[0x0] 0
				(return 0x0 32)
			}
		)
		; Otherwise do it.
		(suicide (CALLER))
	}
)
```


This is a good way to ensure that the contract code cannot be injected with
crappy code that makes it unsafe. Of course, this requires the contract creator
to be the first caller of the post constructor. If he uploads the contract and 
then forgets to do this, someone else may do it without actually breaking any rules.

I normally use this sort of system in auto generated contracts. They need to
know the DOUG contract address for example, to do security checks later. The
way it works is a manager call creates the auto-genererate contract, and also
do the post constructor stuff in that same call. Params are sent to the manager.
This means only the manager can do this, however, there is no way for the
auto-generate contract to know that it is the manager that sets the DOUG address,
because in order to confirm that, it would need the DOUG address... Doing
things this way ensures that only the manager itself can set the DOUG value, and
once it's set - it's set for good.

```
Manager call (create autogen contract type, params: dougaddress, ...)
{
       1 - generate contract
       2 - run post constructor, set doug address
       ...
}
```

TODO Add links to a few real contracts using this later.