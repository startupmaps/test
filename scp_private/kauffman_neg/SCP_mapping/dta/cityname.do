clear
global statelist AK AR AZ CA CO FL GA IA ID IL KY MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY

foreach state in $statelist{
clear
set more off
use `state'_cities_lat_lon.dta

capture confirm variable geo_state
	if !_rc {
di "In `state' geo_code exists"	

save `state'_cities_lat_lon.dta, replace

drop if geo_state != "`state'"
		}
		else {
		di "In `state' geo_code does not exist"
		}
	}
