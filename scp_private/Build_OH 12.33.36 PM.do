 clear
 cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets
 
 
 local keepraw = 0
 local dtasuffix = ""
global mergetempsuffix="Ohio_State"
global OH_dta_file OH.dta
global only_DE 0

 set more off
 
 
 clear
 import delimited dataid articlesfilingdoc entityname firmtype x3 x4 filingdate x5  active x6 x7 x8 x9 x10 city state  v1 v v3 v4 v5 v6 v7 v8 v9 z1 z2 z3 z4  using /NOBACKUP/scratch/share_scp/raw_data/Ohio/CORPDATA.BUS, delim("|")
 
 gen is_corp = inlist(firmtype,"CP","CF")
gen is_foreign = inlist(firmtype,"CF","LF")
 gen is_nonprofit = inlist(firmtype,"CN")
 drop if inlist(firmtype,"CN","FN","MO","NR","RN") | inlist(firmtype,"RT","SM","BT","00","CV","UN")

gen zipcode = ""
gen stateaddress = state


 split filingdate ,parse(" ")
 gen incdate = date(filingdate1,"YMD")
 gen incyear = year(incdate)

savesome if !is_foreign using $OH_dta_file , replace 

keep if is_foreign
tomname entityname
save OH.foreign.dta , replace

corp_get_DE_by_name ,dta(OH.foreign.dta) 
keep if is_DE
append using $OH_dta_file

replace is_DE = 0 if is_DE == .

if $only_DE == 1 {
    keep if is_DE == 1
}
keep dataid  entityname incdate incyear is_corp    city state zipcode is_nonprofit is_DE
gen stateaddress  = state

gen address = ""
replace state = trim(itrim(upper(state)))
gen local_firm = state == "OH"
save $OH_dta_file,replace








 *** DIRECTORS *** 
 
clear 
import delimited dataid numdirector fullname  using /NOBACKUP/scratch/share_scp/raw_data/Ohio/CORPDATA.ASS, delim("|")

/*assume that only the first three directors are important*/
keep if numdirector <= 3


split fullname, parse(" ") limit(2)
rename fullname1 firstname
gen title = "PRESIDENT"
keep dataid title firstname fullname
save OH.directors.dta,replace
	
	
	
*** OLD NAMES ***
	
	
 clear 
 import delimited dataid namechangeddate oldname using /NOBACKUP/scratch/share_scp/raw_data/Ohio/CORPDATA.NAM, delim("|")
 
duplicates drop
save OH.names.dta,replace

	

	
****
*** Step 2: Add Information
****


	
	u OH.dta, replace
	tomname entityname
	save OH.dta, replace
	corp_add_names,dta($OH_dta_file) names(OH.names.dta)
	
	
	clear
	u $OH_dta_file

	drop if missing(dataid)
	save $OH_dta_file,replace

	corp_add_gender, dta($OH_dta_file) directors(OH.directors.dta) names(/NOBACKUP/scratch/share_scp/scp_private/ado/names/NATIONAL.TXT)

	corp_add_eponymy, dtapath($OH_dta_file) directorpath(OH.directors.dta)
	
	
	
	# delimit ;
	corp_add_patent_applications OH OHIO , 
		dta($OH_dta_file) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  OH OHIO , 
		dta($OH_dta_file)
		pat("/NOBACKUP/scratch/share_scp/ext_data/patent_assignments.dta" "/NOBACKUP/scratch/share_scp/ext_data/patent_assignments2.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	

	# delimit ;
	corp_add_trademarks OH , 
		dta($OH_dta_file) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		classificationfile(/NOBACKUP/scratch/share_scp/ext_data/classification.dta)
		tomonths(12)
		;
	
	# delimit cr	

	corp_add_vc 	 OH  ,dta($OH_dta_file) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(OHIO) 


	corp_add_ipos	 OH  ,dta($OH_dta_file) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta)  longstate(OHIO) 
	corp_add_mergers OH  ,dta($OH_dta_file) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta)  longstate(OHIO) 


*		set trace on
*		set tracedepth 1
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta($OH_dta_file)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta($OH_dta_file)

	

clear
u $OH_dta_file
gen  shortname = wordcount(entityname) <= 3
 save $OH_dta_file, replace
 
***** address *********
clear
import delimited dataid using /NOBACKUP/scratch/share_scp/raw_data/Ohio/CORPDATA.ADR, delim("|")
replace  v7 = substr(v7, 1, 5)

*keep if v6 == "OH"
replace v3 =trim(itrim(v3))
replace v3 =upper(v3)
replace v4 =trim(itrim(v4))
replace v4 =upper(v4)
replace v5 =trim(itrim(v5))
replace v5 =upper(v5)
replace v6 =trim(itrim(v6))
replace v6 =upper(v6)
replace v7 =trim(itrim(v7))

gen a4 = ", " + v4 if v4 != ""
gen a5 = ", " + v5 if v5 != ""
gen a6 = ", " + v6 if v6 != ""
gen a7 = ", " + v7 if v7 != ""

sort dataid
quietly by dataid: gen dup = cond(_N == 1,0,_n)

drop if dup > 1
drop dup
rename (v3 v4 v5 v6 v7) (address1 address2 city state zipcode)

keep dataid city state zipcode address1 address2
gen addr_priority = 1
save OH.address.dta, replace

*************** AGN address **********
clear
import delimited dataid using /NOBACKUP/scratch/share_scp/raw_data/Ohio/CORPDATA.AGN, delim("|")
replace  v9 = substr(v9, 1, 5)

replace v4 =trim(itrim(v4))
replace v4 =upper(v4)
replace v5 =trim(itrim(v5))
replace v5 =upper(v5)
replace v6 =trim(itrim(v6))
replace v6 =upper(v6)
replace v7 =trim(itrim(v7))
replace v7 =upper(v7)
replace v9 =trim(itrim(v9))


gen a5 = ", " + v5 if v5 != ""
gen a6 = ", " + v6 if v6 != ""
gen a7 = ", " + v7 if v7 != ""
gen a9 = ", " + v9 if v9 != ""


sort dataid
quietly by dataid: gen dup = cond(_N == 1,0,_n)

drop if dup > 1
drop dup
rename (v4 v5 v6 v7 v9) (address1 address2 city state zipcode)

keep dataid city state zipcode address1 address2
gen addr_priority = 2
save address_AGN.dta,replace

append using OH.address.dta

sort dataid
quietly by dataid: egen min_priority = min(addr_priority)
keep if addr_priority == min_priority
rename (city state) (city2 state2)
save OH.address.dta, replace


******** Merge *******
u OH.dta, clear

safedrop address
safedrop zipcode
save OH.dta, replace

u OH.address.dta, clear
merge 1:m dataid using OH.dta

drop if _merge == 1 
drop _merge

gen     address = address1 + " " + address2
replace address = trim(itrim(subinstr(address,",","",.)))

//Only for DE firms, we don't want the address of the agent
foreach v in  address city state zipcode {
    replace `v' = "" if is_DE == 1 & addr_priority == 2
}

replace city2 = city if city2 == ""
drop city 
rename city2 city

replace state2 = state if state2 == ""
drop state
rename state2 state
replace state = trim(itrim(upper(state)))
replace stateaddress  = state




compress

replace local_firm = state == "OH"
save OH.dta, replace
save /NOBACKUP/scratch/share_scp/migration/datafiles/OH.dta, replace


