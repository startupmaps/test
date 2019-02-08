
/**
 Build Last Name file:
 clear
	import delimited using ~/ado/names/AllLastNames.txt, delim("|") varnames(1)
	rename name lastname
	replace lastname = upper(trim(lastname))
	save ~/ado/names/lastnames.dta, replace
 
 
 */

capture program drop corp_has_last_name

program define corp_has_last_name, rclass
	syntax, DTAfile(string) [lastnamedta(string )] [num(integer 500000)]
	
	
	if "`lastnamedta'" == "" {
		local lastnamedta = "~/ado/names/lastnames.dta"
	}
	di "Using Name File: `lastnamedta'"
	
	
	clear
	u `dtafile'
	
	keep dataid entityname
	
	replace entityname = trim(regexr(upper(entityname),"[^A-Z]+"," "))
	split entityname, parse(" ") limit(6)
	gen idx = _n
	
	rename entityname fullentityname
	reshape long entityname, i(idx) j(namenum) 
	drop if length(entityname) < 4
	rename entityname lastname
	merge m:1 lastname using `lastnamedta'
	
	keep if _merge == 3 & rank <= `num'
	
	gen haslastname = 1
	collapse (max) haslastname,by(dataid)
	merge 1:m dataid using `dtafile'
	drop if _merge == 1
	drop _merge
	replace haslastname = 0 if missing(haslastname)
	save `dtafile',replace
	
end
