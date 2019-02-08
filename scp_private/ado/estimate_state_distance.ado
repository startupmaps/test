


capture program drop estimate_distance

program define estimate_state_distance , rclass
	syntax , destlat(real) destlon(real) sourcestate(varname) gen(name)
{

    capture confirm variable "~/ado/State_lat_lon.dta"
	if _rc != 0 {
		preserve
		clear 
		import delimited  using "~/ado/State_lat_lon.csv", delim(",") varnames(1)
		safedrop v5
		rename stateabbr _stateabbr
		save "~/ado/State_lat_lon.dta" , replace
		restore
	}
	
	capture confirm variable _stateabbr
	if _rc == 0 {
		di "ERROR: variable _stateabbr already exists but is needed for script"
	}
	
	
	gen _stateabbr = `sourcestate'
	
	merge m:1 _stateabbr using "~/ado/State_lat_lon.dta" 
	drop if _merge == 2
	drop _merge
	local R=6371e3
	
	/*** This was done by following the code in http://www.movable-type.co.uk/scripts/latlong.html **/
	
	/** Convert to Radians **/
	gen _statelat_rad = statelat * 3.141592 / 180
	gen _statelon_rad =statelon * 3.141592 / 180
	local _destlat_rad = `destlat' * 3.141592 / 180
	local _destlon_rad = `destlon' * 3.141592 / 180
	
	/** Get the radian difference **/
	gen _deltalat = `_destlat_rad' - _statelat_rad
	gen _deltalon = `_destlon_rad' - _statelon_rad

	gen __a  = sin(_deltalat) * sin(_deltalat) + cos(_statelat_rad) * cos(`_destlat_rad') * sin(_deltalon) * sin(_deltalon)
	gen __c = 	2 *atan2(sqrt(__a), sqrt(1-__a))
	
	gen  `gen' = `R' * __c
	
	safedrop _statelat_rad _statelon_rad _deltalat _deltalon __a __c
}
end
