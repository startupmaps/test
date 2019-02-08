cd ~/kauffman_neg/

    local state NY


clear
u analysis34.minimal.dta
keep if datastate == "`state'"
safedrop _merge 
save ~/kauffman_neg/RJ/dta/`state'.collapsed.minimal.dta, replace

clear 
u  ~/kauffman_neg/RJ/dta/`state'.collapsed.minimal.dta 
safedrop obs     
gen obs = 1
collapse (sum) obs, by(city)
drop if obs < 50
capture ssc install geocode
gen datastate = "`state'"
geocodeopen , key("v2f0urgEM3iinPwTEZcYA83NDgPPm4PC") city(city) state(datastate)
 save ~/kauffman_neg/RJ/dta/`state'_cities_lat_lon.dta , replace

clear 
u RJ/CA.collapsed.minimal.dta 
safedrop obs
gen obs=1
collapse (mean) quality (sum) obs growthz, by (incyear city)
gen recpi = quality * obs
gen reai = growthz/recpi
merge m:1 city using RJ/CA_cities_lat_lon.dta
keep if _merge == 3
 outsheet using output/RJ/CA_by_city.csv , comma names replace
outsheet using output/RJ/CA_citylist.csv, comma names replace
