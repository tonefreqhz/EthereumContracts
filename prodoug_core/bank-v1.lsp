{	
	[[0x10]] 0x07a03c311f07ad616e551daaee83e330c702559b; DOUG address 
	[[0x11]] 4; Size of a log entry.
	[[0x12]] 0x20 ; This is the next empty log address.
	[[0x13]] 10ether ; Maximum amount of money in one transaction.
   ;[[0x20]] this is where the log starts.
	
	[0x0] "reg"
	[0x20] "bank"
	(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32) ;Register with DOUG  TODO remove.
	
	; BODY
	(return 0x0 (lll 
	{
		
		[0x0] (calldataload 0) ; This is the command.
		
		; USAGE: 0 : "balance"
		; RETURNS: The balance of the bank.
		; INTERFACE Bank
		(when (= @0x0 "balance")
			{
				[0x0] (BALANCE (ADDRESS))
				(return 0x0 32)
			}
		)
		
		; USAGE: 0 : "setmaxendowment", 32 : value
		; RETURNS: 1 if success (larger then 100 finney, less then 100 ether), 0 otherwise.
		; NOTES: A single endowment may not be larger then this value.
		; INTERFACE Bank
		(when (= @0x0 "setmaxendowment")
			{
				;Cannot be lower then 100 finney
				(when (< (calldataload 32) 100finney)
					{
						[0x0] 0
						(return 0x0 32)
					}	
				)
				
				; Hardcoded 100 ether max during testing.
				(when (> (calldataload 32) 100ether)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				[[0x13]] (calldataload 32)
				[0x0] 1
				(return 0x0 32)
			}
		)
		
		; USAGE: 0 : "maxendowment"
		; RETURNS: The maximum endowment allowed in one single transaction.
		; INTERFACE Bank
		(when (= @0x0 "maxendowment")
			{
				[0x0] @@0x13
				(return 0x0 32)
			}
		)
		
		; USAGE: 0 : "deposit"
		; RETURNS: 1 if success (deposit larger then 100 finney), 0 otherwise.
		; NOTES: A deposit smaller then 100 finney will not be registered.
		; INTERFACE Bank
		(when (= @0x0 "deposit")
			{
				(when (< (CALLVALUE) 100finney)
					{
						[0x0] 0
						(return 0x0 32)
					}	
				)
						
				; Log the transaction.
				[0x0] @@0x12
				[[@0x0]]		"Deposit"
				[[(+ @0x0 1)]] 	(TIMESTAMP)
				[[(+ @0x0 2)]] 	(ORIGIN)
				[[(+ @0x0 3)]] 	(CALLVALUE)
				[[0x12]] (+ @@0x12 @@0x11)
				
				[0x0] 1
				(return 0x0 32)
			}
		)
		
		; USAGE: 0 : "endow", 32 : recipient (address), 64 : amount
		; RETURNS: 1 if success, 0 otherwise.
		; NOTES: Nobody is allowed to get more then 10 ether per transaction atm.
		; INTERFACE Bank
		(when (= @0x0 "endow")
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
				
				; No more then 10 ether.
				(when (> (calldataload 64) @@0x13)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				; If the bank does not have enough money to make the payment - cancel.
				(when (< (BALANCE (ADDRESS)) (calldataload 64))
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				; Send the money
				(call (- (GAS) 100) (calldataload 32) (calldataload 64) 0x0 0 0x0 0)
				
				; Log the transaction.
				[0x0] @@0x12
				[[@0x0]]		"Endowment"
				[[(+ @0x0 1)]] 	(TIMESTAMP)
				[[(+ @0x0 2)]] 	(calldataload 32)
				[[(+ @0x0 3)]] 	(calldataload 64)
				[[0x12]] (+ @@0x12 @@0x11)
				
				[0x0] 1
				(return 0x0 32)
			}
		)
		
		[0x0] 0
		(return 0x0 32)
		
	} 
	0x0 ) ) ; End of body 
}