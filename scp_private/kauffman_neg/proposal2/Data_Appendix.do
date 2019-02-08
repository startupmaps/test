cd ~/kauffman_neg


clear
u $datafile

levelsof datastate, local(states)

clear
gen dataid = "" 
save mergervalues.dta , replace
foreach state of local states {
	di "Building State `state'"
	clear
	u ~/final_datasets/`state'.dta
	keep if enterprisevalue != ""
	tostring dataid, replace
	keep enterprisevalue dataid
	gen datastate = "`state'"
	duplicates drop
	di "Dataset ready appending "
	append using mergervalues.dta
	save mergervalues.dta , replace
	di "Saved"
}




clear
u $datafile
safedrop _merge
merge m:m datastate dataid using mergervalues.dta
keep if _merge != 2
drop _merge

save analysis.lernerregression.dta , replace
*
u analysis.lernerregression.dta , replace

replace enterprisevalue = subinstr(enterprisevalue,",","",.)
replace enterprisevalue = "" if enterprisevalue =="nm"
destring enterprisevalue, replace
save analysis.lernerregression.dta , replace



u analysis.lernerregression.dta , replace


safedrop growthz9yr ipo6yr ipoever growthz_highval
gen growthz9yr = inrange(diffipo,0,12*9) & !missing(ipodate) | inrange(diffmerger,0,12*9) & !missing(mergerdate)
gen ipo6yr = inrange(diffipo,1,12*6) & !missing(ipodate) 
gen ipoever = diffipo>0 & !missing(ipodate)
gen growthz_highval = inrange(diffipo,0,12*6) & !missing(ipodate) | inrange(diffmerger,0,12*6) & !missing(mergerdate) & enterprisevalue >= 100


tabstat growthz ipo6yr growthz_highval if inrange(incyear, 1995,2008), stats(sum mean)
tabstat growthz growthz9yr ipoever ipo6yr if inrange(incyear, 1995,2005), stats(sum mean)

save analysis.lernerregression.dta , replace



# delimit ;
 local full_model_params is_corp 
                        eponymous shortname
                        trademark patent_noDE nopatent_DE patent_and_DE 
                        clust_local  clust_resource_int clust_traded
                        is_biotech is_ecommerce is_IT is_medicaldev is_semicond
                        ib11.statecode;
			
# delimit cr		

# delimit ;
 local nocorp_model_params 
                        eponymous shortname
                        trademark patent_noDE nopatent_DE patent_and_DE 
                        clust_local  clust_resource_int clust_traded
                        is_biotech is_ecommerce is_IT is_medicaldev is_semicond
                        ib11.statecode;
			
