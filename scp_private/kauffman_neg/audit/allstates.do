clear
cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/audit
global statelist AK AR AZ CA CO FL GA IA ID IL KY MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
global longstatelist ALASKA ARKANSAS ARIZONA CALIFORNIA COLORADO FLORIDA GEORGIA IOWA IDAHO ILLINOIS KENTUCKY MASSACHUSETTS MAINE MICHIGAN MINNESOTA MISSOURI NORTH_CAROLINA NORTH_DAKOTA NEW_JERSEY NEW_MEXICO NEW_YORK OHIO OKLAHOMA OREGON RHODE_ISLAND SOUTH_CAROLINA TENNESSEE TEXAS UTAH VIRGINIA VERMONT WASHINGTON WISCONSIN WYOMING

set more off

use  /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta , clear
keep if year(dateannounced)  <= 2014
destring equityvalue, replace force
drop if strpos( upper(targetname), "UNDISCLOSE")
drop if strpos( upper(targetname), "CERTAIN ASSET")
drop if strpos( upper(targetname), "CERT ASSET")
drop if strpos( upper(targetname), "CERTAIN AST")
drop if regexm( upper(targetname), "\-AST(S)*$")
drop if regexm( upper(targetname), "\-PPTY$")
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate)
tomname targetname , commasplit parendrop
save /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.pre2014.dta , replace


use  /user/user1/yl4180/save/Z_mergers.dta , clear
keep if year(dateannounced)  <= 2014
replace dealvalue = subinstr(dealvalue,",","",.)
replace dealvalue = subinstr(dealvalue,"*","",.)
destring dealvalue, replace force
rename equityvalue __equityvalue 
rename dealvalue equityvalue
drop if strpos( upper(targetname), "UNDISCLOSE")
drop if strpos( upper(targetname), "CERTAIN ASSET")
drop if strpos( upper(targetname), "CERT ASSET")
drop if strpos( upper(targetname), "CERTAIN AST")
drop if regexm( upper(targetname), "\-AST(S)*$")
drop if regexm( upper(targetname), "\-PPTY$")
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate)
tomname targetname , commasplit parendrop
save /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.pre2014.dta , replace





postfile stats str20 state str20 dataset share eshare share_equity cnt_all cnt_w_equity using allstates.dta, replace every(1)


local n: word count $statelist
forvalues i = 1/`n'{
	local state: word `i' of $statelist
	local longstate: word `i' of $longstatelist
	local longstate= subinstr("`longstate'","_"," ",.)
	
	u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta	
	tostring dataid , replace 
	rename state datastate 
	gen obs = 1
	capture drop match_* mfull_name
	tomname entityname
	keep if incyear <= 2014
	safedrop mergerdate mergeryear targetname equityvalue
	save `state'.only.dta, replace
	save `state'.only.orig.dta, replace

	use `state'.only.orig.dta, replace
	save `state'.only.dta, replace

	corp_add_mergers `state' ,dta(`state'.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.pre2014.dta) storenomatched(`state'.nomatch_new.dta) longstate(`longstate') 

	u `state'.only.dta , replace
	keep if mergerdate != .
	append using `state'.nomatch_new.dta
	gen is_match = dataid != ""
	collapse (max) equityvalue, by(targetname is_match)
	qui: sum equityvalue , detail 
	local tot `r(sum)'
	qui: sum equityvalue if is_match == 1
	local matched `r(sum)'
	local count_all `r(N)'
	local share = round(`matched'/`tot',.001)
	qui: sum is_match
	local share_matched = round(`r(mean)',.001)

	qui: sum is_match if equityvalue !=.
	local eshare_matched = round(`r(mean)',.001)
	local count_w_equity `r(N)'
	
	di "share matched: `share_matched'"
	di "share matched with equity: `eshare_matched'"
	di "share of equity covered: `share'"

	post stats ("`state'") ("new_thompson") (`share_matched') (`eshare_matched') (`share') (`count_all') (`count_w_equity')
	
	
	
	
	use `state'.only.orig.dta, replace
	save `state'.only.dta, replace

	corp_add_mergers `state' ,dta(`state'.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.pre2014.dta) storenomatched(`state'.nomatch_new.dta) longstate(`longstate') 

	u `state'.only.dta , replace
	keep if mergerdate != .
	append using `state'.nomatch_new.dta
	gen is_match = dataid != ""
	collapse (max) equityvalue, by(targetname is_match)
	qui: sum equityvalue , detail 
	local tot `r(sum)'
	qui: sum equityvalue if is_match == 1
	local matched `r(sum)'
	local count_all `r(N)'
	local share = round(`matched'/`tot',.001)
	qui: sum is_match
	local share_matched = round(`r(mean)',.001)

	qui: sum is_match if equityvalue !=.
	local eshare_matched = round(`r(mean)',.001)
	local count_w_equity `r(N)'
	
	di "share matched: `share_matched'"
	di "share matched with equity: `eshare_matched'"
	di "share of equity covered: `share'"

	post stats ("`state'") ("new_zillow") (`share_matched') (`eshare_matched') (`share') (`count_all') (`count_w_equity')
	clear
	
}

  postclose stats 
 
u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/audit/allstates.dta, clear
sort state share
export delimited /user/user1/yl4180/allstates.csv, replace


/*
sort share_equity 
gen axis = _n
labmask  axis, values(state)
graph bar (asis) share_equity , over(axis, label(angle(90))) yline(.5, lpattern(dash))

