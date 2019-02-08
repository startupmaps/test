cd ~/final_datasets

clear
u CA.collapsed.dta
gen datastate = "CA"
tostring dataid,replace
append using MA.collapsed.dta

replace datastate = "MA" if datastate == ""
append using TX.collapsed.dta
replace datastate = "TX" if datastate == ""
append using NY.collapsed.dta
replace datastate = "NY" if datastate == ""
append using WA.collapsed.dta
replace datastate = "WA" if datastate == ""

compress
save 4state.collapsed.dta, replace
