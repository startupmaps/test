clear
cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg
set more off
global prepare_minimal 0
global prepare_state 0
global makefile 0
global makeresult 1
global audit_extfile 1
global statelist AK AR AZ CA CO FL GA IA ID IL KY MA ME // MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
global longstatelist ALASKA ARKANSAS ARIZONA CALIFORNIA COLORADO FLORIDA GEORGIA IOWA IDAHO ILLINOIS KENTUCKY MASSACHUSETTS MAINE // MICHIGAN MINNESOTA MISSOURI NORTH_CAROLINA NORTH_DAKOTA NEW_JERSEY NEW_MEXICO NEW_YORK OHIO OKLAHOMA OREGON RHODE_ISLAND SOUTH_CAROLINA TENNESSEE TEXAS UTAH VIRGINIA VERMONT WASHINGTON WISCONSIN WYOMING


use /NOBACKUP/scratch/share_scp/ext_data/mergers.dta , clear


use  /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta , clear
keep if year(dateannounced)  <= 2014
destring equityvalue, replace force
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate)
tomname targetname
save /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.pre2014.dta , replace



clear
u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta	
tostring dataid , replace 
rename state datastate 
gen obs = 1
capture drop match_* mfull_name
tomname entityname
keep if incyear <= 2014
safedrop mergerdate mergeryear targetname equityvalue
save `state'.only.dta, replace


clear
corp_add_mergers `state' ,dta(`state'.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.pre2014.dta) storenomatched(`state'.nomatch_new.dta) longstate(`longstate')

keep if mergerdate != .
append using AK.nomatch_new.dta
gen is_match = dataid != ""
collapse (max) equityvalue, by(targetname is_match)
tabstat equityvalue, by(is_match) stats(sum)
tab is_match
tab is_match if equityvalue !=.
	




use /user/user1/yl4180/save/Z_mergers.dta , clear




if $prepare_minimal == 1{

	u analysis34.minimal.dta
	keep dataid datastate obs is_merger
	rename is_merger  
	save minimal_temp.dta, replace // a lite version of minimal

	collapse (sum) obs  , by(datastate)
	export delimited using /user/user1/yl4180/save/audit_mergers.csv, replace
	save audit/audit_mergers.dta, replace
	
}


if $prepare_state == 1{

	foreach state in $statelist{
	u minimal_temp.dta, clear
	keep if datastate == "`state'"
	save audit/`state'.only.dta, replace
	
	}
}

cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/audit

if $makefile == 1{
set more off
local n: word count $statelist
	forvalues i = 1/`n'{
	local state: word `i' of $statelist
	local longstate: word `i' of $longstatelist
	local longstate= subinstr("`longstate'","_"," ",.)
	
	/** CHANGE: drop this
	u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta, clear
	tostring dataid, replace
	save /NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta,replace
	u `state'.only.dta, clear
	merge 1:m dataid 
	
	keep if _merge == 3
	drop _merge
	duplicates drop dataid, force
	*/
	
	clear
	u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta	
	tostring dataid , replace 
	rename state datastate 
	gen obs = 1
	capture drop match_* mfull_name
	tomname entityname
	keep if incyear <= 2014
	safedrop mergerdate mergeryear targetname equityvalue
	save `state'.only.dta, replace
	
	clear
	corp_add_mergers `state' ,dta(`state'.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta) storenomatched(`state'.nomatch_old.dta)  longstate(`longstate')
	gen merger_old = !missing(mergerdate) 
	gen nonmergers_old = missing(mergerdate)
	drop if year(mergerdate) > 2013 & mergerdate !=. // we can keep this
	rename mergerdate mergerdate_old
	
	replace equityvalue = "0" if equityvalue == "np" | missing(equityvalue)
	replace equityvalue = subinstr(equityvalue, ",","",.)
	destring equityvalue, replace
	
	rename equityvalue equityvalue_old
	keep dataid datastate merger_old nonmergers_old mergerdate_old obs match_name entityname equityvalue_old
	//DROP: duplicates drop dataid, force
	save `state'.mergers.dta, replace
	
	clear
	u `state'.only.dta
	keep dataid datastate obs entityname match_* mfull_name
	save `state'.only.dta, replace
	
	clear
	corp_add_mergers `state' ,dta(`state'.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.pre2014.dta) storenomatched(`state'.nomatch_new.dta) longstate(`longstate')
	gen merger_new = !missing(mergerdate)
	gen nonmergers_new = missing(mergerdate)
	rename mergerdate mergerdate_new
	
	replace equityvalue = "0" if equityvalue == "np" | missing(equityvalue)
	replace equityvalue = subinstr(equityvalue, ",","",.)
	destring equityvalue, replace
	
	rename equityvalue equityxvalue_new
	keep dataid merger_new nonmergers_new mergerdate_new match_name entityname equityvalue_new
	// DROP: duplicates drop dataid, force
	save `state'.mergers_new.dta, replace
	
	clear
	u `state'.only.dta
	keep dataid datastate obs entityname match_* mfull_name
	save `state'.only.dta, replace
	
	clear
	corp_add_mergers `state' ,dta(`state'.only.dta) merger(/user/user1/yl4180/save/Z_mergers.dta) storenomatched(`state'.nomatch_Z.dta) longstate(`longstate')
	gen merger_Z = !missing(mergerdate)
	gen nonmergers_Z =missing(mergerdate)
	drop if year(mergerdate) > 2013 & mergerdate !=.
	rename mergerdate mergerdate_Z
	
	replace equityvalue = "0" if equityvalue == "n.a." | missing(equityvalue)
	replace equityvalue = subinstr(equityvalue, ",","",.)
	destring equityvalue, replace
	replace equityvalue = equityvalue / (0.784 * 1000)
	
	rename equityvalue equityvalue_Z
	keep dataid merger_Z nonmergers_Z mergerdate_Z match_name entityname equityvalue_Z
	merge m:m dataid using `state'.mergers_new.dta
	drop _merge
	merge m:m dataid using `state'.mergers.dta
	drop _merge
	//DROP: duplicates drop dataid, force
	
	//add next 2
	// keep if datastate ==  "`state'" 
	replace datastate =  "`state'"  // some company names got matched in other state, a potential issue, might inflate result.
	drop if missing(entityname)
	collapse (max) merger_old merger_new merger_Z n* obs equityvalue*, by(match_name datastate)
	save `state'.mergers_all.dta, replace
	}
}

if $makeresult == 1{
clear
gen a = .
	foreach state in $statelist{
		append using `state'.mergers_all.dta
		save allstates.mergers.dta, replace
	}
drop a
save allstates.mergers.dta, replace

collapse (sum) merger_old merger_new merger_Z n* obs equityvalue*, by(datastate)
save audit_mergers.dta, replace
export delimited using /user/user1/yl4180/save/audit_mergers.csv, replace

}

if $audit_extfile == 1{
	u /NOBACKUP/scratch/share_scp/ext_data/mergers.dta, clear // 1990 - 2014
	gen obs_old = 1
	drop if missing(targetname)
	gen year = year(dateannounced)
	drop if year > 2013 // edit as needed
	replace targetstate = trim(upper(targetstate))
	
	replace equityvalue = "0" if equityvalue == "np" | missing(equityvalue)
	replace equityvalue = subinstr(equityvalue, ",","",.)
	destring equityvalue, replace	

	collapse (max) dateannounced equityvalue, by(match_name targetstate obs_old)
	// duplicates drop targetname, force
	collapse (sum) obs_old equityvalue, by(targetstate) 
	rename equityvalue value_old
	gsort -obs_old
	merge 1:1 targetstate using /user/user1/yl4180/us.dta
	keep if _merge == 3
	drop _merge targetstate 
	save ext_old.dta, replace

	u /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta, clear // 1980 - 2018
	gen obs_new = 1
	drop if missing(targetname)
	gen year = year(dateannounced)
	drop if year < 1990 | year > 2013 // edit as needed
	replace targetstate = trim(upper(targetstate))
	
	replace equityvalue = "0" if equityvalue == "np" | missing(equityvalue)
	replace equityvalue = subinstr(equityvalue, ",","",.)
	destring equityvalue, replace
	
	collapse (max) dateannounced equityvalue, by(match_name targetstate obs_new)
	// duplicates drop targetname, force
	collapse (sum) obs_new equityvalue, by(targetstate) 
	rename equityvalue value_new
	
	gsort -obs_new
	merge 1:1 targetstate using /user/user1/yl4180/us.dta
	keep if _merge == 3
	drop _merge targetstate 
	save ext_new.dta, replace
	
	u /user/user1/yl4180/save/Z_mergers.dta, clear //1996 - 2019
	gen obs_Z = 1
	drop if missing(targetname)
	gen year = year(dateannounced)
	drop if year > 2013 // edit as needed
	replace targetstate = trim(upper(targetstate))
	
	replace equityvalue = "0" if equityvalue == "n.a." | missing(equityvalue)
	replace equityvalue = subinstr(equityvalue, ",","",.)
	destring equityvalue, replace
	replace equityvalue = equityvalue / (0.784 * 1000)
	
	collapse (max) dateannounced equityvalue, by(match_name targetstate obs_Z)
	// duplicates drop targetname, force
	collapse (sum) obs_Z equityvalue, by(targetstate) 
	rename equityvalue value_Z
	gsort -obs_Z
	merge 1:1 targetstate using /user/user1/yl4180/us.dta
	keep if _merge == 3
	drop _merge targetstate 
	save ext_Z.dta, replace
	
	merge 1:1 state using ext_old.dta
	drop _merge
	merge 1:1 state using ext_new.dta
	drop _merge
	save ext_all.dta, replace
	
	u ext_all.dta, clear
	rename state datastate
	merge 1:1 datastate using audit_mergers.dta
	drop _merge
	save ext_all.dta, replace
	

	collapse (sum) obs* merger* value* equityvalue*
	gen ratio_old = 1 - merger_old / obs_old
	gen ratio_new = 1 - merger_new / obs_new
	gen ratio_Z = 1- merger_Z /obs_Z
	gen vratio_old = 1 - equityvalue_old / value_old
	gen vratio_new = 1 - equityvalue_new / value_new
	gen vratio_Z = 1 - equityvalue_Z / value_Z
	
	rename ratio_* misspct_*
	save audit_collapse.dta, replace
	export delimited using /user/user1/yl4180/save/audit_collapse.csv, replace
	
	u ext_all.dta, clear
	gen unmatched_old = obs_old - merger_old
	gen ratio_old = unmatched_old / obs_old 
	gen unmatched_new = obs_new - merger_new 
	gen ratio_new = unmatched_new / obs_new 
	gen unmatched_Z = obs_Z - merger_Z
	gen ratio_Z = unmatched_Z / obs_Z 
	
	gen vratio_old = 1 - equityvalue_old /value_old
	gen vratio_new = 1-equityvalue_new / value_new
	gen vratio_Z = 1 - equityvalue_Z / value_Z
	drop nonmerger*
	order datastate merger_old merger_new merger_Z ratio_old ratio_new ratio_Z unmatched_old unmatched_new unmatched_Z obs vratio_old vratio_new vratio_Z equityvalue_old value_old equityvalue_new value_new equityvalue_Z value_Z
	gsort -merger_old
	rename ratio_* misspct_* 
	rename vratio_* vmisspct_*
	save ext_all.dta, replace
	export delimited using /user/user1/yl4180/save/ext_all.csv, replace
	
}


