clear
cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg

u minimal_temp.dta, clear
gen nomatched_min = 1 - merger_min
keep if datastate == "KY"
save audit/KY.only.dta, replace

	cd audit
	u KY.only.dta, clear 
	merge 1:m dataid using /NOBACKUP/scratch/share_scp/migration/datafiles/KY.dta, keepus(entityname match_* mfull_name)
	keep if _merge == 3
	drop _merge
	duplicates drop dataid, force
	save KY.only.dta, replace
	clear
	corp_add_mergers KY ,dta(KY.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta)  longstate(KENTUCKY)
	gen merger_old = !missing(mergerdate) 
	gen nomatched_old = missing(mergerdate)
	keep dataid datastate merger_min merger_old nomatched_min nomatched_old obs 
	duplicates drop 
	save KY.mergers.dta, replace
	
	clear
	u KY.only.dta
	keep dataid datastate merger_min nomatched_min obs entityname match_* mfull_name
	save KY.only.dta, replace
	
	corp_add_mergers KY ,dta(KY.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta) longstate(KENTUCKY)
	gen merger_new = !missing(mergerdate)
	gen nomatched_new = missing(mergerdate)
	keep dataid merger_new nomatched_new 
	duplicates drop
	save KY.mergers_new.dta, replace
	
	clear
	u KY.only.dta
	keep dataid datastate merger_min nomatched_min obs entityname match_* mfull_name
	save KY.only.dta, replace
	corp_add_mergers KY ,dta(KY.only.dta) merger(/user/user1/yl4180/save/Z_mergers.dta) longstate(KENTUCKY)
	gen merger_Z = !missing(mergerdate)
	gen nomatched_Z = missing(mergerdate)
	keep dataid merger_Z nomatched_Z 
	duplicates drop
	merge m:m dataid using KY.mergers_new.dta
	drop _merge
	merge m:m dataid using KY.mergers.dta
	drop _merge
	duplicates drop dataid, force
	save KY.mergers_all.dta, replace
