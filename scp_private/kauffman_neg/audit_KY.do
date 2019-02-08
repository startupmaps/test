clear
cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/audit
use /NOBACKUP/scratch/share_scp/migration/datafiles/KY.dta,clear

	tostring dataid, replace
	save KY.only.dta, replace
	clear
	corp_add_mergers KY ,dta(KY.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta)  longstate(KENTUCKY)
	gen merger_old = !missing(mergerdate) 
	gen nonmergers_old = missing(mergerdate)
	rename mergerdate mergerdate_old
	keep dataid datastate merger_min merger_old nonmergers_min nonmergers_old mergerdate_old obs entityname
	// duplicates drop dataid, force
	save KY.mergers.dta, replace
	
	clear
	u KY.only.dta
	keep dataid datastate merger_min nonmergers_min obs entityname match_* mfull_name
	save KY.only.dta, replace
	
	corp_add_mergers KY ,dta(KY.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta) longstate(KENTUCKY)
	gen merger_new = !missing(mergerdate)
	gen nonmergers_new = missing(mergerdate)
	rename mergerdate mergerdate_new
	keep dataid merger_new nonmergers_new mergerdate_new entityname 
	// duplicates drop dataid, force
	save KY.mergers_new.dta, replace
	
	clear
	u KY.only.dta
	keep dataid datastate merger_min nonmergers_min obs entityname match_* mfull_name
	save KY.only.dta, replace
	corp_add_mergers KY ,dta(KY.only.dta) merger(/user/user1/yl4180/save/Z_mergers.dta) longstate(KENTUCKY)
	gen merger_Z = !missing(mergerdate)
	gen nonmergers_Z = missing(mergerdate)
	rename mergerdate mergerdate_Z
	keep dataid merger_Z nonmergers_Z mergerdate_Z entityname
	// duplicates drop dataid, force
	merge m:m dataid using KY.mergers_new.dta
	drop _merge
	merge m:m dataid using KY.mergers.dta
	drop _merge
	
	collapse (max) 	merger_min merger_old merger_new merger_Z n* obs , by(dataid)
	gen datastate = "KY"
	save KY.mergers_all.dta, replace

