


program define quality_boost_2015, rclass
      syntax  , save(string) [dta(string)]

if "`dta'" != "" {
u `dta'  , replace
}


keep if inrange(incyear, 2014,2015)
levelsof datastate, local(states)
safedrop  incmonth rsort
gen incmonth = month(incdate)
gen rsort= runiform()
sort  datastate incmonth incyear  rsort


gen in2015 = incyear == 2015
by datastate incmonth: egen count2015 = sum(in2015)
by datastate incmonth incyear: gen in2014comparable = _n <= count2015 if incyear == 2014
by datastate: egen comparable2014quality = mean(quality) if in2014comparable
by datastate: egen full2014quality = mean(quality) if incyear == 2014

gen obs2014 = 1 if incyear == 2014
gen obs2015 = 1 if incyear == 2015

collapse (mean) comparable2014quality full2014quality (sum) obs2014 obs2015, by(datastate)
gen qualityboost2015 = full2014quality/comparable2014quality
gen year = 2015
replace qualityboost2015 = 1 if datastate == "MA"
list
keep datastate year qualityboost2015
save `save', replace
end 
