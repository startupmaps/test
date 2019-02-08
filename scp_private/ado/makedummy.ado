**
*
* Summary:
*   Makes all missing values zero for variables
*
*
capture program drop makedummy
program define makedummy,rclass
	foreach v of varlist `0' {
		di "Converting `v' into dummy"
		replace `v' = 0 if missing(`v')
		replace `v' = 1 if `v' > 1 & !missing(`v')
	}
end
