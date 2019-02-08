clear
cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg
set more off
global prepare_minimal 0
global prepare_state 0
global makefile 0
global makeresult 0
global audit_extfile 0
global get_equityvalue 1

global statelist AK AR AZ CA CO GA IA ID IL MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY

	
if $prepare_minimal == 1{

	u analysis34.minimal.dta
	keep dataid datastate obs is_merger
	rename is_merger merger_min
	save minimal_temp.dta, replace // a lite version of minimal

	collapse (sum) obs merger_min, by(datastate)
	export delimited using /user/user1/yl4180/save/audit_mergers.csv, replace
	save audit/audit_mergers.dta, replace
	
}


if $prepare_state == 1{

	foreach state in $statelist{
	u minimal_temp.dta, clear
	keep if datastate == "`state'"
	gen nonmergers_min = 1 - merger_min
	save audit/`state'.only.dta, replace
	
	}
}

cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/audit

global longstatelist ALASKA ARKANSAS ARIZONA CALIFORNIA COLORADO GEORGIA IOWA IDAHO ILLINOIS MASSACHUSETTS MAINE MICHIGAN MINNESOTA MISSOURI NORTH_CAROLINA NORTH_DAKOTA NEW_JERSEY NEW_MEXICO NEW_YORK OHIO OKLAHOMA OREGON RHODE_ISLAND SOUTH_CAROLINA TENNESSEE TEXAS UTAH VIRGINIA VERMONT WASHINGTON WISCONSIN WYOMING

if $makefile == 1{
set more off
local n: word count $statelist
	forvalues i = 1/`n'{
	local state: word `i' of $statelist
	local longstate: word `i' of $longstatelist
        local longstate= subinstr("`longstate'","_"," ",.)
	u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta, clear
	tostring dataid, replace
	save /NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta,replace
	u `state'.only.dta, clear
	merge 1:m dataid using /NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta, keepus(entityname match_* mfull_name)
	keep if _merge == 3
	drop _merge
	duplicates drop dataid, force
	save `state'.only.dta, replace
	clear
	corp_add_mergers `state' ,dta(`state'.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta)  longstate(`longstate')
	gen merger_old = !missing(mergerdate) 
	gen nonmergers_old = missing(mergerdate)
	rename mergerdate mergerdate_old
	keep dataid datastate merger_min merger_old nonmergers_min nonmergers_old mergerdate_old obs entityname
	duplicates drop dataid, force
	save `state'.mergers.dta, replace
	
	clear
	u `state'.only.dta
	keep dataid datastate merger_min nonmergers_min obs entityname match_* mfull_name
	save `state'.only.dta, replace
	
	clear
	corp_add_mergers `state' ,dta(`state'.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta) longstate(`longstate')
	gen merger_new = !missing(mergerdate)
	gen nonmergers_new = missing(mergerdate)
	rename mergerdate mergerdate_new
	keep dataid merger_new nonmergers_new mergerdate_new entityname 
	duplicates drop dataid, force
	save `state'.mergers_new.dta, replace
	
	clear
	u `state'.only.dta
	keep dataid datastate merger_min nonmergers_min obs entityname match_* mfull_name
	save `state'.only.dta, replace
	
	clear
	corp_add_mergers `state' ,dta(`state'.only.dta) merger(/user/user1/yl4180/save/Z_mergers.dta) longstate(`longstate')
	gen merger_Z = !missing(mergerdate)
	gen nonmergers_Z =missing(mergerdate)
	rename mergerdate mergerdate_Z
	keep dataid merger_Z nonmergers_Z mergerdate_Z entityname
	merge m:m dataid using `state'.mergers_new.dta
	drop _merge
	merge m:m dataid using `state'.mergers.dta
	drop _merge
	duplicates drop dataid, force
	save `state'.mergers_all.dta, replace
	}
}

if $makeresult == 1{
clear
global statelist AK AR AZ CA CO FL GA IA ID IL KY MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
gen a = .
	foreach state in $statelist{
		append using `state'.mergers_all.dta
	save allstates.mergers.dta, replace
	}
