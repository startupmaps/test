set more off
cd ~/final_datasets
global mergetempsuffix="NC_Official"

/* Change this to create test samples */
global NC_dta_file NC.dta


**
** STEP 1: Load the data dump from TX Corporations 
**
**

clear
gen blk = ""
save $NC_dta_file  , replace
forvalues y=1988/2015 {

    di "Import Year: `y'"
    clear
     import delimited using ~/projects/reap_proj/raw_data/North_Carolina/`y'.csv , varnames(1) delim(tab)
    tostring sosid, replace
    capture confirm variable v21
    if _rc == 0 {
        drop v21
    }
    append using $NC_dta_file
    save $NC_dta_file , replace
}
rename sosid dataid 

rename corpname entityname
split dateformed
gen incdate = date(dateformed1,"MDY")
gen incyear = year(incdate)
gen is_corp = type == "BUS"
rename prinaddr1  address
replace address = trim(address + " " + prinaddr2)
rename (princity prinstate prinzip) (city state zipcode)
** Very unique to NC where state is complete missing for NC firms.  Usually we do not assign blanks to the state
replace state = "NC" if state == ""
savesome if citizenship == "D" using $NC_dta_file , replace

gen is_foreign = citizenship == "F"
keep if is_foreign
tomname entityname
save NC.foreign.dta,  replace
corp_get_DE_by_name, dta(NC.foreign.dta)

keep if is_DE
append using $NC_dta_file
replace is_DE = 0 if missing(is_DE)
gen stateaddress = state

if "$NC_dta_file" == "NC.DE.dta" {
    keep if is_DE == 1
}

save $NC_dta_file, replace


	corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta($NC_dta_file)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta($NC_dta_file)

	
	# delimit ;
	corp_add_trademarks NC , 
		dta($NC_dta_file) 
		trademarkfile(~/projects/reap_proj/data/trademarks.dta) 
		ownerfile(~/projects/reap_proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications NC NORTH CAROLINA , 
		dta($NC_dta_file) 
		pat(~/projects/reap_proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;
	
	corp_add_patent_assignments  NC NORTH CAROLINA , 
		dta($NC_dta_file)
		pat("~/projects/reap_proj/data_share/patent_assignments.dta" "~/projects/reap_proj/data_share/patent_assignments2.dta"  "~/projects/reap_proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	# delimit cr	
	corp_add_ipos	 NC ,dta($NC_dta_file) ipo(~/projects/reap_proj/data/ipoallUS.dta) longstate(NORTH CAROLINA)
	corp_add_mergers NC ,dta($NC_dta_file) merger(~/projects/reap_proj/data/mergers.dta) longstate(NORTH CAROLINA)
corp_add_vc NC ,dta($NC_dta_file) vc(~/final_datasets/VX.dta) longstate(NORTH CAROLINA)

clear
u $NC_dta_file

gen  shortname = wordcount(entityname) <= 3
save $NC_dta_file, replace

