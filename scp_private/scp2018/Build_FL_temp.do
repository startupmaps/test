clear

cd /NOBACKUP/scratch/share_scp/raw_data/Florida/2018
// !wget "ftp://ftp.dos.state.fl.us/public/doc/Quarterly/Cor/cordata.zip"
// !unzip cordata.zip

cd /NOBACKUP/scratch/share_scp/scp_private/scp2018
global mergetempsuffix="migration.FL"
clear
/*
gen cor_name = ""
save FL.dta, replace

forvalues doci=0/9 {
	di "*** loading file cordata`doci' ***"
	clear
	import delimited using "/NOBACKUP/scratch/share_scp/raw_data/Florida/2018/cordata`doci'.txt", stringcol(_all) // we need dct file!
		
	// append using FL.dta
	save FL_cor`doci'.dta, replace
}
*/

***** NO dictionary version ******
clear
forvalues doci = 0/9 {
di "*** loading file cordata`doci' ***"
clear
import delimited using "/NOBACKUP/scratch/share_scp/raw_data/Florida/2018/cordata`doci'.txt", stringcol(_all)

forvalues num = 2/27 {
replace v1 = v1 + ", "+ v`num' if !missing(v`num')
drop v`num'
}

gen dataid = substr(v1,1,12)
gen tag = "wrong" if strlen(trim(dataid))<12
gen entityname = substr(v1, 13, 99)
// replace len = strlen(trim(entityname))
// gsort -len +tag
gen cor_filing_type = substr(v1, 206,5)
replace cor_filing_type = itrim(trim(cor_filing_type))
// tab cor_filing_type, sort

gen address1 = substr(v1, 220, 40)
gen address2 = substr(v1, 260, 40)

replace address1 = trim(itrim(upper(address1)))
replace address2 = trim(itrim(upper(address2)))
gen address = trim(itrim(address1 + " " + address2))

replace state = substr(v1, 332, 9)
forvalue i = 0/9{
replace state = subinstr(state, "`i'"," ",.)
}
replace state = subinstr(state, "-"," ",.)
replace state = trim(itrim(upper(state)))

gen city = substr(v1, 300, 30)
replace city = trim(itrim(upper(city)))

gen zipcode = substr(v1, 335, 5)
replace zipcode = trim(itrim(zipcode))

gen cor_file_date = substr(v1, 473, 8)
replace cor_file_date = trim(itrim(cor_file_date))

gen incdate = date(cor_file_date,"MDY")
gen incyear = year(incdate)

gen jurisdiction = substr(v1, 504, 2)
replace jurisdiction = trim(itrim(upper(jurisdiction)))
replace jurisdiction = "FL" if missing(jurisdiction)


// replace state = "FL" if state == ""
gen is_nonprofit = inlist(cor_filing_type,"DOMNP","FORNP")

gen is_corp = inlist(cor_filing_type,"DOMP", "DOMNP","FORP","FORNP")

gen stateaddress = state

gen local_firm = inlist(jurisdiction,"DE","FL") & state == "DE"

keep dataid entityname incdate incyear is_corp jurisdiction is_nonprofit address city state zipcode local_firm stateaddress v1
save FL_`doci'.dta,replace
}

u FL_0.dta, clear
forvalues doci = 1/9{
append using FL_`doci'.dta
save FL.dta, replace
}

/*

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


