cd /projects/reap.proj/reapindex/Iowa
global mergetempsuffix IA

clear
#delim ;
import delimited dataid addressType corpName address1 address2 city state zipcode country 
using /projects/reap.proj/raw_data/Iowa/CrpWAdd.txt, delim(tab)  ;
#delim cr

drop if !missing(v10)
drop if !missing(v13)
drop if !missing(v11)
drop if !missing(v12)
drop v10 v11 v12 v13


save IA.dta,replace

/*
CORP-FILE-NO	9	N
ADDRESS-TYPE (Footnote #1)	1	AN
NAME	50	AN
ADDR-1	50	AN
ADDR-2	50	AN
CITY	50	AN
STATE (Footnote #2)	2	AN
ZIP	9	AN
COUNTRY
*/
clear


import delimited dataid chapterNo delinFlag farmFlag farmDelinFlag deadCode deadDate stateOfIncorp statusCode dateIncorp dateExpired noAcres using /projects/reap.proj/raw_data/Iowa/CrpWFil.txt, delim(tab)

gen is_corp = inlist(chapterNo,"490 DP","490 FP")


merge 1:m dataid using IA.dta
/*
CORP-FILE-NO	9	N
CHAPTER-NO (Footnote #5)	6	AN
DELIN-FLAG (Footnote #6)	1	AN
FARM-FLAG (Footnote #7)	1	AN
FARM-DELIN-FLAG (Footnote #8)	1	AN
DEAD-CODE (Footnote #9)	1	AN
DEAD-DATE (mm-dd-yyyy)	10	AN
STATE-OF-INCORP (Footnote #2)	2	AN
STATUS-CODE (A,D) (Footnote #10)	1	AN
DATE-INCORP (mm-dd-yyyy)	10	AN
DATE-EXPIRED (mm-dd-yyyy)	10	AN
NO-ACRES
*/
drop _merge
save IA.dta, replace

clear
/*Adding Name*/
#delim ;
import delimited dataid nameType name nameModFlag nameFrm statusCode certNo
 using /projects/reap.proj/raw_data/Iowa/CrpWNam.txt, delim(tab);
#delim cr
keep if inlist(nameType,"L","R*")
keep if inlist(statusCode,"A")
merge m:m dataid using IA.dta
drop if _merge == 1
drop _merge

/* Drop Non-profit */
drop if regexm(chapterNo,".*N$")
drop if inlist(chapterNo,"*504*","4980CN","")
/* Drop Foreign Firms */
keep if inlist(country,"USA","")

/* Generating Variables */
gen jurisdiction = stateOfIncorp
replace jurisdiction = "IA" if missing(jurisdiction)

gen is_DE = jurisdiction == "DE"

gen address = address1 + address2

replace state = "IA" if missing(state) | trim(state) == ""
gen stateaddress = state
gen local_firm = inlist(jurisdiction,"IA","DE") & stateaddress == "IA"

gen incdate = date(dateIncorp,"MDY")
gen incyear = year(incdate)

save IA.dta, replace


gen entityname = name 
replace entityname = corpName if missing(entityname)
drop if missing(incdate)
keep dataid entityname incdate incyear  jurisdiction address city state zipcode country  statusCode is_DE stateaddress local_firm is_corp

drop if missing(entityname)
save IA.dta,replace

clear
/* Build Director File */
clear
cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets/

#delim ;
import delimited dataid NAME addr1 ADDR2 CITY STATE ZIP COUNTRY OFFICER_TYPE DIR_FLAG SHHOLDER_FLAG 
using /NOBACKUP/scratch/share_scp/raw_data/Iowa/CrpWOff.txt, delim(tab);
#delim cr

drop if !missing(v12)
drop if !missing(v13)
drop if !missing(v14)
rename NAME fullname
rename OFFICER_TYPE role
// keep if inlist(role,"00","01","02","10","11","43","65") for legislator task
keep dataid fullname role
replace fullname = upper(trim(itrim(subinstr(fullname,"."," ",.))))
split fullname, parse(,)
gen name = fullname2 + " " + fullname3 + " " + fullname1 
replace name = fullname3 + " " + fullname2 + " " + fullname1 if length(trim(itrim(fullname3)))>2
replace fullname = upper(trim(itrim(name)))
/*split name
gen firstname = name1 
replace fullname = name */
keep dataid fullname role 
save IA.directors.dta, replace


**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u IA.dta , replace
	tomname entityname
	save IA.dta, replace

	corp_add_eponymy, dtapath(IA.dta) directorpath(IA.directors.dta)


       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(IA.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(IA.dta)
	
	
	# delimit ;
	corp_add_trademarks IA , 
		dta(IA.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications IA IOWA , 
		dta(IA.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
/* No Observations */	
	corp_add_patent_assignments  IA IOWA , 
		dta(IA.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	# delimit cr	
	
	corp_add_ipos	 IA ,dta(IA.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(IOWA)
	corp_add_mergers IA ,dta(IA.dta) merger(/projects/reap.proj/data/mergers.dta) longstate(IOWA)
	
	
      corp_add_vc        IA ,dta(IA.dta) vc(~/final_datasets/VX.dta) longstate(IOWA)
