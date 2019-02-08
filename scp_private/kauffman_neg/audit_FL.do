clear
cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg

u minimal_temp.dta, clear
keep if datastate == "FL"
gen nonmergers_min = 1 - merger_min
save audit/FL.only.dta, replace

	cd audit
	u FL.only.dta, clear 
	duplicates drop dataid, force
	merge 1:m dataid using /NOBACKUP/scratch/share_scp/scp_private/final_datasets/FL.dta, keepus(entityname match_* mfull_name)
	keep if _merge == 3
	drop _merge
	duplicates drop
	save FL.only.dta, replace
	clear
	corp_add_mergers FL ,dta(FL.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta)  longstate(FLORIDA)
	gen merger_old = !missing(mergerdate) 
	gen nonmergers_old = missing(mergerdate)
	rename mergerdate mergerdate_old
	keep dataid datastate merger_min merger_old nonmergers_min nonmergers_old mergerdate_old obs entityname
	duplicates drop dataid, force 
	save FL.mergers.dta, replace
	
	clear
	u FL.only.dta
	keep dataid datastate merger_min nonmergers_min obs entityname match_* mfull_name
	save FL.only.dta, replace
	
	corp_add_mergers FL ,dta(FL.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta) longstate(FLORIDA)
	gen merger_new = !missing(mergerdate)
	gen nonmergers_new = missing(mergerdate)
	rename mergerdate mergerdate_new
	keep dataid merger_new nonmergers_new mergerdate_new entityname 
	duplicates drop dataid, force
	save FL.mergers_new.dta, replace
	
	clear
	u FL.only.dta
	keep dataid datastate merger_min nonmergers_min obs entityname match_* mfull_name
	save FL.only.dta, replace
	
	corp_add_mergers FL ,dta(FL.only.dta) merger(/user/user1/yl4180/save/Z_mergers.dta) longstate(FLORIDA)
	gen merger_Z = !missing(mergerdate)
	gen nonmergers_Z = missing(mergerdate)
	rename mergerdate mergerdate_Z
	keep dataid merger_Z nonmergers_Z mergerdate_Z entityname
	duplicates drop dataid, force
	merge m:m dataid using FL.mergers_new.dta
	drop _merge
	merge m:m dataid using FL.mergers.dta
	drop _merge
	duplicates drop dataid, force
	save FL.mergers_all.dta, replace
