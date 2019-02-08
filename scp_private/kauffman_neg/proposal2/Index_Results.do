cd ~/kauffman_neg

display "Script started on: $S_DATE $S_TIME " 

capture program drop build_indexes


clear
u mc_index_results.dta

sum iteration_number
local total_iterations `r(max)'

local bottom_percentile 5
local top_percentile 195

if `total_iterations' < `bottom_percentile' {
    local bottom_percentile 1
}

if `total_iterations' < `top_percentile' {
    local top_percentile `total_iterations'
}


di "Using top=`top_percentile' bottom=`bottom_percentile'"

saferename incyear year
sort year recpi
by year: gen recpi_order = _n
sort year reai
by year: gen reai_order = _n

gen recpi_2_5= recpi if recpi_order == `bottom_percentile'
gen recpi_97_5= recpi if recpi_order == `top_percentile'


gen reai_2_5= reai if reai_order == `bottom_percentile'
gen reai_97_5= reai if reai_order == `top_percentile'

collapse recpi_2_5 recpi_97_5 reai_2_5 reai_97_5, by(year)
save conf_intervals_indexes.dta, replace



 
build_external_indexes , skipstates($skip_states_in_indexes)


clear
u $datafile
drop if incyear < 1988
build_indexes , skipstates($skip_states_in_indexes) predictreai
merge 1:1 year using conf_intervals_indexes.dta
keep if _merge != 2
drop _merge

merge 1:1 year using external_data_yearly.dta
keep if _merge != 2
drop _merge
gen countrycode = 1
xtset countrycode year

gen gdp_5year_growth = (F5.samplegsp - samplegsp)/samplegsp
drop if year == 2015
outsheet using ~/kauffman_neg/output/Indexes$output_suffix.csv, replace comma names
save indexes.dta, replace




clear
u $datafile
build_indexes, addby(datastate)  
rename datastate stateabbr
merge m:m stateabbr using statecodes
keep if _merge == 3
drop _merge


save ~/kauffman_neg/state_indexes.dta, replace
outsheet using ~/kauffman_neg/output/Indexes_State$output_suffix.csv, comma names replace


keep if year == 2012
keep if inlist(stateabbr,"OK","WA","NY","OH","VA")

outsheet using ~/kauffman_neg/output/Indexes_State_map.csv, comma names replace



clear
u $datafile

gen dropped = missing(quality)
tab datastate dropped

build_indexes, addby(datastate city)    /*  */
map_buckets quality

outsheet using ~/kauffman_neg/output/Indexes_City$output_suffix.csv, comma names replace



/*


clear
u $datafile
replace zipcode = trim(zipcode)
replace zipcode = substr(zipcode,1,5)
drop if regexm(zipcode, "[^0-9]")

drop if missing(zipcode)
safedrop _merge

add_cbsa , zipcode(zipcode)
drop if strpos(area,datastate) == 0

build_indexes, addby(area datastate)
drop if !inlist(datastate,"VT","AK") & (strpos(msaname,"NONMETROPOLITAN") > 0 | msaobs < 5000)
outsheet using ~/kauffman_neg/output/Indexes_MSA$output_suffix.csv, comma names replace

merge m:1 msacode year using msagdp.dta

by msacode, sort: egen msaobs = sum(obs)
drop if strpos(msaname,datastate) == 0
outsheet using ~/kauffman_neg/output/Indexes_MSA.with_GDP$output_suffix.csv, comma names replace
gsort msacode year -obs
by msacode year: gen ord=_n
keep if ord == 1
save msa_indexes.dta, replace



clear
import delimited using ~/kauffman_neg/input/zbp13totals.txt , delim(",") varnames(1) stringcols(_all)
keep zip stabbr
rename zip zipcode
save zip_state.dta, replace

clear
u $datafile
replace zipcode = trim(zipcode)
replace zipcode = substr(zipcode,1,5)
drop if zipcode == "" | zipcode == "."
keep if incyear == 2012
safedrop _merge
merge m:m zipcode using zip_state
keep if _merge == 3
keep if inlist(stabbr,"MA","CA","WA","TX","FL","NY") |  inlist(stabbr,"OR","MI","WY","VT","AK","GA")|inlist(stabbr,"OK","MO","ID")
drop if inlist(stabbr,"NY","WA")
build_indexes, addby(stabbr zipcode)   
map_buckets quality

outsheet using ~/kauffman_neg/output/Indexes_ZIPCode_only2012$output_suffix.csv, comma names replace
save zipcode_2012only.dta, replace

clear

u $datafile
keep if incyear == 2012
collapse (mean) quality, by(datastate)
keep if inlist(datastate,"WA","NY")
rename datastate stateabbr
append using zipcode_2012only.dta
drop map_bucket
map_buckets quality

*/

    

clear
u $datafile
replace zipcode = trim(zipcode)
replace zipcode = substr(zipcode,1,5)
drop if zipcode == "" | zipcode == "."
safedrop _merge
merge m:m zipcode using zip_state

keep if _merge == 3

keep if inlist(stabbr,"MA","CA","WA","TX","FL","NY") |  inlist(stabbr,"OR","MI","WY","VT","AK","GA")|inlist(stabbr,"OK","MO","ID")
keep if inlist(incyear,1988,1996,2000,2004,2007,2012)
build_indexes , addby(stabbr zipcode)
keep zipcode recpi quality obs year stabbr growthz
map_buckets quality
outsheet using ~/kauffman_neg/output/Indexes_ZIPCode_minimal$output_suffix.csv, comma names replace

*/

clear
u $datafile
replace zipcode = trim(zipcode)
replace zipcode = substr(zipcode,1,5)
drop if zipcode == "" | zipcode == "."
safedrop _merge
keep if inlist(incyear,1988,1996,2000,2004,2007,2012)

levelsof datastate , local(states)

merge m:m zipcode using zip_state

keep if _merge == 3

gen keepme = 0
foreach st in `states' {
    replace keepme = 1 if stabbr == "`st'"
}
keep if keepme
build_indexes , addby(stabbr zipcode)
add_cbsa , zipcode(zipcode)

keep zipcode recpi quality obs year stabbr growthz area cbsa
duplicates drop zipcode year , force
map_buckets quality
outsheet using ~/kauffman_neg/output/Indexes_ZIPCode_minimal_allyears.csv, comma names replace

keep if year == 2012
outsheet using ~/kauffman_neg/output/Indexes_ZIPCode_2012only.csv , replace comma names


keep zipcode recpinow qualitynow obs year stabbr
duplicates drop zipcode year , force
map_buckets quality
outsheet using ~/kauffman_neg/output/Indexes_ZIPCode_nowcasting_allyears.csv, comma names replace

keep if year == 2012
outsheet using ~/kauffman_neg/output/Indexes_ZIPCode_2012only.csv , replace comma names

