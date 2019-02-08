/* DATA SETUP SCRIPTS


clear 

import delimited using "/home/jorgeg/projects/reap_proj/raw_data/VentureCapital/capitaliq/All Series A VC Investments.csv" , delim(",") varnames(1)

shortstate state , gen(datastate)
gen vcdate = date(investment,"MDY",2050)
rename portfoliocompany companyname
tomname companyname
save ~/projects/reap_proj/data/capitaliq_vc_series_a.dta , replace




*/

capture program drop corp_add_vc_capitaliq

program define corp_add_vc_capitaliq , rclass
	syntax namelist , dta(string) [vcdta(string)]

	clear
	u `dta'
	safedrop firstvc_capitaliq
	save `dta' , replace

	if "`vcdta'" == "" { 
	    local vcdta   ~/projects/reap_proj/data/capitaliq_vc_series_a.dta
	}

	local state `1'
	u `vcdta' , replace
	keep if stateabbr == "`state'"
	save ~/temp/VC.`state'.capitaliq.dta , replace
	jnamemerge ~/temp/VC.`state'.capitaliq.dta  `dta'
	drop if _mergex == "no match"
	
	if _N > 0 {
	    collapse (min) firstvc_capitaliq=firstvc, by(dataid)

	    merge 1:m dataid using `dta'
	    drop if _merge == 1
	    drop _merge
	    save `dta' , replace
	}
end
