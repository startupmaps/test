clear
cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg
set more off
global prepare_state 0
global prepare_minimal 0
global makefile 0
global makeresult 1
global audit_extfile 1
global statelist AK AR AZ CA CO GA IA ID IL MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
// global statelist CA CO FL GA IA ID IL MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
	
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
// global longstatelist CALIFORNIA COLORADO GEORGIA IOWA IDAHO ILLINOIS MASSACHUSETTS MAINE MICHIGAN MINNESOTA MISSOURI NORTH_CAROLINA NORTH_DAKOTA NEW_JERSEY NEW_MEXICO NEW_YORK OHIO OKLAHOMA OREGON RHODE_ISLAND SOUTH_CAROLINA TENNESSEE TEXAS UTAH VIRGINIA VERMONT WASHINGTON WISCONSIN WYOMING

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
	duplicates drop
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
	duplicates drop
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
	duplicates drop
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
	replace targetstate = trim(upper(targetstate))
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
	drop if year < 1990 | year > 2014 // edit as needed
	replace targetstate = trim(upper(targetstate))
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
	drop if year > 2014 // edit as needed
	replace targetstate = trim(upper(targetstate))
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
	gen ratio_old = 1 - merger_old / obs_old
	gen ratio_new = 1 - merger_new / obs_new
	gen ratio_Z = 1- merger_Z /obs_Z
	save audit_collapse.dta, replace
	export delimited using /user/user1/yl4180/save/audit_collapse.csv, replace
	
	u ext_all.dta, clear
	gen unmatched_old = obs_old - merger_old
	gen ratio_old = unmatched_old / obs_old
	gen unmatched_new = obs_new - merger_new
	gen ratio_new = unmatched_new / obs_new
	gen unmatched_Z = obs_Z - merger_Z
	gen ratio_Z = unmatched_Z / obs_Z
	order datastate merger* obs* ratio* unmatched* nonmerger*
	gsort -merger_min
	save ext_all.dta, replace
	export delimited using /user/user1/yl4180/save/ext_all.csv, replace
	
}
