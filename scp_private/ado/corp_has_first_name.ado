
/**
 Build  Name file:
 clear
	import delimited name gender occurences using ~/ado/names/NATIONAL.TXT, delim(",")
	replace name = upper(trim(name))
	collapse (sum) occurences,by(name)
	gsort -occurences
	gen rank = _n
	save ~/ado/names/names.dta, replace
 
 
 */

 capture program drop corp_has_first_name

program define corp_has_first_name, rclass
	syntax , DTAfile(string) [firstnamedta(string )] [num(integer 100000)]
	if "`firstnamedta'" == "" {
		local firstnamedta = "~/ado/names/names.dta"
	}
	di "Using Name File: `firstnamedta'"
	
	clear
	u `dtafile'
	
	keep dataid entityname
	
	replace entityname = trim(regexr(upper(entityname),"[^A-Z]+"," "))
	split entityname, parse(" ") limit(6)
	gen idx = _n
	rename entityname fullentityname
	reshape long entityname, i(idx) j(namenum) 
	drop if length(entityname) < 4
	rename entityname name
	merge m:1 name using `firstnamedta'
	
	keep if _merge == 3 & rank <= `num'
	
	gen haspropername = 1
	collapse (max) haspropername,by(dataid)
	merge 1:m dataid using `dtafile'
	drop if _merge == 1
	drop _merge
	replace haspropername = 0 if missing(haspropername)
	save `dtafile',replace
	
end

