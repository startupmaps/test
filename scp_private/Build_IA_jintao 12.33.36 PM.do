cd /projects/reap.proj/reapindex/Iowa

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

drop if addressType != "H"

save IA_raw.dta,replace

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

#delim ;
import delimited dataid chapterNo delinFlag farmFlag farmDelinFlag deadCode deadDate stateOfIncorp statusCode dateIncorp dateExpired noAcres
 using /projects/reap.proj/raw_data/Iowa/CrpWFil.txt, delim(tab);
#delim cr

merge 1:1 dataid using IA_raw.dta
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
save IA_raw.dta, replace

clear
/*Adding Name*/
#delim ;
import delimited dataid nameType name nameModFlag nameFrm statusCode certNo
 using /projects/reap.proj/raw_data/Iowa/CrpWNam.txt, delim(tab);
#delim cr
keep if inlist(nameType,"L","R","RG")


duplicates tag dataid,generate(dup)
drop if dup == 1 & statusCode == "A"
duplicates drop dataid, force
merge 1:1 dataid using IA_raw.dta

drop _merge

/* Drop Non-profit */
drop if regexm(chapterNo,"504")
drop if inlist(chapterNo,"4980CN","")

/* Generating Variables */
gen jurisdiction = stateOfIncorp
replace jurisdiction = "IA" if missing(jurisdiction)

gen is_DE = jurisdiction == "DE"

gen address = address1 + address2

replace state = "IA" if missing(state) | trim(state) == ""

drop if !inlist(jurisdiction,"IA","DE") 


gen incdate = date(dateIncorp,"MDY")
gen incyear = year(incdate)
gen is_corp = inlist(chapterNo,"490 DP","490 FP")

save IA_raw.dta, replace


gen entityname = name 
replace entityname = corpName if missing(entityname)
drop if missing(incdate)
gen shortname = wordcount(entityname) < 4
keep dataid entityname incdate incyear jurisdiction address city state zipcode country statusCode is_DE is_corp shortname

drop if missing(entityname)

drop if is_DE & state != "IA"
save IA_raw.dta,replace

clear
/* Build Director File */
#delim ;
import delimited dataid NAME addr1 ADDR2 CITY STATE ZIP COUNTRY OFFICER_TYPE DIR_FLAG SHHOLDER_FLAG 
using /projects/reap.proj/raw_data/Iowa/CrpWOff.txt, delim(tab);
#delim cr

drop if !missing(v12)
drop if !missing(v13)
drop if !missing(v14)
rename NAME fullname
rename OFFICER_TYPE role
keep if inlist(role,"00","01","02","10","11","43","65")
duplicates tag dataid, generate(dup)
drop if dup ==1 & DIR_FLAG == "N"
duplicates drop dataid, force
keep dataid fullname role
/*split fullname, parse(,)

gen name = fullname2 + fullname3 + fullname1 

replace name = fullname3 + fullname2 + fullname1 if length(fullname3)>2
split name
gen firstname = name1 
replace fullname = name */
 
save IA_directors.dta, replace


**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u IA_raw.dta , replace
	tomname entityname
	save IA_raw.dta, replace

	corp_add_eponymy, dtapath(IA_raw.dta) directorpath(IA_directors.dta)


       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(IA_raw.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(IA_raw.dta)
	
	
	# delimit ;
	corp_add_trademarks IA , 
		dta(IA_raw.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications IA IOWA , 
		dta(IA_raw.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
/* No Observations */	
	corp_add_patent_assignments  IA IOWA , 
		dta(IA_raw.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment);
	# delimit cr	
	
	corp_add_ipos	 IA ,dta(IA_raw.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(IOWA)
	corp_add_mergers IA ,dta(IA_raw.dta) merger(/projects/reap.proj/data/mergers.dta) longstate(IOWA)
	
	
