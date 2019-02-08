cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg
u analysis34.minimal.dta, clear
keep if incyear<2019 & incyear >1987
replace zipcode = trim(itrim(zipcode))
replace zipcode = substr(zipcode, 1, 5)
//replace quality for qualitynow for some years?
collapse (sum) obs growthz (mean) quality, by(zipcode incyear datastate)

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
    drop growthz state countyname
    compress      
    order zipcode year StateAbbr quality obs recpi reai
    save zipscode_share34.dta, replace
   
export delimited using "/user/user1/yl4180/save/zipcode_share34.csv", replace
