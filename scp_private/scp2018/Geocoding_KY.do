
clear 
//import delimited using "/user/user1/yl4180/save/KY_lat_lon.csv", varname(1)
//save KY_lat_lon.dta, replace

cd /NOBACKUP/scratch/share_scp/scp_private/scp2018
u KY_lat_lon.dta, clear

replace dataid = trim(dataid)

replace dataid = "0" + dataid if strlen(dataid) < 11
replace dataid = "0" + dataid if strlen(dataid) < 11
replace dataid = "0" + dataid if strlen(dataid) < 11
replace dataid = "0" + dataid if strlen(dataid) < 11
replace dataid = "0" + dataid if strlen(dataid) < 11
replace dataid = "0" + dataid if strlen(dataid) < 11

keep if v13 == "KY"
drop if missing(street)
replace v12 = trim(itrim(upper(v12)))
//replace city = trim(itrim(upper(city)))
//drop if city != v12
//tostring zip, replace
// drop if zip != zipcode

save KY_lat_lon_only.dta,replace

merge m:m dataid using KY.collapsed.RJ.dta

keep if _merge ==3
drop _merge

keep city state latitude longitude quality incyear
save KY.geocoding.dta,replace

gen obs = 1 
collapse (mean) quality (sum) obs, by(longitude latitude incyear)
drop if missing(longitude) & missing(latitude)

sort obs
sort quality
gen  quality_percentile_global = floor((_n-1)/_N*1000)

replace quality_percentile_global = quality_percentile_global +1 
bysort incyear (quality): gen quality_percentile_yearly= floor((_n-1)/_N * 1000)
replace quality_percentile_yearly = quality_percentile_yearly +1

rename (obs quality_percentile_global quality_percentile_yearly incyear) (o qg qy year)
safedrop id
egen id = group(longitude latitude)
keep id year longitude latitude o qg qy
reshape wide o qg qy , i(id) j(year)
	 	 
gen datastate = "KY"
order id datastate latitude longitude
	
	
foreach v of varlist o* qy* qg* {
        tostring `v' , replace force
        replace `v' = "0" if `v' == "."
 }

save KY_by_point.dta,replace
outsheet using /user/user1/yl4180/save/KY_by_point.csv, names comma replace

****** By City******
clear

u KY.geocoding.dta
gen obs = 1
collapse (mean) quality (sum) obs, by(incyear city)

sort city incyear
replace city = trim(itrim(city))
save KY.city.dta, replace

merge m:1 city using KYcitygeo.dta

keep if _merge == 3
drop _merge

sort quality
gen  quality_percentile_global = floor((_n-1)/_N*1000)

replace quality_percentile_global = quality_percentile_global +1 
bysort incyear (quality): gen quality_percentile_yearly= floor((_n-1)/_N * 1000)
replace quality_percentile_yearly = quality_percentile_yearly +1

rename (obs quality_percentile_global quality_percentile_yearly incyear) (o qg qy year)
safedrop id
egen id = group(longitude latitude)
keep id year city longitude latitude o qg qy
reshape wide o qg qy , i(id) j(year)
	 	 
gen datastate = "KY"
order id datastate city latitude longitude
	
	
foreach v of varlist o* qy* qg* {
        tostring `v' , replace force
        replace `v' = "0" if `v' == "."
 }
tostring latitude longitude, replace force
save KY.city.dta, replace

outsheet using /user/user1/yl4180/save/KY_by_city.csv, names comma replace


