
clear
u $datafile
gen incquarter = quarter(incdate)
gen incmonth = month(incdate)


clear
u $datafile
gen incmonth = month(incdate)
rename (incyear incmonth) (year month)
safedrop obs
gen obs = 1
collapse (sum) obs recpi=quality (mean) quality, by(year month)
save indexes_monthly.dta , replace