drop a
save allstates.mergers.dta, replace

collapse (sum) merger_min merger_old merger_new merger_Z n* obs, by(datastate)
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
	duplicates drop targetname, force
	collapse (sum) obs, by(targetstate) 
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
	duplicates drop targetname, force
	collapse (sum) obs, by(targetstate) 
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
	duplicates drop targetname, force
	collapse (sum) obs, by(targetstate) 
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
	
	collapse (sum) obs* merger*
	drop obs
	gen ratio_old = 1 - merger_old / obs_old
	gen ratio_new = 1 - merger_new / obs_new
	gen ratio_Z = 1- merger_Z /obs_Z
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
	order datastate merger_min merger_old merger_new merger_Z ratio_old ratio_new ratio_Z unmatched_old unmatched_new unmatched_Z obs nonmergers_min nonmergers_old nonmergers_new nonmergers_Z
	gsort -merger_min
	rename ratio_* misspct_*
	save ext_all.dta, replace
	export delimited using /user/user1/yl4180/save/ext_all.csv, replace
	
}

if $get_equityvalue == 1{
cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/audit
	global statelist AK AR AZ CA CO FL GA IA ID IL KY MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
	global longstatelist ALASKA ARKANSAS ARIZONA CALIFORNIA COLORADO FLORIDA GEORGIA IOWA IDAHO ILLINOIS KENTUCKY MASSACHUSETTS MAINE MICHIGAN MINNESOTA MISSOURI NORTH_CAROLINA NORTH_DAKOTA NEW_JERSEY NEW_MEXICO NEW_YORK OHIO OKLAHOMA OREGON RHODE_ISLAND SOUTH_CAROLINA TENNESSEE TEXAS UTAH VIRGINIA VERMONT WASHINGTON WISCONSIN WYOMING

	local n: word count $statelist
	forvalues i = 1/`n'{
		local state: word `i' of $statelist
		local longstate: word `i' of $longstatelist
		local longstate= subinstr("`longstate'","_"," ",.)
		u `state'.mergers_all.dta, clear
		keep dataid entityname datastate merger_* mergerdate_* nonmergers_* obs
		keep if merger_old == 1 | merger_new == 1 | merger_Z == 1
		tomname entityname
		save `state'.mergers_all.dta, replace
		corp_add_mergers `state' ,dta(`state'.mergers_all.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta)  longstate(`longstate')
		rename equityvalue avalue_old
		keep dataid entityname datastate merger_* mergerdate_* nonmergers_* obs avalue_old
		save  `state'.mergers_all_1.dta, replace
		drop avalue_old
		duplicates drop dataid, force
		tomname entityname
		save `state'.mergers_all.dta, replace
		corp_add_mergers `state' ,dta(`state'.mergers_all.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta) longstate(`longstate')
		rename equityvalue avalue_new
		keep dataid entityname datastate merger_* mergerdate_* nonmergers_* obs avalue_new
		save  `state'.mergers_all_2.dta, replace
		drop avalue_new
		duplicates drop dataid, force
		tomname entityname
		save `state'.mergers_all.dta, replace
		corp_add_mergers `state' ,dta(`state'.mergers_all.dta) merger(/user/user1/yl4180/save/Z_mergers.dta) longstate(`longstate')
		rename equityvalue avalue_Z
		keep dataid entityname datastate merger_* mergerdate_* nonmergers_* obs avalue_Z
		save  `state'.mergers_all_3.dta, replace
		drop avalue_Z
		duplicates drop dataid, force
		tomname entityname
		save `state'.mergers_all.dta, replace
		
		u `state'.mergers_all_1.dta, clear
		replace avalue_old = "0" if avalue_old == "np"
		replace avalue_old = subinstr(avalue_old, ",","",.)
		destring avalue_old, replace
		collapse (sum) avalue_old, by(datastate)
		save `state'.value_old.dta, replace
		
		u `state'.mergers_all_2.dta, clear
		replace avalue_new = "0" if avalue_new == "np"
		replace avalue_new = subinstr(avalue_new, ",","",.)
		destring avalue_new, replace
		collapse (sum) avalue_new, by(datastate)
		save `state'.value_new.dta, replace
		
		u `state'.mergers_all_3.dta, clear
		replace avalue_Z = "0" if avalue_Z == "n.a."
		replace avalue_Z = subinstr(avalue_Z, ",","",.)
		destring avalue_Z, replace
		collapse (sum) avalue_Z, by(datastate)
		replace avalue_Z = avalue_Z / (0.784 * 1000)
		save `state'.value_Z.dta, replace
		
		u `state'.value_old.dta, clear
		merge 1:1 datastate using `state'.value_new.dta
		drop _merge
		merge 1:1 datastate using `state'.value_Z.dta
		drop _merge
		save `state'.value.dta, replace	
	}
		clear
		gen a = .
		foreach state in $statelist{
			append using `state'.value.dta
			save allstates.value.dta, replace
			}
	drop a
	save allstates.value.dta, replace
	u ext_all.dta, clear
	merge 1:1 datastate using allstates.value.dta
	drop _merge
	gsort -merger_min
	order datastate merger_min merger_old merger_new merger_Z misspct_old misspct_new misspct_Z avalue_old avalue_new avalue_Z unmatched_old unmatched_new unmatched_Z obs nonmergers_min nonmergers_old nonmergers_new nonmergers_Z
	save ext_value.dta, replace
	
	u /NOBACKUP/scratch/share_scp/ext_data/mergers.dta, clear
	drop if missing(targetname)
	gen year = year(dateannounced)
	drop if year > 2013 // edit as needed
	replace targetstate = trim(upper(targetstate))		
	replace equityvalue = "0" if equityvalue == "np"
	replace equityvalue = subinstr(equityvalue, ",","",.)
	destring equityvalue, replace
	collapse (sum) equityvalue, by(targetstate)	
	merge 1:1 targetstate using /user/user1/yl4180/us.dta
	keep if _merge == 3
	drop _merge targetstate 
	rename equityvalue allvalue_old
	save value_old.dta, replace

	u /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta, clear // 1980 - 2018
	drop if missing(targetname)
	gen year = year(dateannounced)
	drop if year < 1990 | year > 2013 // edit as needed
	replace targetstate = trim(upper(targetstate))
	replace equityvalue = "0" if equityvalue == "np"
	replace equityvalue = subinstr(equityvalue, ",","",.)
	destring equityvalue, replace
	collapse (sum) equityvalue, by(targetstate)	
	merge 1:1 targetstate using /user/user1/yl4180/us.dta
	keep if _merge == 3
	drop _merge targetstate 
	rename equityvalue allvalue_new
	save value_new.dta, replace
	
	u /user/user1/yl4180/save/Z_mergers.dta, clear //1996 - 2019
	drop if missing(targetname)
	gen year = year(dateannounced)
	drop if year > 2013 // edit as needed
	replace targetstate = trim(upper(targetstate))
	replace equityvalue = "0" if equityvalue == "n.a."
	replace equityvalue = subinstr(equityvalue, ",","",.)
	destring equityvalue, replace
	collapse (sum) equityvalue, by(targetstate)
	replace equityvalue = equityvalue / (0.784 * 1000)
	merge 1:1 targetstate using /user/user1/yl4180/us.dta
	keep if _merge == 3
	drop _merge targetstate 
	rename equityvalue allvalue_Z
	save value_Z.dta, replace
	
	merge 1:1 state using value_old.dta
	drop _merge
	merge 1:1 state using value_new.dta
	drop _merge
	order state allvalue_old allvalue_new allvalue_Z
	rename state datastate
	save value_all.dta, replace
	
	u ext_value.dta, clear
	merge 1:1 datastate using value_all.dta
	drop _merge
	gsort -merger_min
	
	
}
