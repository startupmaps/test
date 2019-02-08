capture program drop corp_add_vc2

program define corp_add_vc2,rclass
	syntax namelist(min=1 max=1), DTApath(string) [NOSave] VCpath(string) longstate(string) [nomatchdta(string)] [manualmatch(string)] [mturkmatch(string)] [dropexisting] [skipcollapsed]
	
	*set trace on

	local state="`1'"
	local filepath = "`dtapath'"
	
	
	if "`dropexisting'"  == "dropexisting" {
		qui{
			clear
			u `dtapath'
			safedrop ones
			gen ones = 1
			safedrop companyname companystateregion firstvc maxvcquality1996 maxvcquality1997 maxvcquality1998 maxvcquality1999 maxvcquality2000 
			safedrop maxvcquality2001 maxvcquality2002 maxvcquality1995 maxvcquality2003 maxvcquality2004 maxvcquality2005 meanvcquality1996
			safedrop meanvcquality1997 meanvcquality1998 meanvcquality1999 meanvcquality2000 meanvcquality2001 meanvcquality2002 
			safedrop meanvcquality1995 meanvcquality2003 meanvcquality2004 meanvcquality2005
			save `dtapath', replace
		}
	}
	
	clear
	u `vcpath'
	replace companystate = upper(trim(itrim(companystate)))
	di "filepath = `filepath'"
	di "LONGSTATE = `longstate'"
	keep if companystate == trim(itrim(upper("`longstate'")))
	
	local totalvc = _N
	save ~/temp/`state'vc.dta,replace
	
		
	qui: jnamemerge `filepath' ~/temp/`state'vc.dta , both  `skipcollapsed'
	di "Initial match results"
	tab _mergex
	if "`nomatchdta'" != "" {
		savesome if _mergex == "no match (rightfile)" using `nomatchdta'
	}
	drop if _mergex == "no match (rightfile)"
	
	capture confirm variable ones

	if  _rc != 0 {
		gen ones = 1
	}
	sum ones if _mergex != "no match"
	local initialmatch `r(N)'
	
	safedrop _merge _mergex
	
	
	
	
	
	if "`manualmatch'" != "" {
		clear

		import delimited  using `manualmatch', delim("|") varnames(1)
		rename corpid corpnumber

		drop if corpnumber == "ERROR" | corpnumber == "MULTIPLE" | corpnumber == "NOT FOUND"

		by corpnumber (invdate), sort: gen firstinv = _n == 1
		keep if firstinv
		drop firstinv

		merge 1:m corpnumber using `dtapath'
		
		
		di "Matching for `manualmatch'"
		
		tab _merge
		sum ones if _merge == 1
		gen shouldmatch = _merge == 1
		
		 sum ones if _merge == 3
		 local manualcount `r(N)'
		
		 drop if _merge == 1
		 drop _merge
		 
		 
		 gen invd = date(invdate,"DMY")
		 replace firstvc = invd if !missing(invd)
		 drop invdate invd 
		 
	
	}
	
	if "`mturkmatch'" != "" {
		clear

		import delimited  using `mturkmatch', delim(",") varnames(1) bindquote(strict)
		keep inputname inputinvdate answerweb_url
		rename (inputname inputinvdate answerweb_url) (firmname invdate corpnumber)
		replace corpnumber = itrim(trim(upper(corpnumber)))

		drop if corpnumber == "ERROR" | corpnumber == "MULTIPLE" | corpnumber == "NOT FOUND"

		by corpnumber (invdate), sort: gen firstinv = _n == 1
		keep if firstinv
		drop firstinv

		di "Matching for `mturkmatch'"

		merge 1:m corpnumber using `dtapath'
		tab _merge
		
		 sum ones if _merge == 3
		 local mturkcount `r(N)'
		
		
		sum ones if _merge == 1
		blankgen shouldmatch 
		replace shouldmatch = _merge == 1
		
		 drop if _merge == 1
		 drop _merge
		 gen invd = date(invdate,"DMY")
		 replace firstvc = invd if !missing(invd)
		 drop invdate invd 
	}
	
	blankgen shouldmatch
	sum ones if shouldmatch
	local shouldmatch = `r(N)'
	drop shouldmatch
	
	sum ones if !missing(firstvc) & firstvc < (incdate - 90)
	local earlyvcdate = `r(N)'
	
	local nomatch = `totalvc' - `initialmatch' - `manualcount' - `mturkcount' - `shouldmatch'
	local totalmatch = `totalvc' - `nomatch'
	
	di "Total VC: `totalvc'"
	di "Total Matched: `totalmatch'"
	di ""
	di "Matched by name: `initialmatch'"
	di "Manual Matched 1: `manualcount'"
	di "Manual Matched 2: `mturkcount'"
	di "Different State or pre-1988: `shouldmatch'"
	di "No Match: `no match'"
	di ""
	di "VC date before incdate: `earlyvcdate'"

	if "`nosave'" == "" {
		save  `filepath',replace 
	}
		
	
end
