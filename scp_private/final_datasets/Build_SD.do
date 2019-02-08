set more off
cd ~/projects/reap_proj/final_datasets
global mergetempsuffix="SD_Official"

/* Change this to create test samples */
global dtasuffix 


**
** STEP 1: Load the data dump from SD Corporations 
** 

clear
infile using SD1.dct, using(~/projects/reap_proj/raw_data/South_Dakota/st02d88.txt)
** drop if filing_number == ""
save SD$dtasuffix.dta, replace



clear
use SD$dtasuffix.dta

keep if state == "SD" | state == ""
gen address = address1
gen incdate = date(startdate,"MDY") 
gen incdateDE = date(jurisdiction,"MDY")
gen incyear = year(incdate)
gen deathdate = date(enddate,"MDY") 
gen deathyear = year(deathdate) 
gen first2 = substr(dataid, 1, 2)
gen is_corp = inlist(first2,"FB","DB")
gen is_nonprofit = inlist(first2,"CH","NS")

drop if is_nonprofit

keep if jurisdiction == "DE" | jurisdiction == "SD"

**rename (name filing_number) (entityname dataid)
gen corpnumber = dataid
keep dataid corpnumber entityname incdate incyear is_corp jurisdiction is_nonprofit address city state zipcode
save SD$dtasuffix.dta,replace
	
	
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
	clear
	u ~/projects/reap_proj/final_datasets/SD.dta
	tomname entityname
	save ~/projects/reap_proj/final_datasets/SD.dta, replace
	corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(~/projects/reap_proj/final_datasets/SD.dta)

	# delimit ;
	corp_add_trademarks SD , 
		dta(~/projects/reap_proj/final_datasets/SD.dta) 
		trademarkfile(/home/agroark/projects/reap_proj/data/trademarks.dta) 
		ownerfile(~/projects/reap_proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications SD SOUTH DAKOTA , 
		dta(~/projects/reap_proj/final_datasets/SD.dta) 
		pat(~/projects/reap_proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  SD SOUTH DAKOTA , 
		dta(~/projects/reap_proj/final_datasets/SD.dta)
		pat("home/agroark/projects/reap_proj/data_share/patent_assignments.dta" "~/projects/reap_proj/data_share/patent_assignments2.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
		
		

		
		
	# delimit cr	
	corp_add_ipos	 SD  ,dta(~/projects/reap_proj/final_datasets/SD.dta) ipo(~/projects/reap_proj/data/ipoallUS.dta) longstate(SOUTH DAKOTA)
	corp_add_mergers SD  ,dta(~/projects/reap_proj/final_datasets/SD.dta) merger(~/projects/reap_proj/data/mergers.dta) longstate(SOUTH DAKOTA)

	corp_add_vc 	 SD  ,dta(~/projects/reap_proj/final_datasets/SD.dta) vc(~/projects/reap_proj/data/VX.dta) longstate(SOUTH DAKOTA)

	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/final_datasets/SD.dta)
 
clear
u ~/projects/reap_proj/final_datasets/SD.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
 save ~/projects/reap_proj/final_datasets/SD.dta, replace
