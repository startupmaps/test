\
cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets

global mergetempsuffix WYmerge

clear
import delimited using "/NOBACKUP/scratch/share_scp/raw_data/Wyoming/FILING.csv", delim("|") varnames(1) bindquote(loose)
rename mail_* *

rename (state_of_org postal_code filing_id filing_name)(jurisdiction zipcode dataid entityname)
gen address = itrim(trim(addr1 + " " + addr2  + " " + addr3))


replace jurisdiction = "DE" if jurisdiction == "Delaware"
replace jurisdiction = "WY" if jurisdiction == "" | jurisdiction == "Wyoming"
gen potentiallylocal= inlist(jurisdiction,"DE","WY")
 
gen is_nonprofit = filing_type == "NonProfit Corporation"
gen is_corp = strpos(filing_type, "Corporation") >0
drop if is_nonprofit
gen is_DE = jurisdiction == "DE"
gen incdate = date(filing_date,"MDY")
ge incyear = year(incdate)


gen shortname = wordcount(entityname) <= 3
keep dataid entityname incdate incyear   is_corp  is_nonprofit address city state zipcode is_DE shortname potentiallylocal
gen local_firm = potentiallylocal
gen stateaddress = state
save WY.dta,replace


***** Directors ******
clear
import delimited using "/NOBACKUP/scratch/share_scp/raw_data/Wyoming/PARTY.csv", delim("|") varnames(1) bindquote(loose)
rename source_id dataid
gen fullname = trim(itrim(first_name + " " + middle_name + " " + last_name))
keep if inlist(party_type,"President","Incorporator","Applicant","Organizer","Member","Manager","Member/Manager","General Partner")
gen role = "CEO" 
keep dataid fullname role
save WY.directors.dta,replace


**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u WY.dta, replace
	tomname entityname
	save WY.dta, replace
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(WY.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(WY.dta)

*	corp_add_gender, dta(WY.dta) directors(WY.directors.dta) names(/NOBACKUP/scratch/share_scp/ext_data/names/WY.TXT)


	corp_add_eponymy, dtapath(WY.dta) directorpath(WY.directors.dta)
	
	# delimit ;
	corp_add_trademarks WY , 
		dta(WY.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications WY WYOMING , 
		dta(WY.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  WY WYOMING , 
		dta(WY.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/patent_assignments.dta" "/NOBACKUP/scratch/share_scp/ext_data/patent_assignments2.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
	corp_add_ipos	 WY ,dta(WY.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta) longstate(WYOMING)
	corp_add_mergers WY ,dta(WY.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta)  longstate(WYOMING)




 
      corp_add_vc        WY ,dta(WY.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(WYOMING)
      
  ****** For now ******
  
save /NOBACKUP/scratch/share_scp/migration/datafiles/WY.dta, replace

