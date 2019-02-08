local state IL

clear
import delimited using  ~/projects/reap_proj/geocoding/`state'_cleaned-output.csv , delim(",") varnames(1)
keep if precision == "Zip9"


keep dataid latitude longitude
tostring dataid, replace
gen datastate = "`state'"
merge 1:m dataid datastate using ~/kauffman_neg/analysis34.minimal.dta
keep if _merge == 3
rename incyear year
collapse (mean) quality = quality (sum) recpi = quality (count) num_observations = quality ,by(latitude longitude year)

save ~/projects/reap_proj/geocoding/`state'.geocoded.bypoint.dta , repalce
