
/**
 Build  Name file:
	clear
	gen entityname = "" 
	save ~/ado/names/firmnames.dta,replace
	
	foreach state in CA MA TX FL WA NY {
		clear
		u ~/final_datasets/`state'.dta
		keep entityname		
		replace entityname = trim(regexr(upper(entityname),"[^A-Z]+"," "))
		drop if length(entityname) < 4
		
		split entityname, parse(" ")
		replace entityname = trim(regexr(upper(entityname),"[^A-Z]+"," "))
		gen idx = _n
		drop entityname
		reshape long entityname, i(idx) j(namenum) 
		drop if length(entityname) < 4
		gen numocurrences = 1
		collapse (sum) numocurrences, by(entityname)
		append using ~/ado/names/firmnames.dta
		save ~/ado/names/firmnames.dta, replace		
	}	

	
	collapse (sum) numocurrences, by(entityname)
	sort numocurrences
	gen uniquename = _n/_N
	
	save ~/ado/names/firmnames.dta, replace
 
 
 */

capture program drop corp_name_uniqueness

program define corp_name_uniqueness, rclass
	syntax, DTAfile(string) [firmnamesdta(string)] [func(string)] 
	
	if "`firmnamesdta'" == "" {
		local firmnamesdta = " ~/ado/names/firmnames.dta"
	}
	di "Using Name File: `firmnamesdta'"
	
	if "`func'" == "" {
		local func = "min"
	}
	di "Using Collapse Function: `func'"
	
	
	clear
	u `dtafile'
	
	keep dataid entityname
	split entityname, parse(" ") limit(6)
	gen idx = _n
	rename entityname fullentityname
	reshape long entityname, i(idx) j(namenum) 
	drop if length(entityname) < 4
	
	merge m:1 entityname using `firmnamesdta'
	
	keep if _merge == 3
	
	
	collapse (`func') numocurrences,by(dataid)
	rename numocurrences uniquename
	
	merge 1:m dataid using `dtafile'
	drop if _merge == 1
	drop _merge
	save `dtafile' , replace
	
end
