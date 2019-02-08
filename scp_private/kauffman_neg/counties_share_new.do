cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/
u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/allstates.minimal_final2019.dta, clear

keep if incyear < 2015 & incyear > 1987
safedrop mergerdate_old mergerdate_Z quality_old quality_Z diffmerger_old diffmerger_Z growthz_old growthz_Z is_merger_old is_merger_Z
rename (mergerdate_new quality_new diffmerger_new growthz_new is_merger_new) (mergerdate quality diffmerger growthz is_merger)

replace zipcode = itrim(trim(zipcode))
replace zipcode = substr(zipcode, 1,5)

merge m:m zipcode using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/county_zipcode.dta 
keep if _merge == 3
drop _merge
keep zipcode county bus_ratio quality incyear growthz datastate
    tostring county, replace
    replace county = "0" + county if length(county) == 4
    
    gen obs = 1
    replace obs = obs *bus_ratio
    replace growthz = growthz *bus_ratio

    collapse (sum) obs growthz (mean) quality, by(county incyear datastate)

    rename county countycode
    rename incyear year

    drop if year == .

    gen recpi = obs * quality
    gen reai = growthz/recpi
    replace reai = 0 if reai ==.

    drop if countycode == ""
    gen statefp = substr(countycode,1,2)
    gen countyfp = substr(countycode,3,3)

    merge m:1  statefp countyfp using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/countylist.dta 
    drop if datastate != state
    keep if _merge == 3
    drop _merge 
    sort state countyname year
    compress
    order datastate year countycode obs growthz quality recpi reai statefp countyfp state countyname
    save counties_share.dta, replace
    export delimited using "/user/user1/yl4180/save/counties_share.csv", replace
    
