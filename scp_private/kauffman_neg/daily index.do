u analysis34.minimal.dta, clear
collapse (mean) quality = qualitynow (sum) obs, by(incdate)
keep if year(incdate) >= 1988
save daily.dta, replace

clear
set obs 10227
gen incdate = _n + 10226
save merge.dta, replace

clear
u daily.dta
merge 1:1 incdate using merge.dta
replace quality = 0 if missing(quality)
replace obs = 0 if missing(obs)
gen RECPI = quality * obs
gen year = year(incdate)
gen month = month(incdate)
gen day = day(incdate)
drop _merge
format incdate %1.0f
*format incdate %td

order incdate RECPI quality obs year month day
sort incdate
save daily.dta, replace
rm merge.dta





