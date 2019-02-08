
cd ~/kauffman_neg
capture log close 


log using ~/kauffman_neg/output/Build_External_Indexes.log, replace text

cd ~/kauffman_neg/


clear
import delimited using state_fips_code.csv, delim(",") varnames(1)
keep statename stateabbr fipscode
save statecodes.dta, replace

clear
import delimited using bds_f_agest_release.csv, delim(",") varnames(1)
keep if fage == "a) 0"
rename state fipscode
rename firms firmbirthsbds
rename year2 year
keep fipscode firmbirthsbds year
merge m:1 fipscode using statecodes.dta
keep if _merge == 3
drop _merge
save state_external.dta, replace


clear 
import delimited using "/projects/reap.proj/raw_data/gsp_naics_all_R.csv", delim(",") varnames(1)

keep if industryid == 1
forvalues i=9/26 {
    local year=`i' - 9 + 1997
    rename v`i' gsp`year'
}
gen fipscode = substr(geofips,1,2)
destring fipscode, replace
keep gsp* fipscode geoname 
reshape long gsp, i(fipscode) j(year)
gen gspyear = 2009
destring gsp, replace
save GSP.dta, replace


clear 
import delimited using "/projects/reap.proj/raw_data/gsp_sic_all_R.csv", delim(",") varnames(1)

keep if industryid == 1
forvalues i=9/43 {
    local year=`i' - 9 + 1963
    rename v`i' gsp`year'
}
gen fipscode = substr(geofips,1,2)
destring fipscode, replace
keep gsp* fipscode geoname 
reshape long gsp, i(fipscode) j(year)
gen gspyear = 1997
replace  gsp = "" if gsp == "(NA)"
destring gsp, replace
append using  GSP.dta
save GSP.dta, replace

by fipscode year (gspyear), sort: gen adjustment_2009gdp = gsp[_n+1]/gsp if fipscode == 0
egen adj = max(adjustment_2009gdp)
replace gsp = gsp* adj if gspyear == 1997
drop if gspyear == 1997 & year == 1997
drop adj*
save GSP.dta, replace

merge m:1 fipscode using statecodes.dta
keep if _merge == 3
drop _merge
save GSP.dta, replace


merge 1:1 fipscode year using state_external.dta

drop if _merge == 1 & year < 2013
drop _merge

*gen insample = inlist(stateabbr , "AK","CA","FL","GA","MA","MI") | inlist(stateabbr,"NY","OR","TX","VT","WA","WY")
gen insample = inlist(stateabbr , "AK","CA","FL","GA","MA","MI") | inlist(stateabbr,"OR","TX","VT","WA","WY")
by year insample, sort: egen samplegsp = sum(gsp)
by year insample, sort: egen samplebdsbirths = sum(firmbirthsbds)
replace samplegsp =. if !insample
replace samplebdsbirths =. if !insample

save external_data.dta, replace


u external_data.dta, replace
drop if !insample
keep year samplegsp samplebdsbirths
duplicates drop
save external_data_yearly.dta, replace




/*MSA Results*/

import delimited using /projects/reap.proj/raw_data/zcta_cbsa_rel_10.txt, delim(",") varnames(1)
keep zcta cbsa memi
keep if memi == 1
rename (zcta cbsa) (zipcode msacode)
save zipcode_to_msa.dta, replace

clear
import delimited using /projects/reap.proj/raw_data/Gross_MSA_Product_allMSA.csv, delim(",") varnames(1)

local startyear = 2001

forvalues i=9/21 {
    rename v`i' msagdp`startyear'
    local startyear = `startyear' + 1
}
keep if description  == "All industry total"
keep if componentname == "GDP by Metropolitan Area (millions of current dollars)"
destring geofips, replace
rename geofips msacode
rename geoname msaname
reshape long msagdp, i(msacode) j(year)
save msagdp.dta, replace

outsheet using ~/kauffman_neg/output/GSP_Firms.csv, replace comma names 
log close





