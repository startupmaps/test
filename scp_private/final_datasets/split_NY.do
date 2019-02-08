gen group = 1 if _n < _N/2

replace group = 2 if group ==.

save NY.dta, replace

foreach i of num 1/2{
	use NY.dta if group ==`i', clear
	drop group
	save NY`i'.dta, replace
}
u NY.dta, clear
drop group
save NY.dta, replace
keep dataid entityname incdate address city state stateaddress zipcode
save NY_lite.dta, replace
