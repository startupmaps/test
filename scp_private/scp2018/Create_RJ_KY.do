cd /NOBACKUP/scratch/share_scp/scp_private/scp2018

************* Keep only DE/KY firm from 1988 to 2018 ***********
u KY.dta, clear
replace state = trim(itrim(state))
replace city = upper(trim(itrim(city)))
replace zipcode = trim(itrim(zipcode))
replace address = upper(trim(itrim(address)))
keep if jurisdiction == "KY" | jurisdiction =="DE"
keep if state == "KY"
keep if incyear < 2019 & incyear > 1987
duplicates drop
keep if incyear > 2004
compress
export delimited using "/user/user1/yl4180/save/KY.post2005.csv", replace

**** address ******
u KY.dta, clear
keep if state == "KY"
keep if jurisdiction == "KY" | jurisdiction =="DE"
keep if incyear < 2019 & incyear > 1987
keep dataid address city state zipcode

replace zipcode = substr(zipcode, 1,5)
duplicates drop
save KY.address.dta, replace
export delimited using "/user/user1/yl4180/save/KY.address.csv", replace


******* Collapse *******

corp_collapse_any_state KY , workingfolder(/NOBACKUP/scratch/share_scp/scp_private/scp2018/) outputsuffix("new")

****** train before 2011 ********

u KY.collapsed.new.dta, clear
gen rsort = runiform()
gen trainingyears = inrange(incyear,1988,2011)
by trainingyears (rsort), sort: gen trainingsample = _n/_N <= .7
replace trainingsample = 0 if !trainingyears

********** logit ******

*** full model ****

logit growthz eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond if inrange(incyear, 1988,2011), vce(robust) or
predict quality, pr

logit growthz eponymous shortname is_corp is_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond if inrange(incyear, 1988,2011), vce(robust) or
predict qualitynow, pr

save KY.collapsed.dta, replace

******* RJ file ********

u KY.collapsed.new.dta, clear

*** full model up to 2015 ****

logit growthz eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond if inrange(incyear, 1988,2015), vce(robust) or
predict quality, pr

**** nowcasted from 2016 to 2018****
logit growthz eponymous shortname is_corp is_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond if inrange(incyear, 2016,2018), vce(robust) or
predict qualitynow, pr

save KY.collapsed.RJ.dta, replace
