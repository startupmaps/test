cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets
clear
global mergetempsuffix = "_"
global statelist AK AR AZ CA CO FL GA IA ID IL KY LA MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
global longstatelist ALASKA ARKANSAS ARIZONA CALIFORNIA COLORADO FLORIDA GEORGIA IOWA IDAHO ILLINOIS KENTUCKY LOUISIANA MASSACHUSETTS MAINE MICHIGAN MINNESOTA MISSOURI NORTH_CAROLINA NORTH_DAKOTA NEW_JERSEY NEW_MEXICO NEW_YORK OHIO OKLAHOMA OREGON RHODE_ISLAND SOUTH_CAROLINA TENNESSEE TEXAS UTAH VIRGINIA VERMONT WASHINGTON WISCONSIN WYOMING
global prepare_mergerfile 1
global prepare_states 1
global append_states 1
global make_minimal 1
global yuting 1

set more off
if $prepare_mergerfile == 1{
use  /NOBACKUP/scratch/share_scp/ext_data/mergers.dta , clear
keep if year(dateannounced)  <= 2014
destring equityvalue, replace force
drop if strpos( upper(targetname), "UNDISCLOSE")
drop if strpos( upper(targetname), "CERTAIN ASSET")
drop if strpos( upper(targetname), "CERT ASSET")
drop if strpos( upper(targetname), "CERTAIN AST")
drop if regexm( upper(targetname), "\-AST(S)*$")
drop if regexm( upper(targetname), "\-PPTY$")
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate targetsic)
tomname targetname , commasplit parendrop
save /NOBACKUP/scratch/share_scp/ext_data/mergers.pre2014.dta , replace


use  /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta , clear
rename targetprimarysiccode targetsic
keep if year(dateannounced)  <= 2014
destring equityvalue, replace force
drop if strpos( upper(targetname), "UNDISCLOSE")
drop if strpos( upper(targetname), "CERTAIN ASSET")
drop if strpos( upper(targetname), "CERT ASSET")
drop if strpos( upper(targetname), "CERTAIN AST")
drop if regexm( upper(targetname), "\-AST(S)*$")
drop if regexm( upper(targetname), "\-PPTY$")
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate targetsic)
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
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate targetsic)
tomname targetname , commasplit parendrop
save /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.pre2014.dta , replace
}

if $prepare_states == 1{

local n: word count $statelist
forvalues i = 1/`n'{
	local state: word `i' of $statelist
	local longstate: word `i' of $longstatelist
	local longstate= subinstr("`longstate'","_"," ",.)
	
	u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta, clear
	
	safedrop dateannounced* targetname enterprisevalue equityvalue equityvalue_old equityvalue_new equityvalue_Z x mergeryear mergeryear_old mergeryear_new mergeryear_Z mergerdate mergerdate_old mergerdate_new mergerdate_Z ipo growthz_old growthz_new growthz_Z acq acq_old acq_new acq_Z
	safedrop patent_assignment patent_application trademark 
	save `state'.dta,replace
		
		# delimit ;
	corp_add_trademarks `state' , 
		dta(`state'.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications `state' `longstate' , 
		dta(`state'.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	corp_add_patent_assignments `state' `longstate' , 
		dta(`state'.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr
	gen ipo = !missing(ipodate) & inrange(ipodate-incdate,0,365*6)
	
	save `state'.dta, replace
	save `state'.origin.dta, replace
	
	corp_add_mergers `state' ,dta(`state'.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.pre2014.dta) longstate(`longstate')
	replace targetsic = trim(targetsic)
	// gen acq = !missing(mergerdate) & inrange(mergerdate-incdate,0,365*6) & substr(targetsic, 1,1) != "6" & !missing(targetsic)
	// gen growthz  = ipo | acq
	
	foreach var of varlist equityvalue mergeryear mergerdate{
	rename `var' `var'_old
	}
	save `state'.dta, replace
	
	corp_add_mergers `state' ,dta(`state'.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.pre2014.dta) longstate(`longstate') 
	replace targetsic = trim(targetsic)
	// gen acq = !missing(mergerdate) & inrange(mergerdate-incdate,0,365*6) & substr(targetsic, 1,1) != "6" & !missing(targetsic)
	// gen growthz  = ipo | acq
	
	foreach var of varlist equityvalue mergeryear mergerdate{
	rename `var' `var'_new
	}
	save `state'.dta, replace
	
	corp_add_mergers `state' ,dta(`state'.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.pre2014.dta) longstate(`longstate') 
	replace targetsic = trim(targetsic)
	// gen acq = !missing(mergerdate) & inrange(mergerdate-incdate,0,365*6) & substr(targetsic, 1,1) != "6" & !missing(targetsic)
	// gen growthz  = ipo | acq
	
	foreach var of varlist equityvalue mergeryear mergerdate {
	rename `var' `var'_Z
	}
	save `state'.dta, replace
	

}

	
	 }

if $append_states == 1{
	clear
	local n: word count $statelist
	forvalues i = 1/`n'{
	local state: word `i' of $statelist
	u `state'.dta,clear
	capture confirm variable eponymous
    	if _rc != 0 {
	        gen eponymous = 0
         }
	capture confirm variable local_firm
	if _rc != 0 {
		gen local_firm = is_Local
	}
	save `state'.dta, replace
	corp_collapse_any_state `state' , workingfolder(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/) outputsuffix("new")
	gen datastate = "`state'" 
	save `state'.collapsed.new.dta, replace
	}

	clear
	gen a = .
	local n: word count $statelist
	forvalues i = 1/`n'{
		local state: word `i' of $statelist
		di "Adding state `state'"
		append using `state'.collapsed.new.dta, force
		save allstates.minimal.new.dta, replace
	}
	drop a
	save allstates.minimal.new.dta, replace
	
}

if $make_minimal == 1 {	
	u allstates.minimal.new.dta, clear
	
	encode datastate, gen(statecode)
	// levelsof datastate, local(states) clean
	
	eststo clear
	eststo: logit growthz_old eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond i.statecode if inrange(incyear, 1988,2008), vce(robust) or
	predict quality_old, pr
	
	eststo: logit growthz_new eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond i.statecode if inrange(incyear, 1988,2008), vce(robust) or
	predict quality_new, pr
	
	eststo: logit growthz_Z eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond i.statecode if inrange(incyear, 1988,2008), vce(robust) or
	esttab using "/user/user1/yl4180/save/Quality Model for All_State.csv", pr2 se eform indicate("State FE=*statecode") replace
	predict quality_Z, pr
	
	replace quality_old = 0 if missing(quality_old)
	replace quality_new = 0 if missing(quality_new)
	replace quality_Z = 0 if missing(quality_Z)
	
	corr quality_old quality_new quality_Z
	
	save allstates.minimal_final.dta, replace
	

}

if $yuting == 1{
	do Yu-ting_minimal.do
	}
