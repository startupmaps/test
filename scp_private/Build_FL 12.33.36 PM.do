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
replace entityname = trim(itrim(entityname))

gen cor_filing_type = substr(v1, 203,10)
replace cor_filing_type = itrim(trim(cor_filing_type))
replace cor_filing_type = substr(cor_filing_type, 2,5) if substr(cor_filing_type, 1,1) == "A" | substr(cor_filing_type, 1,1) == "I"

gen address1 = substr(v1, 220, 40)
gen address2 = substr(v1, 260, 40)

replace address1 = trim(itrim(upper(address1)))
replace address2 = trim(itrim(upper(address2)))
gen address = trim(itrim(address1 + " " + address2))

*** state ***
gen state = substr(v1, 332, 9)
forvalue i = 0/9{
replace state = subinstr(state, "`i'"," ",.)
}
replace state = subinstr(state, "-"," ",.)
replace state = trim(itrim(upper(state)))
replace state = "FL" if state == "F"

**** city ****
gen city = substr(v1, 300, 30)
forvalue i = 0/9{
replace city = subinstr(city, "`i'"," ",.)
}
replace city = trim(itrim(upper(city)))

*** zipcode ****
gen zipcode = substr(v1, 335, 5)
replace zipcode = substr(v1, 335, 10) if regexm(zipcode, "[A-Z]")
local list ="A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
local n : word count `list'
forvalues i = 1/`n'{
local letter: word `i' of `list'
replace zipcode = subinstr(zipcode, "`letter'"," ",.)
}
replace zipcode = trim(itrim(zipcode))
replace zipcode = substr(zipcode, 1, 5)

**** incdate ****
gen cor_file_date = substr(v1, 473, 16)
local list ="A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
local n : word count `list'
forvalues i = 1/`n'{
local letter: word `i' of `list'
replace cor_file_date = subinstr(cor_file_date, "`letter'"," ",.)
}
replace cor_file_date = trim(itrim(cor_file_date))
replace cor_file_date = substr(cor_file_date, 1, 8)
replace cor_file_date = substr(v1, 474, 16) if year(date(cor_file_date, "MDY")) > 2019
replace cor_file_date = trim(itrim(cor_file_date))
replace cor_file_date = substr(cor_file_date, 1, 8)
gen incdate = date(cor_file_date,"MDY")
gen incyear = year(incdate)

**** jurisdiction ****
gen jurisdiction = substr(v1, 503, 12)
forvalue i = 0/9{
replace jurisdiction = subinstr(jurisdiction, "`i'"," ",.)
}
replace jurisdiction = trim(itrim(upper(jurisdiction)))
replace jurisdiction = "FL" if missing(jurisdiction) | jurisdiction == "N FL"
replace jurisdiction = substr(jurisdiction, 1, 2)

******
gen is_nonprofit = inlist(cor_filing_type,"DOMNP","FORNP")
gen is_corp = inlist(cor_filing_type,"DOMP", "DOMNP","FORP","FORNP")
gen stateaddress = state
gen local_firm = inlist(jurisdiction,"DE","FL") & state == "DE"
drop if incyear > 2019
drop if missing(entityname) | missing(dataid)
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
	
	append using FL.directors.dta, force
	save FL.directors.dta, replace
}

*/
	u FL.dta
	tomname entityname
	drop if missing(dataid)
	save FL.dta,replace

clear
	u FL.dta
	safedrop firstentityname
	gen firstentityname = entityname
	save FL.dta, replace



	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(FL.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(FL.dta)
 

*	corp_add_gender, dta(FL.dta) directors(FL.directors.dta) names(~/ado/names/NATIONAL.TXT)

	corp_add_eponymy, dtapath(FL.dta) directorpath(FL.directors.dta)
	
# delimit ;
	corp_add_trademarks FL , 
		dta(FL.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications FL FLORIDA , 
		dta(FL.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

/* No Observations */	
	corp_add_patent_assignments  FL FLORIDA , 
		dta(FL.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	# delimit cr	
	
	corp_add_ipos	 FL ,dta(FL.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta) longstate(FLORIDA)
	corp_add_mergers FL  ,dta(FL.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers_2018.dta)  longstate(FLORIDA) 
	replace targetsic = trim(targetsic)
	foreach var of varlist equityvalue mergeryear mergerdate{
	rename `var' `var'_new
	}


	corp_add_vc FL ,dta(FL.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(FLORIDA)


clear
u FL.dta
safedrop is_DE
safedrop shortname
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3


 save FL.dta, replace


