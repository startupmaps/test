clear
u sampleKY.dta
gen obs = 1 
collapse (mean) quality=nowcastingquality (sum) obs, by(longitude latitude incyear)
drop if longitude =="" & latitude ==""
sort obs
save withinKY.dta, replace
sort quality
gen  quality_percentile_global = floor((_n-1)/_N*1000)

replace quality_percentile_global = quality_percentile_global +1 
bysort incyear (quality): gen quality_percentile_yearly= floor((_n-1)/_N * 1000)
replace quality_percentile_yearly = quality_percentile_yearly +1

rename (obs quality_percentile_global quality_percentile_yearly   incyear) (o qg qy year)
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
	
outsheet using ~/Desktop/scp_private-master/KY_geocode/KY_address_all.csv, names comma replace


/**** Do a per innovation district file ***/


clear
u sampleKY.dta

foreach innov_v of varlist innov_* { 
		
	clear
	u sampleKY.dta
	keep if `innov_v' == 1
	
	gen obs = 1 
	collapse (mean) quality=nowcastingquality (sum) obs, by(longitude latitude incyear)
	drop if longitude =="" & latitude ==""
	sort obs
	save withinKY.dta, replace
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
		


	outsheet using ~/Desktop/scp_private-master/KY_geocode/KY_address_`innov_v'.csv, names comma  replace

}
