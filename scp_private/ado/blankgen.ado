**
*
* Summary:
*   Drops variables if they exist, does nothing if not 
*
*

capture confirm program drop blankgen

program define blankgen, rclass
	syntax anything, [onlyexisting]
	foreach v in  `0' {
		
		capture confirm variable `v' 
		
		if _rc == 0 {
			di "Var `v' already exists. No action taken"
		}
		else{
			gen `v' = .
		}
	}
end
