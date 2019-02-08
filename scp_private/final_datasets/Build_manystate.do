cd ~/final_datasets



clear
di "Adding State: `1'"
u `1'.collapsed.dta
gen datastate = "`1'"
tostring dataid,replace

foreach state in `2' `3' `4' `5' `6' `7' `8' `9' {
	di "Adding State: `state'"
	append using `state'.collapsed.dta, force
	replace datastate = "`state'" if datastate == ""
}

compress
