cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta

global clean_minimal 0
global make_mapfile 0
global audit_top_cities 1

if $clean_minimal == 1 {
u ../../minimal_2019.dta, clear
safedrop obs
gen obs = 1 
drop if incyear ==.
replace city = subinstr(city, "#","",.)
replace city = subinstr(city, ",","",.)
replace city = subinstr(city, "&","",.)
replace city = subinstr(city, "%","",.)
replace city = subinstr(city, `"""',"",.)
replace city = subinstr(city, `"("',"",.)
replace city = subinstr(city, `")"',"",.)
replace city = subinstr(city, "*","",.)

replace city = subinstr(city, "+","",.)
replace city = subinstr(city, "-","",.)
replace city = subinstr(city, ":","",.)
replace city = subinstr(city, "/","",.)
forvalues i = 0/9{
replace city = subinstr(city, "`i'","",.)
}


replace city = upper(trim(itrim(city)))
replace city = subinstr(city, "ST.", "SAINT", .)
replace city = subinstr(city, ".","",.)
replace city = regexr(city, "\((.*)\)", "")
replace city = upper(trim(itrim(city)))
drop if city == ""
drop if incyear > 2014 | incyear < 1988
save minimal_clean.dta, replace

collapse (sum) obs growthz_new (mean) quality_new, by(city incyear datastate)
//keep if obs > 20
gen recpi = quality_new * obs
gen reai = growthz/recpi
merge m:1 city datastate using allcities_lat_lon
keep if _merge ==3
drop _merge
keep city datastate incyear obs growthz_new quality_new recpi reai lat lng 
order city datastate incyear obs growthz_new quality_new recpi reai lat lng 
rename (lat lng) (latitude longitude)
rename growthz_new growthz
rename quality_new quality
rename incyear year
save collapsed_clean.dta, replace
}
if $make_mapfile == 1{
u collapsed_clean.dta, clear
safedrop quality_percentile_global quality_percentile_yearly quality_percentile_state
    gen  quality_percentile_global = floor((_n-1)/_N*1000)
    replace quality_percentile_global = quality_percentile_global +1 
    bysort year (quality): gen quality_percentile_yearly= floor((_n-1)/_N * 1000)
    replace quality_percentile_yearly = quality_percentile_yearly +1
    
    drop if obs == .

    /** Keep only the main one **/
    bysort  datastate latitude longitude: egen num_in_state = sum(obs)
    bysort  latitude longitude: egen num_max = max(num_in_state)
    keep if num_in_state == num_max

    /** there are a few duplicates remaining, they are too small, too few and do not matter, just force to kill one **/
    safedrop keepme
    bysort latitude longitude: gen keepme = datastate == datastate[1]
    keep if keepme
    drop keepme
    
    rename (obs quality_percentile_global quality_percentile_yearly) (o qg qy)
    gen SO = round(sqrt(o),1)
    safedrop id
    egen id = group(latitude longitude)
    drop if latitude == . | longitude == . | year < 1988
    
    keep datastate id year lat lon o SO qg qy city
    order datastate id year lat lon o SO qg qy city
    egen median = median(SO), by(id)
    reshape wide o SO qg qy , i(id) j(year)
    gsort datastate -median
    replace id = _n

    foreach v of varlist o* SO* qy* qg* median{
        tostring `v' , replace force
        // the value of 0 means no value in the map
        replace `v' = "0" if `v' == "."
    }

    order id datastate city latitude longitude 

save allstates_cities_19.dta,replace
export delimited allstates_cities_19.csv, replace
export delimited /user/user1/yl4180/save/allstates_cities_19.csv, replace
}

if $audit_top_cities == 1{
import delimited /user/user1/yl4180/topcities.csv, clear
drop if missing(city)
replace city = subinstr(city, "-"," ",.)
replace city = upper(trim(itrim(city)))
replace city = subinstr(city, "ST.", "SAINT", .)
replace city = subinstr(city, "."," ",.)
replace city = upper(trim(itrim(city)))
replace state = upper(trim(itrim(state)))
rename state datastate
merge m:1 datastate using /user/user1/yl4180/us.dta
gsort- population
keep if _merge == 3
drop _merge
drop datastate
rename state datastate
save topcities.dta, replace

u collapsed_clean.dta, clear
merge m:1 city datastate using topcities.dta
keep if _merge == 2
sort rank
global statelist AK AR AZ CA CO FL GA IA ID IL KY LA MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
keep if inlist(datastate, "AK", "AR", "AZ", "CA", "CO", "FL", "GA", "IA", "ID") | inlist(datastate, "IL", "KY", "LA", "MA", "ME", "MI", "MN", "MO", "NC") | inlist(datastate, "ND", "NJ", "NM", "NY", "OH", "OK", "OR", "RI", "SC") | inlist(datastate, "TN", "TX", "UT", "VA", "VT", "WI", "WY", "WA")
keep city datastate rank population 
sort population
save cities_not_covered.dta, replace
export delimited cities_not_covered.csv, replace
export delimited /user/user1/yl4180/save/cities_not_covered.csv, replace
}

