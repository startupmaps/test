/* DATA SETUP SCRIPTS

clear 

import delimited using "/home/jorgeg/projects/reap_proj/raw_data/VentureCapital/preqin/Preqin All US VC Investments.csv" , delim(",") varnames(1)

shortstate state , gen(stateabbr)
gen vcdate = date(dealdate,"MDY",2050)
rename portfoliocompany companyname
tomname companyname
keep companyname vcdate state stateabbr dealsizeus stage 
save ~/projects/reap_proj/data/preqin_vc_series_a.dta , replace
*/

capture program drop corp_add_vc_crunchbase

program define corp_add_vc_crunchbase , rclass
	syntax namelist , dta(string) [vcdta(string)]
 
	clear
	u `dta'
	safedrop firstvc_crunchbase
	save `dta', replace

	if "`vcdta'" == "" { 
	    local vcdta   ~/projects/reap_proj/data/crunchbase_vc_series_a.dta
	}

	local state `1'
	u `vcdta' , replace
	keep if stateabbr == "`state'"
	save ~/temp/VC.`state'.crunchbase.dta , replace
	jnamemerge ~/temp/VC.`state'.crunchbase.dta  `dta'
	drop if _mergex == "no match"
	if _N > 0 {
	    collapse (min) firstvc_crunchbase=firstvc, by(dataid)

	    merge 1:m dataid using `dta'
	    drop if _merge == 1
	    drop _merge
	    save `dta' , replace
	}
end

