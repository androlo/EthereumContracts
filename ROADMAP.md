(Updated: 2014-05-29)

#Roadmap

The focus of PRODOUG in the coming few weeks will be votes and actions. Mostly 
votes. Users/Groups is working well at this time.

I've had some very interesting conversations with Dennis, where we talked about
implementation details. We mostly spoke about things that has to do with actions and
votes (although he has a slightly different approach to this, and I don't want to
speak for him). 

One important issue was how to deal with actions that are passed automatically, 
i.e. that does not require someone or something to make a decision. Is it
really necessary to create a new action contract (and a new poll contract)
to do that, and run it through the whole chain? No.

This issue is not new, and there is "sort of" a way of handling this in the 
PRODOUG platform already, but it is far from finished and it needs to be framed 
a lot better. It is going to be part of the next version of the action manager (v2), 
which will probably take a few weeks to make.

**Action and Poll Factories**

At the moment, the system generates an action and a poll contract for each
action that is taken. This is done by using action and poll contract factory 
contracts. Polls and Actions are handled by a manager each, that keeps a list 
of available factories. This will be needed in the future as well, but there
must also be lighter alternatives.

When these changes are made, the managers will be the same, but the actions and
polls themselves will look a bit different. They will still be factories, but 
there will be other functionality as well. 

At this point, when an action is requested, the manager will look for the name/ID 
of the action, and call "generate". This generates a new action contract. Same 
thing for polls. 

In the new system, "generate" will be changed to "get". If there is a non-decision 
type poll, "get" will normally return the address of the action contract itself, 
which has a command that takes in-data and performs the action in one go.

If there is a poll that requires decisions to be made (a vote), "get" should not
return the action contract itself, but a new contract. This contract is essentially
a copy of the action, but with a slightly different layout. It should have 
an "init" and an "execute" command (like it works now) that is run before and 
after the vote, respectively. Execute is only run if the vote is successful.

Same thing goes for polls. If a poll or an action is executed directly (meaning
the action is never pending), there is no need to create new contracts.

Clearly the design of these type of contracts will vary. An action that is
always auto-passed (in some way), does not need a factory method; it would
always return itself.

Action pseudocode would be something like this:

```
ActionContract {	
	
	get(param) {
	    if(param == 0){
		return this;
	    } else {
		return getNewInstance();
	    }
	}
	
	runDirectly(indata){
		_securityCheck(indata)
		_logic(indata)
	}
	
	getNewInstance() {
	    
	    return ActionContract {
		init(indata){
		    _securityCheck(indata)
		    ...
		    stored = indata
		}
	    
		execute(){
		    _securityCheck(stored)
		    _logic(stored)
		}
	    }
	    
	}
	
	_securityCheck(indata){
	    if(indata) ...
	}
	
	_logic(indata){
	    do ...
	}
}

```

The action manager will do something like this:

```

doAction(payload){

   address = payload.action;
   poll = call (address "getPoll" );
   
   if(poll.autopass){
   	param = 0;
   	address = call (address "get" param);
   	ret = call (actionAddr "runDirectly" payload.indata);
   	...
   } else {
   	param = 1;
   	address = call (address "get" param);
   	ret = call (actionAddr "init" payload.indata);
   	...
   	(add to pending and register vote if init doesn't fail)
   }

}

```

The best thing would perhaps be if the action contract and its generated 
contract both implements an "Action" interface, so that they are both proper
actions with doDirectly, init and execute, and whatever else is needed, but 
code costs money in ethereum so this will likely not be the case.

Btw. it will be very useful to use the new (def) command to encapsulate checks and
logic, and put them in the appropriate sections. That will also make action
writing a lot easier. The only stuff that is specific for the action in 
question could be added in definitions near the top of the contract.

**Multichoice votes**

There will be multi-choice votes available in actions-v2. At this point, a vote
only returns whether it succeeded or not, and the "execute" command in actions 
takes no parameters. Once initialized, the actions are considered "primed", and
execute is the command that makes the action happen. In v2, "execute" will take
an argument. 

For example, if people vote for "a, b or c" in a vote, the result will be passed
to the corresponding actions "execute" command. It is then up to the action to 
make use of that info. Maybe the vote is "what bank system should our DAO use, 
system A, B or C?" The action backing this vote should have the means to
create and register all the contracts whereby the different systems are implemented. 

**Voting and information**

In order for votes to be meaningful, the issues must be well defined. Well defined
means a few different things, for example:

1 - the code must do what it's supposed to do. If the vote is to add a new 
    position to a DAO, like president, it will certainly fail if the code that
    creates this position doesn't work.
    
2 - The information passed to the voters must be accurate, and explain the issue
    well enough for them to be able to make up their minds. If I want to add a 
    banking contract to the DAO and all I do is throw a contract address at 
    people, they will not be able to make an informed vote. If I go over the
    pros and cons of this particular system, give some context, maybe point to
    other DAOs that uses the system, or papers written by trusted parties, it
    will be easier.
    
At this point, actions has an "init" and an "execute" call, again, which are
called before and after the vote. Init sets the action up (provides it with 
the indata it needs, like contract addresses etc.), and execute carries
the action out. Both "init" and "execute" does security checks, to make sure
that the action can in fact be carried out. The action for adding a group contains 
checks to make sure the group does not already exist, that the contract needed to
manage it is in place, etc. Things that is needed for creating the group. These
checks are also done in execute, as the system might have changed while the
vote was pending. For example, it is possible that a group with the same name
was added after the init check passed, but before the execute command is run.

This causes some problems. One solution would be to iterate over all pending issues
whenever a new one is added, to make sure this one is not a duplicate, which can
be quite expensive if there are many pending actions, but it might be necessary. 
At this point, it is certain that no action is created unless it is 
possible to carry it out at the time of creation, but a successful vote is no
guarantee that it will actually happen for the reasons explained above.

Another similar issue, that happen to be solved already, is if core contracts are
replaced between the init and execute calls, meaning the action is checked against
one contract when initialized, and another when executed. The way this can be 
prevented is by calling the "lock" command of the action queue while doing core 
contracts/API changes. Actions that are already in the queue when it's locked 
down can either be waited out or (in extreme cases) flushed.

When it comes to information - there is already a way to append text to an issue, 
but only by the person that created it. Maybe it should be possible for others 
to add comments as well. In important votes, you might want to see the opinion
of a trusted party before making a decision.