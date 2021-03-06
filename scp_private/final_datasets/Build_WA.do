
cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets/
global mergetempsuffix="WA_Official"


**
** STEP 1: Load the data dump from MA Corporations 
/** This data uses the director address to locate companies **/
{
    /** Create a file with addresses **/
    clear
    import delimited using /NOBACKUP/scratch/share_scp/raw_data/Washington/2015_05_26/GoverningPersons.txt,delim(tab) bindquote(nobind) varnames(1)

    gen address_ord = 1 if inlist(title,"All Officers","President")
    replace address_ord = 2 if inlist(title,"Manager","Partner")
    replace address_ord = 3 if missing(address_ord)

    gen instances = 1
    replace zip = trim(itrim(zip))
    drop if zip == "" /** Get rid of some empty ones **/
    collapse (sum) instances, by(ubi address city state zip address_ord)
    gsort ubi address_ord -instances
    duplicates drop ubi, force
    keep ubi address city state zip
    destring ubi, replace force
    replace zip = itrim(trim(zip))
    replace zip = substr(zip,1,5)
    drop if ubi == . /** these are only 4, not big deal if dropping **/
    save /NOBACKUP/scratch/share_scp/temp/WA.addresses.dta , replace
    
}    

/*** Import Company File **/
{
    //Import file and basic definitions
    clear
    import delimited using /NOBACKUP/scratch/share_scp/raw_data/Washington/2015_05_26/Corporations.txt,delim(tab) bindquote(nobind) varnames(1)
    keep if inlist(stateofinc,"WA","DE")
    gen incdate = date(dateofinc,"MDY")
    gen incyear = year(date(dateofinc,"MDY"))
    gen deathdate = date(dissolutiondate,"MDY")
    gen deathyear = year(date(dissolutiondate,"MDY"))
    
    gen is_nonprofit= type == "Nonprofit"
    gen is_corp =category == "REG"


    //add addresses
    merge m:1 ubi using /NOBACKUP/scratch/share_scp/temp/WA.addresses.dta
    drop if _merge == 2
    drop _merge
    
    tostring ubi, replace
    rename (businessname ubi) (entityname dataid)
    gen corpnumber = dataid 
    rename (stateofincorporation zip) (jurisdiction zipcode)
    
    keep dataid entityname incdate incyear deathdate deathyear is_corp jurisdiction is_nonprofit address city state zipcode corpnumber

    
    replace state = "WA" if trim(state) == "" & jurisdiction == "WA"

    gen stateaddress = state
    gen local_firm = stateaddress == "WA"
    
    save WA.dta,replace
}


*Build Director file
	
	clear
	import delimited using /NOBACKUP/scratch/share_scp/raw_data/Washington/2013_07_23/GoverningPersonsClean.txt,delim(tab) bindquote(nobind) varnames(1)

	gen fullname = firstname + " " + middlename + " " + lastname
	replace title = "PRESIDENT" if inlist(title,"ALL Officers","Chairman","President")
	replace title = "MANAGER" if inlist(title,"Manager","Partner","Member")
	rename title role
	rename ubi dataid                                        
	replace role = upper(trim(itrim(role)))
	replace fullname =  trim(itrim(fullname))
	replace firstname =  trim(itrim(firstname))
        save WA.diraddress.dta , replace

	keep if inlist(role,"PRESIDENT","MANAGER","CEO")
	keep dataid fullname role firstname
	order dataid fullname role
	save WA.directors.dta,replace


	
**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	clear
	u WA.dta
	tomname entityname
	save WA.dta, replace
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(WA.dta)

	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(WA.dta)

	corp_add_gender, dta(WA.dta) directors(WA.directors.dta) names(~/ado/names/NATIONAL.TXT) precision(1)
	corp_add_eponymy, dtapath(WA.dta) directorpath(WA.directors.dta)
	
	# delimit ;
	corp_add_trademarks WA , 
		dta(WA.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications WA WASHINGTON , 
		dta(WA.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  WA WASHINGTON , 
		dta(WA.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/patent_assignments.dta" "/NOBACKUP/scratch/share_scp/ext_data/patent_assignments2.dta" "/NOBACKUP/scratch/share_scp/ext_data/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
		
		

		
		
	# delimit cr	
	corp_add_ipos	 WA  ,dta(WA.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta) longstate(WASHINGTON)
	corp_add_mergers WA  ,dta(WA.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta) longstate(WASHINGTON)

	corp_add_vc 	 WA  ,dta(WA.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(WASHINGTON)

 
clear
u WA.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
 save WA.dta, replace


