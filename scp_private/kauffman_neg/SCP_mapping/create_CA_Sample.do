cd ~/kauffman_neg/

/*
clear
u analysis34.minimal.dta
keep if datastate == "CA"
safedrop _merge 
save RJ/CA.collapsed.minimal.dta, replace
*/
    

clear
import delimited using ZIP_COUNTY_122016.csv , delim(",") varnames(1)
rename zip zipcode
tostring zipcode, replace
save county_zipcode.dta , replace

merge m:m zipcode using RJ/CA.collapsed.minimal.dta
keep if _merge == 3

keep zipcode county bus_ratio quality incyear growthz
gen obs = 1

*rather than county the ZIP Code completely, only the share that
* is in each county
replace obs = obs *bus_ratio
replace growthz = growthz *bus_ratio
collapse (sum) obs growthz (mean) quality , by(county incyear)
gen recpi = obs * quality
gen reai = growthz/recpi
replace reai = . if incyear  > 2008
replace growthz = . if incyear > 2008
save county_results_rj.dta , replace
outsheet using ~/kauffman_neg/output/RJ/county_quality_obs_recpi.csv, comma names


/** Firm by firm file **/
 
clear
u /projects/reap.proj/geocoding/CA.geocoded.byfirm.dta
merge m:m zipcode using county_zipcode.dta
gsort dataid -bus_ratio
by dataid: gen topzipcode = _n==1
by dataid: egen numcounties = sum(1)
keep if topzipcode
drop qualitynow qualityemp* _merge*
format incdate %d
gen incyear = year(incdate)
drop *ratio
outsheet using ~/kauffman_neg/output/RJ/CA_All_Firms.csv , comma names replace




clear
u /projects/reap.proj/geocoding/CA.geocoded.byfirm.dta

gen obs = 1
gen year = year(incdate)
drop if quality == .
collapse (mean) quality (sum) obs, by(lat lon year)



sort quality
gen key = _n
gen percentile = min(floor(_n/_N*100),99)/100
sort percentile

gen json = "{'type': 'Feature','geometry': {'type': 'Point', 'coordinates':  [" + string(lon) + "," + string(lat) + "] }, 'properties': { 'Key':" + string(key) + ",    'PercentileBin':" + string(percentile) + ",'Year':" + string(year) + ", 'ObsSum':" + string(obs) + " } },"

cd ~/kauffman_neg/output/RJ/
    

replace json = substr(json,1,length(json)-1) if _n == _N
gen cleanjson = subinstr(json,"'",`"""',.)
outsheet cleanjson using  ca.earlyjson , nonames noquote comma replace


! echo "{   'type': 'FeatureCollection',   'features': [" > CA.allfirms.geojson
! cat ca.earlyjson >> CA.allfirms.geojson
! echo "]}" >> CA.allfirms.geojson
 
