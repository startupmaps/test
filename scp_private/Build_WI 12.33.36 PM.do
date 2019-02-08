cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets/

global mergetempsuffix Build_WI
global WI_dta_file WI.dta


clear 
import delimited using "/NOBACKUP/scratch/share_scp/raw_data/Wisconsin/20160523220000COMFicheX.txt"
tostring v8,replace
replace v1 = v1 + v2 +v3+v4+v5+v6+v7+v8
drop if strpos(v1, " PAGE ") & strpos(v1, "DATE ")
drop if strpos(v1, "PAID DATE INCORP") | strpos(v1, "AND DATE.")
gen end = _n if strpos(v1, " TYPE 01 ")>0 
sum end
drop if _n>=r(max)
gen num = _n
gen line = regexm(v1, "[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]")
replace line = 2 if line[_n-1] ==1
replace line = 3 if line == 0 
save WIstart.dta, replace
keep if line == 1
gen three = _n
save WInow.dta,replace
merge 1:1 num using WIstart.dta
drop _merge
sort num
replace three = three[_n-2] if line == 3
save WInow.dta, replace
 
forvalues n=1/3{
savesome if line == `n' using WI_`n'.dta
}
forvalues n=1/3{
u WI_`n'.dta,clear
rename v1 var`n'
safedrop id
gen id = _n
save WI_`n'.dta, replace
}
u WI_1.dta,clear 
merge 1:1 id using WI_2.dta
drop _merge
merge 1:1 three using WI_3.dta
drop _merge 
save WInow.dta, replace

keep var1 var2 var3
gen entityname = trim(itrim(upper(substr(var1, 1, 67))))
gen dataid = trim(itrim(upper(substr(var1, 68, 13))))
gen corptype = substr(var1,77,27)
forval n = 0/9{
    replace corptype = subinstr(corptype, "`n'", "",.)
}
replace corptype = subinstr(corptype, "/","",.)
replace corptype = trim(itrim(corptype))
gen jurisdiction = substr(corptype, 9,2) if strpos(corptype, "$")
gen incdate = regexs(1) if regexm(var1, "([0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9])")
gen address = upper(trim(itrim(substr(var2,40, 31))))
gen city = trim(itrim(upper(substr(var2,71,20))))
gen statezip =trim(itrim(upper(substr(var2, 103, 25))))
split statezip, parse(" ")
rename (statezip1 statezip2) (state zipcode)
replace zipcode = statezip3 if trim(zipcode) == "WI"
replace state = upper(trim(state))
replace zipcode =(trim(substr(zipcode,1,5)))
replace state = "" if regexm(state, "[0-9]")
replace state = "WI" if state == "I"

gen regagent = trim(itrim(upper(substr(var2,1,38))))


drop if dataid == ""

gen for_llc = strpos(corptype,"Foreign LLC") > 0 | strpos(corptype,"Foreign Limited") > 0
gen foreign = strpos(corptype,"Foreign" ) > 0
gen is_corp = strpos(corptype, "Business") > 0 | strpos(corptype,"Corpora") > 0 | foreign & !for_llc

replace jurisdiction = "WI" if missing(jurisdiction)
keep if inlist(jurisdiction, "DE", "WI")

rename incdate incdatestr
gen incdate = date(incdatestr,"MDY")

gen incyear = year(incdate)
gen shortname = wordcount(entityname) <= 3
gen is_DE = jurisdiction == "DE"


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

tomname entityname

keep dataid entityname incdate incyear is_DE jurisdiction zipcode state city address is_corp shortname foreign 
order dataid entityname incdate incyear is_DE jurisdiction zipcode state city address is_corp shortname foreign 
save $WI_dta_file, replace








**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	


u $WI_dta_file, clear
tomname entityname
save $WI_dta_file, replace

       corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta($WI_dta_file)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta($WI_dta_file)
	

	# delimit ;
	corp_add_trademarks WI , 
		dta($WI_dta_file) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications WI WISCONSIN , 
		dta($WI_dta_file) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  WI WISCONSIN , 
		dta($WI_dta_file)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 WI  ,dta($WI_dta_file) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta)  longstate(WISCONSIN)
	corp_add_mergers WI  ,dta($WI_dta_file) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.pre2014.dta)  longstate(WISCONSIN) 
	replace targetsic = trim(targetsic)
	
	foreach var of varlist equityvalue mergeryear mergerdate{
	rename `var' `var'_new
	}
	
corp_add_vc WI ,dta($WI_dta_file) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(WISCONSIN)

clear
u $WI_dta_file

safedrop shortname
gen  shortname = wordcount(entityname) <= 3
save $WI_dta_file, replace

