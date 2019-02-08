cd ~/final_datasets/
global mergetempsuffix Build_WI
global WI_dta_file WI.dta


clear 
infile using ~/projects/reap_proj/final_datasets/WI.dct 
drop if dataid == ""
drop if strpos(entityname,"CORPORATION NAME") == 1
gen for_llc = strpos(corptype,"Foreign LLC") > 0 | strpos(corptype,"Foreign Limited") > 0
gen foreign = strpos(corptype,"Foreign" ) > 0
gen is_corp = strpos(corptype, "Business") > 0 | strpos(corptype,"Corpora") > 0 | foreign & !for_llc

keep if inlist(jurisdiction, "DE", "WI")

rename incdate incdatestr
gen incdate = date(incdatestr,"MDY")

gen incyear = year(incdate)
gen shortname = wordcount(entityname) <= 3
replace address = upper(address)

savesome if !foreign using $WI_dta_file , replace


keep if foreign
tomname entityname
save WI.foreign.dta,  replace
corp_get_DE_by_name, dta(WI.foreign.dta)

append using $WI_dta_file


if "$WI_dta_file" == "WI.DE.dta" {
    keep if is_DE
}

** Get rid of all the DE firms that are not truly local.. Stop marking them as local
replace state = "" if state == "WI" & is_DE & (strpos(address,"8040 EXCELSIOR") | strpos(address,"8020 EXCELSIOR"))
replace state = "" if regagent == "C T CORPORATION SYSTEM" | regagent == "THE PRENTICE-HALL CORPORATION SYSTEM" | regagent == "CSC-LAWYERS INCORPORATING SERVICE CO"
gen stateaddress = state


save $WI_dta_file, replace








**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	





       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta($WI_dta_file)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta($WI_dta_file)
	
	
	# delimit ;
	corp_add_trademarks WI , 
		dta($WI_dta_file) 
		trademarkfile(~/projects/reap_proj/data/trademarks.dta) 
		ownerfile(~/projects/reap_proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications WI WISCONSIN , 
		dta($WI_dta_file) 
		pat(~/projects/reap_proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  WI WISCONSIN , 
		dta($WI_dta_file)
		pat("~/projects/reap_proj/data_share/patent_assignments.dta" "~/projects/reap_proj/data_share/patent_assignments2.dta"  "~/projects/reap_proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 WI  ,dta($WI_dta_file) ipo(~/projects/reap_proj/data/ipoallUS.dta)  longstate(WISCONSIN)
	corp_add_mergers WI  ,dta($WI_dta_file) merger(~/projects/reap_proj/data/mergers.dta)  longstate(WISCONSIN) 

corp_add_vc WI ,dta($WI_dta_file) vc(~/final_datasets/VX.dta) longstate(WISCONSIN)

clear
u $WI_dta_file

gen  shortname = wordcount(entityname) <= 3
save $WI_dta_file, replace

