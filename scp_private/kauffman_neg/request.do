u analysis34.minimal.dta, clear
ssc install rangestat
// 27550217
keep if incyear < 2015
gen id = _n
gcollapse (sum) ob2s growthz (mean) mean_quality = quality mean_qualitynow = qualitynow (sd) sd_quality = quality sd_qualitynow = qualitynow (skewness) sk_quality = quality sk_qualitynow = qualitynow  , by(datastate incyear) 
save request2.dta, replace
