cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets
u allstates.minimal_final.dta, clear

keep if incyear < 2019 & incyear > 1987
safedrop mergerdate_old mergerdate_Z quality_old quality_Z diffmerger_old diffmerger_Z growthz_old growthz_Z is_merger_old is_merger_Z
rename (mergerdate_new quality_new diffmerger_new growthz_new is_merger_new) (mergerdate quality diffmerger growthz is_merger)

logit growthz eponymous shortname is_corp is_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond if inrange(incyear, 1988,2008), vce(robust) or
predict qualitynow, pr
replace quality = qualitynow if inrange(incyear, 2016, 2018)

replace zipcode = itrim(trim(zipcode))
replace zipcode = substr(zipcode, 1,5)

merge m:m zipcode using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/county_zipcode.dta 
keep if _merge == 3
drop _merge
keep zipcode county bus_ratio quality incyear growthz
    tostring county, replace
    replace county = "0" + county if length(county) == 4
    
    gen obs = 1
    replace obs = obs *bus_ratio
    replace growthz = growthz *bus_ratio

    collapse (sum) obs growthz (mean) quality , by(county incyear)

    rename county countycode
    rename incyear year

    drop if year == .

    gen recpi = obs * quality
    gen raw_reai = growthz/recpi
    replace raw_reai = . if year  > 2008
    gen reai =  raw_reai * 100
    replace reai = 1 if reai == 0
    drop if countycode == ""
    gen statefp = substr(countycode,1,2)
    gen countyfp = substr(countycode,3,3)

    merge m:1  statefp countyfp using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/countylist.dta 
    keep if _merge == 3
    drop _merge 
    drop statefp countyfp countycode
    sort state countyname year
    compress
order year state countyname obs growthz quality recpi reai raw_reai
save minimal_by_county.dta, replace
export delimited using "/user/user1/yl4180/save/minimal_by_county.csv", replace
    
