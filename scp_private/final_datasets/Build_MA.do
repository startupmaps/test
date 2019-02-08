
cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets
global mergetempsuffix="MA_Official"


global dtasuffix


/*
**
** STEP 1: Load the data dump from MA Corporations 
*/
	clear
	import delimited using "/NOBACKUP/scratch/share_scp/raw_data/Massachusetts/2015_June/CorpData.txt", delim(",") varnames(1) 

	gen incdate = date(dateoforganization,"MDY") 
	gen incyear = year(incdate)
	gen is_corp = regexm(entitytypedescriptor,"Corporation")
	gen incdateDE = date(jurisdictiondate,"MDY")
        gen stateaddress = state

	* Drop a few bad items (12 in dataid and 75 in incyear of 900K)
	drop if length(dataid) != 6
	drop if missing(incyear)

        replace jurisdictionstate = "MA" if jurisdictionstate == ""
	gen local_firm =  inlist(jurisdictionstate,"MA","DE")
	gen address = addr1 + " " + addr2

	rename (jurisdictionstate postalcode) (jurisdiction zipcode)

	gen is_nonprofit = regexm(entitytypedescriptor, "Nonprofit")
	replace is_nonprofit = 1 if regexm(entitytypedescriptor, "Religious")


	rename fein corpnumber
	keep dataid entityname incdate incyear corpnumber is_llc   jurisdiction is_corp is_nonprofit address city state zipcode  incdateDE stateaddress local_firm
	
	save MA$dtasuffix.dta,replace


* Create files for name changes
* We could add mergers here but then that could definitely make a mess of having the outcome as inputs
*
	clear
	import delimited using "/projects/reap.proj/raw_data/Massachusetts/2015_June/CorpNameChange.txt",delim(",") varnames(1)
	drop if length(dataid) != 6

	rename (oldentityname namechangedate) (oldname namechangeddatestr)
	gen namechangeddate = date(substr(trim(namechangeddatestr),1,10),"YMD")
	keep if !missing(namechangeddate)
	keep dataid oldname namechangeddate
	save MA.names.dta,replace
	
	
	
	
	
**
**
**


*Build Director file
	clear
	import delimited using "/projects/reap.proj/raw_data/Massachusetts/2015_June/CorpIndividualExport.txt",delim(",") varnames(1)
        save MA.diraddress.dta , replace
        gen fullname = firstname + " " + middlename + " " + lastname
	replace fullname = trim(itrim(regexr(fullname," +"," ")))
	rename individualtitle role
	replace role = upper(trim(itrim(role)))
	keep if inlist(role,"PRESIDENT","MANAGER","CEO")
	keep dataid fullname role firstname
	order dataid fullname role
	save MA.directors.dta,replace

 
	
**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	corp_add_names, dta(~/migration/datafiles/MA$dtasuffix.dta) names(~/migration/datafiles/MA.names.dta) nosave
	tomname entityname
	save MA$dtasuffix.dta, replace
	corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(~/migration/datafiles/MA$dtasuffix.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/migration/datafiles/MA$dtasuffix.dta)



***     This part has an error right now
***	corp_add_gender, dta(~/migration/datafiles/MA$dtasuffix.dta) directors(~/migration/datafiles/MA.directors.dta) names(~/ado/names/MA.TXT)


	corp_add_eponymy, dtapath(~/migration/datafiles/MA$dtasuffix.dta) directorpath(~/migration/datafiles/MA.directors.dta)
	
	# delimit ;
	corp_add_trademarks MA , 
		dta(~/migration/datafiles/MA$dtasuffix.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		class(/projects/reap.proj/data/trademarks/classification.dta)
		statefileexists;
	
*/	
	# delimit ;
	corp_add_patent_applications MA MASSACHUSETTS , 
		dta(~/migration/datafiles/MA$dtasuffix.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  MA MASSACHUSETTS , 
		dta(~/migration/datafiles/MA$dtasuffix.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
*	corp_add_ipos	 MA MASSACHUSETTS ,dta(~/migration/datafiles/MA$dtasuffix.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)
*	corp_add_mergers MA MASSACHUSETTS ,dta(~/migration/datafiles/MA$dtasuffix.dta) merger(/projects/reap.proj/data/mergers.dta)
	

*	corp_add_vc2  MA  ,dta(~/migration/datafiles/MA$dtasuffix.dta) vc(~/migration/datafiles/VC.investors.withequity.dta)  longstate(MASSACHUSETTS) dropexisting 


/*
corp_add_ipos MA ,dta(~/migration/datafiles/MA$dtasuffix.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(MASSACHUSETTS)
corp_add_mergers MA  ,dta(~/migration/datafiles/MA$dtasuffix.dta) merger(/projects/reap.proj/data/mergers.dta) longstate(MASSACHUSETTS)
corp_add_vc2  MA  ,dta(~/migration/datafiles/MA$dtasuffix.dta) vc(~/migration/datafiles/VC.investors.withequity.dta)  longstate(MASSACHUSETTS) dropexisting 
*/

	
	corp_has_last_name
				

clear
u ~/migration/datafiles/MA$dtasuffix.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
 save MA$dtasuffix.dta, replace
