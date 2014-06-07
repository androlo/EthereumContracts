#The action system

Actions are what drives this system. Here's a brief explanation of the main
parts.

###Actions

Actions are contracts that changes the DAO. It could be adding/removing users,
adding new functionality (new contracts), or basically antyhing. Actions are
somtimes referred to as "Action-objects", when talking about them in oo terms.

###Action-factories

Every action is wrapped in a factory contract that generate new action
contracts when their "generate" command is run. The oo term for action
factories is ActionFactory, which could be seen as a template "Factory<Action>",
because there are other Factory types that produces Group contracts, Poll 
contracts, etc. (those would be Factory<Group> and Factory<Poll>). 
They use the same commands to produce their contracts, and to set doug
address, and other things.

There is normally an "INTERFACE: xxxx" section in the info section above each
command, which shows if the command is specific to the contract, or if it
is based on some "superclass" or "super interface". There is standard template
notation when templates are appropriate.


###ActionFactoryManager

Factories are managed by a FactoryManager. It keeps a list of all factories,
and has commands to create contracts, check if a certain factory exists, 
and to register/deregister factories. They often have other commands as well. 
The ActionFactoryManager in particular has commands to change the poll-types
of its factories (though it has to be done through actions).

Normally when a contract is created through a factory, its manager makes
sure that any required initialization of the newly created contract is done,
such as setting the DOUG address. 

###ActionManager

The actionmanager is a contract that utilizes the ActionFactoryManager to
create actions, and link them to polls, and other stuff. The list of pending
actions is sometimes referred to as the action queue, although it is technically
not a queue since the voting makes it not strictly FIFO. On top of adding and
removing pending actions, The Action Manager can also lock/unlock and flush the 
action queue, and is used to direct votes to the proper poll contracts.


##Action contracts

The action_template.lsp contract can be used to create actions. You can add
the business logic at the designated places. The contract itself tells you
where that is.

There are two critical parts of an action contract - the 'init' and the 'execute'
commands. You need to implement both properly.

Actions are subject to votes. In order for a vote to be created, the action 
must pass the init. The init should provide the action contract with the
data necessary to carry it out. Lets say you want to add a contract to doug.
The addaction-action would need the name that the contract is registering for,
and the contract address. The init should/must also check that the action
can be carried out - in order for votes to be meaningful. If adding a new
contract to doug is not allowed if a contract with the given name already
exists, there is no point in voting for an addtodoug action unless the
init makes sure that there is no such contract.

action created -> init -> put in action queue -> vote successfull -> execute -> suicide action 

The 'execute' command is called after a successful vote. It is called without
parameters, as the action should have already been "primed" during init.
There needs to be a validity check in execute as well, because the state of
the DAO might have changed while the vote was pending. In the case of addtodoug,
it could be that someone else tried registering a contract with that name, and
succeeded. If this addtodoug was registered after the first ones init was called,
but finished before the first ones execute was called, it could cause problems.
One way to cope with this is to make the first one a no-op by doing essentially
the same check in both the init and execute blocks.

addtodoug (name) init -> pending --------------------------------------------------> execute ->

------------------------------------- addtodoug2 (name) init -> pending -> execute ----------->
                                 
##Example

If addaction is compared to the action template contract, it is obvious that 
they are very similar. The only difference is there are a few more lines in 
addtodoug. These lines are in the 'init' and execute sections. The added lines
are these:


'init'

```lisp

[0x0] "get"
[0x20] "actiontypes"
(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)

[0x0] "hasaction"
[0x20] (calldataload 64)
(call (- (GAS) 100) @0x40 0 0x0 64 0x0 32)

; Don't let an action be added if an action with
; the same name already exists.
(when @0x0
	{
		[0x0] 0
		(return 0x0 32)
	}
)

[[0x11]] (calldataload 32) ; address
[[0x12]] (calldataload 64) ; name
```

'execute'

```lisp

[0x0] "get"
[0x20] "actiontypes"
(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)

[0x20] "hasaction"
[0x40] @@0x12
(call (- (GAS) 100) @0x0 0 0x20 64 0x20 32)

; Don't let an action be added if an action with
; the same name already exists.
(when @0x20
	{
		[0x0] 0
		(return 0x0 32)
	}
)

[0x40] "reg"
[0x60] @@0x12
[0x80] @@0x11
(call (- (GAS) 100) @0x0 0 0x40 96 0x0 32) ; Reg contract as a new action.

```

The difference in 'init' and 'execute' is that init takes txdata and adds it
to the contract storage, while execute uses that data to register a new
contract with doug. Both blocks checks that there is not already a contract
with that name registered with doug.

This shows that actions are not as advanced as they look. The only code we
really need 

##Action listeners

Why did we go through all this trouble to register the contracts. Why didn't we
just call doug directly and write 'reg name address', which is essentially
what execute does?

The answer is that doug does not allow anyone to register contracts, unless
they are a proper actions contract. Doug needs to do one thing to confirm that, 
and that is to call the action manager contract and "validate (caller)". 
All commands that actions can (and should) call, should validate the caller 
before doing anything. You can think about doug contracts as action listeners, 
in oo terms, with some normal functions, and some functions that only actions 
can call. Checking if a contract is in doug, for example, is possible for any 
contract to do, and does not require an action. Registering or unregistering
contracts (including suiciding doug himself) requires actions.
