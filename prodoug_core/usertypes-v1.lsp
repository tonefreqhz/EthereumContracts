; INIT
{	
	;For DOUG integration
	[[0x10]] 0x8bffd298a64ee36eb7b99dcc00d2c67259d15c60 ;Doug Address
	;List data section
	[[0x11]] 0x0										;Size of list
	[[0x12]] 0x0										;Tail address
	[[0x13]] 0x0										;Head address
	
	[0x0] "reg"
	[0x20] "usertypes"
	(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32) ;Register with DOUG  TODO remove.
	
	; Add userdata (UserData contract) when constructing.
	[0x0](LLL
	{
		[[0x10]] 0x8bffd298a64ee36eb7b99dcc00d2c67259d15c60
		;body section
		[0x0](LLL
			{
				; USAGE: 0 : "setdoug", 32 : dougaddress
				; RETURNS: -
				; NOTES: Set the DOUG address. This can only be done once.
				; INTERFACE Factory<?>
				(when (= (calldataload 0) "setdoug") 
					{
						(when @@0x10
							{
								[0x0] 0
								(return 0x0 32)
							}
						)
						[[0x10]] (calldataload 32)
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
							
				; USAGE: 0 : "generate"
				; RETURNS: Pointer to a Group contract.
				; INTERFACE Factory<Group>
				(when (= (calldataload 0) "generate")
					{
						
						[0x0](LLL
							{
							    [[0x1]] "userdata"
							   ;[[0x2]] Reserved for user address.
								[[0x3]] (TIMESTAMP) ; Date of creation.
							   ;[[0x4]] 0 ; Sovereigns
							   ;[[0x5]] address to holdings.
							   ;[[0x6]] home (address)
							   
							   ;[[0x111]] 0 ; Size
							   ;[[0x112]] 0 ; Head
							   ;[[0x113]] 0 ; Tail
								
								;body section
								[0x0](LLL
									{
										
										; USAGE: 0 : "setdoug", 32 : dougaddress
										; RETURNS: 1 if successful, 0 if not.
										; NOTES: Set the DOUG address. This can only be done once.
										; INTERFACE Group
										(when (= (calldataload 0) "setdoug")
											{
												(when @@0x10 
													{
														[0x0] 0
														(return 0x0 32)
													}
												) ; Once doug has been set, don't let it be changed.
												[[0x10]] (calldataload 32)
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
										
										[0x0] (calldataload 0)		;This is the command
										[0x20] (calldataload 32)	;This is the name
										
										; USAGE: 0 : "setuser", 32 : useraddress
										; NOTES: Set the user address.
										; INTERFACE: UserData
										(when (= @0x0 "setuser") 
											{
												; Don't let caller access the reserved addresses.
												(unless (> @0x20 0x120)
													{
														[0x0] 0
														(return 0x0 32)
													}
												)
												(when @@0x2 ; User address is final
													{
														[0x0] 0
														(return 0x0 32)
													}
												)
												[[0x2]] (calldataload 32)
												[0x0] 1
												(return 0x0 32)
											}
										)
										
										; USAGE: 0 : "adduser", 32 : "username", 64: user address
										; RETURNS: 1 if successful, otherwise 0
										; NOTES: Add a user to this group. If successful, it will add the
										;		 username and address. In the case of userdata, the addres
										;		 refers not to the user address, but the address of the
										; 		 users user-data.
										; INTERFACE Group
										(when (= @0x0 "adduser") ; Register a group
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
												
												; Don't let caller access the reserved addresses.
												(unless (> @0x20 0x120)
													{
														[0x0] 0
														(return 0x0 32)
													}
												)
												
												;Store group address at group name.
												[[@0x20]] (calldataload 64)
				
												(if @@0x111 ; If there are elements in the list. 
													{
														;Update the list. First set the 'next' of the current head to be this one.
														[[(+ @@0x113 2)]] @0x20
														;Now set the current head as this ones 'previous'.
														[[(+ @0x20 1)]] @@0x113	
													}
												{
												;If no elements, add this as tail
												[[0x112]] @0x20
											}
				
										)
	
										;And set this as the new head.
										[[0x113]] @0x20
										;Increase the list size by one.
										[[0x111]] (+ @@0x111 1)
				
										;Return the value 1 for a successful register
										[0x0] 1
										(return 0x0 32)
									} ;end body of when
								); end when
								
								; USAGE: 0 : "removeuser", 32 : "username"
								; RETURNS: 1 if successful, otherwise 0.
								; NOTES: Removes the user "username" from the group (if he exists).
								; INTERFACE Group
								(when (= @0x0 "removeuser") ; When de-regging by name.
									{	
										; Don't let caller access the reserved addresses.
										(unless (> @0x20 0x120)
											{
												[0x0] 0
												(return 0x0 32)
											}
										)
										
										(unless @@ @0x20 ; If that user (group) is not part of the userdata - cancel.
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
				
												(unless (|| @0x40 (= (CALLER) @@ @0x20) ) (return 0x40 32) )	
											}
										)
																					
										[0x40] @@(+ @0x20 1) ; Here we store the this ones 'previous'.
										[0x60] @@(+ @0x20 2) ; And next
			
										(if @0x60
											{
												(if @0x40
													{
														;Change previous elements 'next' to this ones 'next'.
														[[(+ @0x40 2)]] @0x60
														;Change next elements 'previous' to this ones 'previous'.
														[[(+ @0x60 1)]] @0x40
													}
													{   ; We are the tail.
														;Set next elements previous to 0
														[[(+ @0x60 1)]] 0
														;Next element is now tail.
														[[0x112]] @0x60
													}											
												)
											}
					
											{
												(if @0x40
													{
														;This element is the head - unset 'next' for the previous element making it the head.
														[[(+ @0x40 2)]] 0
														;Set previous as head
														[[0x113]] @0x40	
													}
													{
														; This element is the only element. Reset head and tail.
														[[0x112]] 0
														[[0x113]] 0
													}					
												)
											}
										)
	
										;Now clear out this element and all its associated data.
				
										[[@0x20]] 0			;The address of the name
										[[(+ @0x20 1)]] 0	;The address for its 'previous'
										[[(+ @0x20 2)]] 0	;The address for its 'next'
						
										;Decrease the size counter
										[[0x111]] (- @@0x111 1)
										[0x0] 1
										(return 0x0 32)
	
									} ; end when body
								) ;end when
		
								; USAGE: 0 : "hasuser", 32 : "username"
								; RETURNS: Returns the address coupled with the user "username", or null.
								; INTERFACE: Group
								(when (= @0x0 "hasuser")
									{
										; Don't let caller access the reserved addresses.
										(unless (> @0x20 0x120)
											{
												[0x0] 0
												(return 0x0 32)
											}
										)
										[0x0] @@ @0x20
										(return 0x0 32)
									}
								)
								
								; USAGE: 0 : "gettype"
								; RETURNS: Returns the type of the group.
								; INTERFACE: Group
								(when (= (calldataload 0) "gettype") 
									{		
										[0x0] @@0x1
										(return 0x0 32)
									}
								)
										
								; USAGE: 0 : "capacity"
								; RETURNS: Returns the capacity of the group (0 means no limit)
								; INTERFACE: Group
								(when (= (calldataload 0) "capacity") ; 0 means no size limit.
									{		
										[0x0] @@0x2
										(return 0x0 32)
									}
								)
									
								; USAGE: 0 : "setcapacity"
								; RETURNS: 0 - this is not allowed in UserData
								; INTERFACE: Group
								(when (= (calldataload 0) "setcapacity")
									{
										[0x0] 0
										(return 0x0 32)
									}
								)
										
								; USAGE: 0 : "currentsize"
								; RETURNS: Returns the current number of users in the group.
								; INTERFACE: Group
								(when (= (calldataload 0) "currentsize")
									{		
										[0x0] @@0x111 
										(return 0x0 32)
									}
								)
								
								; USAGE: 0 : "clear"
								; RETURNS: 1 if successful, otherwise 0
								; INTERFACE: Group
								(when (= (calldataload 0) "clear")
									{	
										; If the group is empty, return.
										(unless @@0x111
											{
												[0x0] 1
												(return 0x0 32)
											}
										)
										
										[0x40] "get"
										[0x60] "actions"
										(call (- (GAS) 100) @@0x10 0 0x40 64 0x80 32)
										
										(when @0x80 ; If so, validate the caller to make sure it's a proper action.
											{
												[0x40] "validate"
												[0x60] (CALLER)
												(call (- (GAS) 100) @0x80 0 0x40 64 0x40 32)
												
												(unless @0x40 (return 0x40 32) )		
											}
										)
										
										;Get users to 0x0
										[0x0] "get"
										[0x20] "users"
										(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32)
										
										[0xA0] @@0x2
										
										[0x40] "getnick"
										[0x60] @@0x2
										(call (- (GAS) 100) @0x0 0 0x40 64 0xA0 32) ;User name at 0xA0
										
										;Start at tail
										[0x20] @@0x112
										
										; While we have a next element.
										(while @0x20
											{
												[0x60] "removeuser"
												[0x80] @0xA0
												(call (- (GAS) 100) @@ @0x20 0 0x60 64 0x40 32)
												
												;Do a little thing.
												[0x40] @0x20
												[0x20] @@(+ @0x20 2)
												
												;Now clear this entry.
												[[@0x40]] 0
												[[(+ @0x40 1)]] 0
												[[(+ @0x40 2)]] 0
											}	
										)
										
										; Clear size, head and tail.
										[[0x111]] 0
										[[0x112]] 0
										[[0x113]] 0
										
										[0x0] 1
										(return 0x0 32)
									}
								)
								
										
								; USAGE: 0 : "setname" "name"
								; RETURNS: 0 (not allowed in UserData)
								; INTERFACE: Group
								(when (= (calldataload 0) "setname")
									{		
										[0x0] 0
										(return 0x0 32)
									}
								)
								
								; USAGE: 0 : "gettokens"
								; RETURNS: Amount of tokens.											
								(when (= @0x0 "gettokens")
									{
										[0x0] @@0x4
										(return 0x0 32)
									}
								)
								
								; USAGE: 0 : "addtokens", 32 : amount
								; RETURNS: 1
								(when (= @0x0 "addtokens")
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
										
										[[0x4]] (+ @@0x4 (calldataload 32) )
										
										[0x0] 1
										(return 0x0 32)
									}
								)
								
								; USAGE: 0 : "removetokens", 32 : amount
								; RETURNS: 1										
								(when (= @0x0 "removetokens")
									{
										(when (< @@0x4 (calldataload 32))
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
										
										[[0x4]] (- @@0x4 (calldataload 32))
										
										[0x0] 1
										(return 0x0 32)
									}
								)
								
								; USAGE: 0 : "setholdings", 32 : address
								; NOTES: Can only be set once.
								; RETURNS: 1 if succesful, 0 otherwise.									
								(when (= @0x0 "setholdings")
									{
										[0x0] "get"
										[0x20] "users"
										(call (- (GAS) 100) @@0x10 0 0x0 64 0x20 32)
										
										(unless (= (CALLER) @0x20) ; Only users are allowed to do this.
											{
												[0x0] 0
												(return 0x0 32)
											}
										)
										
										[[0x5]] (calldataload 32)
										
										[0x0] 1
										(return 0x0 32)
									}
								)
								
								; USAGE: 0 : "getholdings"
								; RETURNS: The address of the holdings contract.										
								(when (= @0x0 "getholdings") 
									{
										[0x0] @@0x5
										(return 0x0 32)
									}
								)
								
								; USAGE: 0 : "sethome", 32 : address
								; NOTES: Set the address of the house
								; RETURNS: 1 if succesful, 0 otherwise.									
								(when (= @0x0 "sethome")
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
										
										[[0x6]] (calldataload 32)
										
										[0x0] 1
										(return 0x0 32)
									}
								)
								
								; USAGE: 0 : "gethome"
								; RETURNS: The home address.										
								(when (= @0x0 "gethome") 
									{
										[0x0] @@0x6
										(return 0x0 32)
									}
								)
								
								; USAGE: 0 : "kill"
								; RETURNS: -
								; NOTE: suicides the contract if called by "actions".											
								(when (= @0x0 "kill") ;clean up
									{
										[0x0] "get"
										[0x20] "actions"
										(call (- (GAS) 100) @@0x10 0 0x0 64 0x0 32) 
														
										(unless (= (CALLER) @0x0) (stop) ) ; Only 'actions' can do this.
																				
										(suicide (CALLER))
									}
								)
								
							} 0x20 )
							(return 0x20 @0x0) ;Return body
							} 0x20 )
						[0x0](CREATE 0 0x20 @0x0)
						(return 0x0 32)
					}
				)
				
				[0x0] "get"
				[0x20] "usertypes"
				(call (- (GAS) 100) @@0x10 0 0x0 64 0x40 32)
				
				; Only 'usertypes' can do this.
				(when (&& (= (CALLER) @0x40) (= (calldataload 0) "kill")) (suicide (CALLER)) )
				
				[0x0] 0
				(return 0x0 32)
				
			} 0x20 )
		(return 0x20 @0x0) ;Return body
	}
	0x20 )
	[0x0](create 0 0x20 @0x0)
	
	; Register userdata as the first element in the list.
	[["userdata"]] @0x0
	[[0x11]] 1
	[[0x12]] "userdata"
	[[0x13]] "userdata"
	
	(return 0x0 (lll 
	{
		[0x0] (calldataload 0)		;This is the command
		[0x20] (calldataload 32)	
		
		; USAGE: 0: "create" 32: "name"
		; RETURNS: Address to the newly created Group, or null.
		; INTERFACE FactoryManager<Factory<Group>>
		(when (= @0x0 "create")  ;TODO more security?
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 0x40)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				[0x0] @@ (calldataload 32)
				[0x20] "generate"
				(call (- (GAS) 100) @0x0 0 0x20 32 0x40 32) ; Get the address of the newly generated poll contract.
				
				(unless @0x40 (return 0x40 32) )
				
				[0x0] "setdoug"
				[0x20] @@0x10
				(call (- (GAS) 100) @0x40 0 0x0 64 0x60 32)
				
				(return 0x40 32)
			}
		)
		
		; USAGE: 0: "hastype" 32: "name"
		; RETURNS: Pointer to the Group generator contract with name "name", or null.
		; INTERFACE: FactoryManager<Factory<Group>>
		; DEPRECATED: Will be replaced with a command that is the same for all factory managers.
		(when (= @0x0 "hastype")
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 0x40)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				[0x0] @@ (calldataload 32)
				(return 0x0 32)
			}
		)
		
		; USAGE: 0: "kill"
		; RETURNS: -
		; NOTES: Suicides the contract if called by DOUG
		(when (= @0x0 "kill")
			{
				(when (= (CALLER) @@0x10) 
					(suicide (CALLER))
				
				)
			} 
		) ;Kill option
		
		
		[0x40] (calldataload 64)
		
		; USAGE: 0: "reg" 32: "name", 64: address
		; RETURNS: 1 if successful, otherwise 0.
		; INTERFACE FactoryManager<Factory<Group>>
		(when (= @0x0 "reg") 
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 0x40)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
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
				
				;If the name address is non-empty (name already taken) - cancel.
				(when @@ @0x20 
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
							
				; Start by setting the doug address
				[0x60] "setdoug"
				[0x80] @@0x10
				(call (- (GAS) 100) @0x40 0 0x60 64 0xA0 32)
				(unless @0xA0 (return 0xA0 32) )
				
				;Store address at name.
				[[@0x20]] @0x40
	
				(if @@0x11 ; If there are elements in the list. 
					{
						;Update the list. First set the 'next' of the current head to be this one.
						[[(+ @@0x13 2)]] @0x20
						;Now set the current head as this ones 'previous'.
						[[(+ @0x20 1)]] @@0x13	
					} 
					{
						;If no elements, add this as tail
						[[0x12]] @0x20
					}
				
				)
				;And set this as the new head.
				[[0x13]] @0x20
				;Increase the list size by one.
				[[0x11]] (+ @@0x11 1)
				
				;Return the value 1 for a successful register
				[0x0] 1
				(return 0x0 0x20)
			} ;end body of when
		); end when
		
		; USAGE: 0: "dereg" 32: "name"
		; RETURNS: 1 if successful, otherwise 0.
		; INTERFACE FactoryManager<Factory<Group>>
		(when (= @0x0 "dereg")
			{
				; Don't let caller access the reserved addresses.
				(unless (> @0x20 0x40)
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
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
				
				;If the name has no address (does not exist) - cancel.
				[0x40] @@ @0x20
				(unless @0x40 
					{
						[0x0] 0
						(return 0x0 32)
					}
				)
				
				; Suicide generator contract.
				[0x60] "kill"
				(call (- (GAS) 100) @0x40 0 0x60 32 0x60 32)
	
				[0x40] @@(+ @0x20 1) ; Here we store the this ones 'previous' (which always exists).
				[0x60] @@(+ @0x20 2) ; And next
			
				;Change previous elements 'next' to this ones 'next', if this one has a next (this could be the head..)
				(if @0x60
					{
						(if @0x40
							{
								;Change next elements 'previous' to this ones 'previous'.
								[[(+ @0x60 1)]] @0x40
								;Change previous elements 'next' to this ones 'next'.
								[[(+ @0x40 2)]] @0x60		
							}
							{
								; We are tail. Set next elements previous to 0
								[[(+ @0x60 1)]] 0
								; Set next element as current tail.
								[[0x12]] @0x60
							}
							
						)
					}
					
					{
						(if @0x40
							{
								;This element is the head - unset 'next' for the previous element making it the head.
								[[(+ @0x40 2)]] 0
								;Set previous as head
								[[0x13]] @0x40	
							}
							{
								; This element is the tail. Reset head and tail.
								[[0x12]] 0
								[[0x13]] 0
							}					
						)
					}
				)
	
				;Now clear out this element and all its associated data.
				
				[[@0x20]] 0			;The address of the name
				[[(+ @0x20 1)]] 0	;The address for its 'previous'
				[[(+ @0x20 2)]] 0	;The address for its 'next'
						
				;Decrease the size counter
				[[0x11]] (- @@0x11 1)
				[0x0] 1
				(return 0x0 32)
			} ; end when body
		) ;end when
		
		[0x0] 0
		(return 0x0 32)
		
	} 0x0 )) ; End of body
}