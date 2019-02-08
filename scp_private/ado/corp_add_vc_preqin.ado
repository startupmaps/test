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

capture program drop corp_add_vc_preqin

program define corp_add_vc_preqin , rclass
	syntax namelist , dta(string) [vcdta(string)]

	clear
	u `dta'
	safedrop firstvc_preqin
	save `dta' , replace
 
	if "`vcdta'" == "" { 
	    local vcdta   ~/projects/reap_proj/data/preqin_vc_series_a.dta
	}

	local state `1'
	u `vcdta' , replace
	keep if stateabbr == "`state'"
	local N = _N
	di "There are `_N' firms with VC in `state'"
	save ~/temp/VC.`state'.preqin.dta , replace
	jnamemerge ~/temp/VC.`state'.preqin.dta  `dta'
	drop if _mergex == "no match"
	if _N > 0 {
	    collapse (min) firstvc_preqin=firstvc, by(dataid)

	    merge 1:m dataid using `dta'
	    drop if _merge == 1
	    drop _merge
	    save `dta' , replace
	}
end

