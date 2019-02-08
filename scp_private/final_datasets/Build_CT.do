cd ~/projects/reap_proj/final_datasets/

global mergetempsuffix CTmege
global DE_only 0
global CT_dta_file CT.dta

clear


#delimit ;

local files ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/BUSMAS1A/DATA.txt
            ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/BUSMAS1B/DATA.txt
            ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/BUSMAS2A/DATA.txt
            ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/BUSMAS2B/DATA.txt
            ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/BUSMAS3A/DATA.txt
            ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/BUSMAS3B/DATA.txt
            ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/BUSMAS4A/DATA.txt
            ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/BUSMAS4B/DATA.txt
            ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/BUSMAST4/DATA.txt
;
#delimit cr


clear
gen dataid = ""
save $CT_dta_file, replace
foreach f in `files' {
    di "loading file `f'"
    clear
    infile using ~/projects/reap_proj/final_datasets/CT.dct , using(`f')

    /**See data dictionary document **/
    keep if record_type == "01"
    
    append using $CT_dta_file
    save $CT_dta_file, replace

}

gen is_corp = corp_type == "C"
gen is_llc = corp_type == "G"
gen incdate = date(incdatestr,"YMD")
gen incyear = year(incdate)
tomname entityname
replace address1 = "" if trim(address1) == "."
gen address = trim(itrim(address2 + "  " + address1))

save $CT_dta_file, replace

corp_get_DE_by_name , dta($CT_dta_file)

if $DE_only == 1 {
    keep if is_DE == 1
}

gen stateaddress = state

save $CT_dta_file, replace



/* Build Director File */

/*
clear

import delimited data using ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/PRNCIPL1/DATA.txt
save CT.directors.dta,replace

clear
import delimited data using ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/PRNCIPL2/DATA.txt
2/8/18Bayseian models and merge m:m data using CT.directors.dta
drop _merge
save CT.directors.dta,replace

clear
import delimited data using ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/PRNCIPL3/DATA.txt
merge m:m data using CT.directors.dta
drop _merge
save CT.directors.dta,replace


clear
import delimited data using ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/PRNCIPL4/DATA.txt
merge m:m data using CT.directors.dta
drop _merge
save CT.directors.dta,replace


clear
import delimited data using ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/PRNCIPL5/DATA.txt
merge m:m data using CT.directors.dta
drop _merge
save CT.directors.dta,replace


clear
import delimited data using ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/PRNCIPL6/DATA.txt

replace data = data+" "+v2+" "+v3+" "+v4+" "+v5+" "+v6+" "+v7+" "+v8
drop v2 v3 v4 v5 v6 v7 v8 v9 v10 v11
merge m:m data using CT.directors.dta
drop _merge
save CT.directors.dta,replace


clear
import delimited data using ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/PRNCIPL7/DATA.txt
replace data = data+" "+v2+" "+v3+" "+v4+" "+v5+" "+v6+" "+v7+" "+v8
drop v2 v3 v4 v5 v6 v7 v8
merge m:m data using CT.directors.dta
drop _merge
save CT.directors.dta,replace


clear
import delimited data using ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/PRNCIPL8/DATA.txt
merge m:m data using CT.directors.dta
drop _merge
save CT.directors.dta,replace

clear
import delimited data using ~/projects/reap_proj/raw_data/Connecticut/SSP/FOCUSA/PRNCIPL9/DATA.txt
merge m:m data using CT.directors.dta
drop _merge
save CT.directors.dta,replace


gen ind = substr(data,1,2)
gen dataid = substr(data,3,7)
gen fullname = substr(data,14,40)
gen role = substr(data,54,40)
replace role = trim(role)
keep if inlist(role,"PRESIDENT","PRES.")
duplicates drop, force
keep dataid fullname role 
save CT.directors.dta, replace
*/

**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	


   /*corp_add_eponymy, dtapath($CT_dta_file) directorpath(CT.directors.dta) */


       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta($CT_dta_file)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta($CT_dta_file)
	
	
	# delimit ;
	corp_add_trademarks CT , 
		dta($CT_dta_file) 
		trademarkfile(~/projects/reap_proj/data/trademarks.dta) 
		ownerfile(~/projects/reap_proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications CT CONNECTICUT , 
		dta($CT_dta_file) 
		pat(~/projects/reap_proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
/* No Observations */	
	corp_add_patent_assignments  CT CONNECTICUT , 
		dta($CT_dta_file)
		pat("~/projects/reap_proj/data_share/patent_assignments.dta" "~/projects/reap_proj/data_share/patent_assignments2.dta"  "~/projects/reap_proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment);
	# delimit cr	


	corp_add_ipos	 CT  ,dta($CT_dta_file) ipo(~/projects/reap_proj/data/ipoallUS.dta)  longstate(CONNECTICUT) 
	corp_add_mergers CT  ,dta($CT_dta_file) merger(~/projects/reap_proj/data/mergers.dta)  longstate(CONNECTICUT) 

corp_add_vc CT ,dta($CT_dta_file) vc(~/final_datasets/VX.dta) longstate(CONNECTICUT)





clear
u $CT_dta_file
gen  shortname = wordcount(entityname) <= 3
save $CT_dta_file, replace