# delimit cr		
		
			
eststo clear
eststo, title("Original Regression"):logit growthz  `full_model_params'  if trainingyears, vce(robust) or
eststo, title("Growth (Only Acq >= 100M)"):logit growthz_highval  `full_model_params'  if trainingyears , vce(robust) or
eststo, title("IPO in 6 Years"):logit ipo6yr  `nocorp_model_params'  if trainingyears, vce(robust) or
eststo, title("Growth in 9 Years"):logit growthz9yr  `full_model_params'  if trainingyears, vce(robust) or
eststo, title("IPO (Ever)"):logit ipoever  `nocorp_model_params'  if trainingyears, vce(robust) or
output_model using ~/kauffman_neg/output/RegressionModel_Appendix_Other_Models$output_suffix.csv

stop right here for now

	   
/************************************************************************************
 ************************************************************************************  
 ***
 ***			Document the biases arising from location changes
 ***
 ************************************************************************************
 ************************************************************************************/
 
 
clear
import delimited using /projects/reap.proj/raw_data/Massachusetts/Massachusetts_2014_11_24/CorpData.txt, delim(",")  varnames(1)
rename postalcode zipcode
keep zipcode dataid 
replace zipcode =  substr(itrim(trim(zipcode)),1,5)
rename zipcode zipcode2015
duplicates drop
save ~/temp/MAzipcodes.dta , replace


clear
import delimited using /projects/reap.proj/raw_data/Massachusetts/01_06_2013/CorpData.txt, delim(",")  varnames(1)
rename postalcode zipcode
keep zipcode dataid 
replace zipcode =  substr(itrim(trim(zipcode)),1,5)
rename zipcode zipcode2013
merge m:m dataid using ~/temp/MAzipcodes.dta
keep if _merge == 3
drop _merge
duplicates drop
save ~/temp/MAzipcodes.dta , replace



gen datastate = "MA"
merge m:m dataid datastate using analysis.collapsed.dta
keep if _merge == 3
drop _merge 
save ~/kauffman_neg/change_of_address.analysis.dta , replace

clear 
u ~/kauffman_neg/change_of_address.analysis.dta , replace
keep zipcode 
replace zipcode =  substr(itrim(trim(zipcode)),1,5)
duplicates drop 
geocode3 ,address(zipcode)
save zipcode.MA.latlon.dta, replace

clear
u zipcode.MA.latlon.dta, replace
drop if g_status != "OK"
rename (zipcode g_lat g_lon) (zipcode2013 g_lat2013 g_lon2013)
drop g_status 
merge 1:m zipcode2013 using ~/kauffman_neg/change_of_address.analysis.dta
keep if _merge == 3
drop _merge 
save ~/kauffman_neg/change_of_address.analysis.dta, replace


clear
u zipcode.MA.latlon.dta, replace
drop if g_status != "OK"
rename (zipcode g_lat g_lon) (zipcode2015 g_lat2015 g_lon2015)
drop g_status 
merge 1:m zipcode2015 using ~/kauffman_neg/change_of_address.analysis.dta
keep if _merge == 3
drop _merge 
save ~/kauffman_neg/change_of_address.analysis.dta, replace

clear 
u ~/kauffman_neg/change_of_address.analysis.dta , replace

drop if length(zipcode2013) != 5 | length(zipcode2015) != 5
gen age = 2013-incyear-1

gen change_zipcode = zipcode2013 != zipcode2015 
gen dist_degrees = sqrt((g_lat2013-g_lat2015)^2+(g_lon2013-g_lon2015)^2)
gen dist_miles = dist_degrees*111/1.6

keep if mod(age,2)==0 & age >= 0

/*Table B2. Change by age*/
sort quality
gen top10 = change_zipcode if _n/_N >= .9
gen bottom50 = change_zipcode if _n/_N < .5

gen top1 = change_zipcode if _n/_N >= .99
tabstat change_zipcode top10 top1 bottom50, by(age) columns(variables)


sort zipcode2013
by zipcode2013: egen num2013 = sum(1)
by zipcode2013: egen zipquality2013 = mean(quality)
replace zipquality2013  =. if num2013 == 1
replace zipquality2013  = (zipquality2013*num2013-quality)/(num2013-1) /*Convert to leave one out estiamtes*/


sort zipcode2015
by zipcode2015: egen num2015 = sum(1)
by zipcode2015: egen zipquality2015 = mean(quality)
replace zipquality2015  =. if num2015 == 1
replace zipquality2015  = (zipquality2015*num2015-quality)/(num2015-1) /*Convert to leave one out estiamtes*/


gen dist_degrees = sqrt((g_lat2013-g_lat2015)^2+(g_lon2013-g_lon2015)^2)
gen dist_miles = dist_degrees*111/1.6



gen x = dist_miles
gen x2 =x^2
gen x3 =x^3

keep if change_zipcode
keep if dist_miles < 4000 /*karger is only geocoding errors as Google interprets international zipcodes*/
sort dist_miles

gen lq = ln(quality)
gen ld = ln(dist_miles)

regress ld lq, robust
gen la = ln(age+1)
regress ld la , robust

	   
/************************************************************************************
 ************************************************************************************  
 ***
 ***			Document the biases arising from re-incorporations
 ***
 ************************************************************************************
 ************************************************************************************/
 
 
cd ~/kauffman_neg/
    clear
u  analysis.collapsed.dta
keep if datastate == "MA"

save MA.collapsed.dta, replace

clear
import delimited using /projects/reap.proj/raw_data/Massachusetts/Massachusetts_2014_11_24/corpmergers.txt, delim(",")  varnames(1)
rename mergerdate mergerdatestr
gen mergerdate = date( substr(mergerdatestr,1,10),"YMD")

drop if year(mergerdate) < 1988
drop entityname


merge m:1 dataid  using MA.collapsed.dta
drop if _merge == 1
gen merger = _merge == 3
drop _merge
gen reregistration = abs(mergerdate - incdate) <= 90

program count_firms
    safedrop reregfirms
    gsort dataid -`1'
    by dataid: gen reregfirms = _n == 1 & `1'
    tabstat  reregfirms, stats(sum)
end

gsort dataid -reregistration
by dataid: gen reregfirms = _n == 1 & rereg

tab merger reregistration
tabstat reregfirms , stats(sum N mean)

keep if reregistration

foreach v of varlist dataid is_corp is_DE patent trademark shortname{
    rename `v' `v'_target
    di "rename `v' `v'_target"
}

rename mergeddataid dataid

merge m:1 dataid using MA.collapsed.dta
keep if _merge ==3
gen dataid = dataid_target


foreach v of varlist dataid is_corp is_DE patent trademark shortname{
    rename `v' `v'_source
    di "rename `v' `v'_source"
    
}

foreach vw of varlist is_corp_target is_DE_target patent_target trademark_target shortname_target{
    local v = subinstr("`vw'","_target","",.)
    di "gain_`v'"
    safedrop gain_`v'
    gen gain_`v' = `v'_source == 0 & `v'_target == 1
    
}


gen gain_DE = 

save mergers.MA.dta , replace 





