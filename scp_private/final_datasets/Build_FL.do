
cd ~/projects/reap_proj/final_datasets

global mergetempsuffix="migration.FL"

clear
gen cor_name = ""
save FL.dta, replace
forvalues doci=0/10 {
	di "*** loading file cordata`doci' ***"
	clear
	infile using ~/scripts/dct/FL.dct, using(/projects/reap.proj/raw_data/Florida/cordata`doci'.txt)
		
	append using ~/migration/datafiles/FL.dta
	save FL.dta, replace
}


clear

use ~/migration/datafiles/FL.dta

gen incdate = date(cor_file_date,"MDY")
gen incyear = year(incdate)

replace state_country = "FL" if state_country == ""
gen is_nonprofit = inlist(cor_filing_type,"DOMNP","FORNP")

gen is_corp = inlist(cor_filing_type,"DOMP", "DOMNP","FORP","FORNP")
gen address = trim(itrim(cor_mail_add_1 +" " +  cor_mail_add_2))
rename (state_country cor_number cor_mail_city cor_mail_state cor_mail_zip cor_name) (jurisdiction dataid city state zipcode entityname)
gen stateaddress = state

gen local_firm = inlist(jurisdiction,"DE","FL") & state == "DE"

keep dataid entityname incdate incyear   is_corp jurisdiction is_nonprofit address city state zipcode local_firm stateaddress
save FL.dta,replace



clear
gen fullname = ""
save FL.directors.dta, replace

forvalues i=1/5{
	use  /projects/reap.proj/data_share/registries/Florida.dta

	keep cor_number  prin`i'*
	rename prin`i'_* *
	replace princ_name = subinstr(subinstr(subinstr(subinstr(princ_name,",","",.),".","",.),"-","",.),"'","",.)
	replace princ_name = upper(trim(itrim(princ_name)))
	replace princ_name = regexr(princ_name,"[^A-Z ]","")
	
	*princ_name_type == "P" if this is a person, C if a corporation
	drop if length(princ_name) < 4  | princ_state != "FL" 
	
	gen role = "PRESIDENT" if strpos(princ_title,"P")
	replace role = "PRESIDENT" if strpos(princ_title,"C")
	drop if missing(role)
	rename (cor_number princ_name) (dataid fullname)
	keep dataid fullname role
	split fullname, limit(2)
	rename (fullname1 fullname2) (firstname lastname)
	
	append using ~/migration/datafiles/FL.directors.dta, force
	save FL.directors.dta, replace
}


	u FL.dta
	tomname entityname
	drop if missing(dataid)
	save FL.dta,replace

clear
	u FL.dta
	safedrop firstentityname
	gen firstentityname = entityname
	save FL.dta, replace



	corp_add_industry_dummies , ind(~/nbercriw/industry_words.dta) dta(~/migration/datafiles/FL.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/migration/datafiles/FL.dta)
 

*	corp_add_gender, dta(~/migration/datafiles/FL.dta) directors(~/migration/datafiles/FL.directors.dta) names(~/ado/names/NATIONAL.TXT)

	corp_add_eponymy, dtapath(FL.dta) directorpath(FL.directors.dta)
	
	# delimit ;
	corp_add_trademarks FL , 
		dta(FL.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		classificationfile(/projects/reap.proj/data/trademarks/classification.dta)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications FL FLORIDA , 
		dta(FL.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	# delimit ;
	
	set trace on;
	set tracedepth 1;
	corp_add_patent_assignments  FL FLORIDA 
		, 
		dta(FL.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta" )
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
		

	# delimit cr	


	corp_add_ipos	 FL  ,dta(~/migration/datafiles/FL.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(FLORIDA) 
	corp_add_mergers FL  ,dta(~/migration/datafiles/FL.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(FLORIDA) 


 

clear
u ~/migration/datafiles/FL.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3


 save FL.dta, replace


