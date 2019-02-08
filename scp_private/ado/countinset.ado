capture confirm program drop countinset

program define countinset, rclass
	syntax name [if],wordfile(string) wordvar(string) newvar(string) [filtercol(string)]
	
		
	set more off 
	local entityname = "`1'"
	di "Looking for words of `wordfile' : `wordvar', in the list `entityname' with results in `newvar'"

	
	preserve
	u `wordfile', replace
	replace `wordvar' = upper(trim(`wordvar'))
	
	if "`filtercol'" == "" {
		levels `wordvar',local(wordlist)
	}
	else {
		levels `wordvar' if `filtercol',local(wordlist)
	} 
	
	/*Adding an if allows only use a specific set of firms to count (e.g. only first name)*/
/*	local ifx = ""
	if "`if'" != "" {
		local ifx = subinstr("`if'","if","") + " & "
	}
*/


	restore
	gen `newvar' = 0
	replace `entityname' = upper(trim(itrim(`entityname')))
	foreach v in `r(levels)' {
		local counter=`counter'+1
		di "Matching: '`v''       `counter' of `numwords'"
		replace `newvar' =1 if `ifx' regexm(`entityname',"(^|[^A-Z])`v'([^A-Z]|$)")	
	}

end
