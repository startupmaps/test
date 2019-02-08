cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg

u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/allstates.minimal_final2019.dta, clear
/*
	drop quality_new
	eststo: logit growthz_new eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond i.statecode if inrange(incyear, 1988,2008), vce(robust) or
	predict quality_new, pr
save /NOBACKUP/scratch/share_scp/scp_private/final_datasets/allstates.minimal_final2019.dta, replace
*/
keep if incyear<2015 & incyear >1987
gen obs = 1
replace zipcode = trim(itrim(zipcode))
replace zipcode = substr(zipcode, 1, 5)

collapse (sum) obs growthz_new (mean) quality = quality_new, by(zipcode incyear datastate)

gen recpi = quality * obs
gen reai = growthz / recpi
drop if missing(zipcode)
drop if !regexm(zipcode, "[0-9][0-9][0-9][0-9][0-9]")

merge m:m zipcode using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/county_zipcode.dta 
keep if _merge == 3
drop _merge

// keep zipcode county bus_ratio quality incyear growthz
    tostring county, replace
    replace county = "0" + county if length(county) == 4
/*not use    
    gen obs = 1
    replace obs = obs *bus_ratio
    replace growthz = growthz *bus_ratio
    collapse (sum) obs growthz (mean) quality , by(county incyear)
*/
    rename county countycode
    rename incyear year

    drop if year == .

    drop if countycode == ""
    gen statefp = substr(countycode,1,2)
    gen countyfp = substr(countycode,3,3)

    merge m:1  statefp countyfp using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/countylist.dta 
    keep if _merge == 3
    drop _merge 
    drop statefp countyfp *ratio countycode
    drop if datastate != state
    sort year zipcode datastate
    rename datastate StateAbbr
    rename growthz_new growthz
    drop state countyname
    compress      
    order zipcode year StateAbbr quality obs growthz recpi reai
    save zipcode_share.dta, replace
   
export delimited using "/user/user1/yl4180/save/zipcode_share.csv", replace
