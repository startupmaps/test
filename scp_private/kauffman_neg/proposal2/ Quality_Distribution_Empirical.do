cd ~/kauffman_neg

clear
u analysis.collapsed.dta

safedrop logempquality logempqualityold

safedrop firmgroup
egen firmgroup = group(is_DE patent trademark is_corp shortname haspropername is_IT is_biotech )

safedrop empquality
by firmgroup, sort: egen empquality = mean(growthz) if inrange(incyear,1995,2008)



save analysis.collapsed.dta, replace 


clear
u analysis.collapsed.dta
drop if missing(empquality)

sum growthz 
sort empquality
local totgrowth = `r(sum)'
foreach size in .01 .1 .001 .5  .05 .25 .2{
	quietly{
		safedrop percentile intratop qualitytop
		sort empquality
		gen percentile =floor((_n/_N)/`size')*100*`size'
		recast int percentile
		gen qualitytop = _n/_N >= (1-`size')
		sum growthz if qualitytop
		local qualitytopgrowth = `r(sum)'
	
		sort percentile growthz empquality
		by percentile, sort: gen intratop = _n/_N >= (1-`size')
		sum growthz if intratop
		local intratopgrowth = `r(sum)'
		
	}
	di "size = `size'; intra=`intratopgrowth' ; quality=`qualitytopgrowth' ; total growth = `totgrowth' ; Num Firms = "
}




clear
u analysis.collapsed.dta , replace

keep if !missing(empquality2)
sort empquality2 
gen percentile = _n/_N
safedrop obs
gen obs = 1





clear
u analysis.collapsed.dta , replace

keep if !missing(empquality)
sort empquality 
gen percentile = floor(_n/_N*10000)/10000
replace percentile = 0 if _n/_N < .5
replace percentile = .5 if inrange(_n/_N,.5,.9)
replace percentile = .9 if inrange(_n/_N , .9,.99)

replace percentile = .99 if inrange(_n/_N , .99,.999)
replace percentile = .9999 if percentile == 1
safedrop obs
gen obs = 1
collapse (mean ) mean_growth = growthz (sd) sd_growth = growthz (sum) obs growthz, by(percentile)
gen coeffvariation = sd_growth/mean_growth
gen sharpe = 1/coeffvariation


gen upper95ci = mean_growth+1.96*sd_growth
gen lower95ci = mean_growth-1.96*sd_growth
replace lower95ci = 0 if lower95ci < 0

safedrop odds*

gen oddslower95 = 1/upper95ci
gen oddsmean = 1/mean_growth
gen oddsupper95 = 1/lower95ci

list percentile coeffvariation mean sd odds*



clear
u analysis.collapsed.dta , replace



gen rounded_quality = floor(logempquality*100)/100
safedrop obs
gen obs = 1
collapse (sum) obs (max) is_DE is_corp patent trademark, by(rounded_quality)


drop if rounded_quality == .

safedrop cumobs log10share sharecum totobs
gsort -rounded_quality
gen cumobs = sum(obs)
egen totobs = sum(obs)
gen sharecum = cumobs/totobs


gen log10share = log10(share)

save quality_distribution.dta, replace


clear 
u quality_distribution.dta, replace

regress log10share rounded_quality  if rounded_quality < -1
regress log10share rounded_quality  if rounded_quality >= -1



set scheme s2color
# delimit ;
scatter log10share rounded_quality  
        || lfit log10share rounded_quality if log10share > -3.3, range(-5 -.6) lpattern(dash)
	|| lfit log10share rounded_quality if log10share <= -3.3 , range(-1.5 0) lpattern(dash)
	legend(off)
	xtitle("Emprical Quality = Mean ({it:Growth}) ") ytitle("P(Quality > X)")
	ylabel(0 "100%" -1 "10%" -2 "1%" -3 "0.1%" -4 ".01%" -5 "1/100,000" -6 "1/1,000,000", angle(0))
	xlabel(0 "1" -1 ".1" -2 ".01" -3 ".001" -4 ".0001" -5 ".00001")
	title("Cumulative Distribution of Quality in Population");



# delimit ;
scatter log10share rounded_quality  if is_DE , msymbol(d) mcolor(blue) msize(medium)  jitter(2 2)
	|| scatter log10share rounded_quality  if !is_DE ,  msymbol(o) mcolor(green) msize(medium)  jitter(2 2)
        || lfit log10share rounded_quality if log10share > -3.3, range(-5 -.6)
	|| lfit log10share rounded_quality if log10share <= -3.3 , range(-1.5 0)
	legend(label(1 "Delaware Jurisdiction") label(2 "Local Jurisdiction") order(1 2))
	xtitle("Emprical Quality = Mean ({it:Growth}) ") ytitle("P(Quality > X)")
	ylabel(0 "100%" -1 "10%" -2 "1%" -3 "0.1%" -4 ".01%" -5 "1/100,000" -6 "1/1,000,000", angle(0))
	xlabel(0 "1" -1 ".1" -2 ".01" -3 ".001" -4 ".0001" -5 ".00001")
	title("Cumulative Distribution of Quality in Population");
	
	
	# delimit ;
scatter log10share rounded_quality  if is_corp , msymbol(d) mcolor(blue) msize(medium)  jitter(2 2)
	|| scatter log10share rounded_quality  if !is_corp ,  msymbol(o) mcolor(green) msize(medium)  jitter(2 2)
        || lfit log10share rounded_quality if log10share > -3.3, range(-5 -.6)
	|| lfit log10share rounded_quality if log10share <= -3.3 , range(-1.5 0)
	legend(label(1 "Corporations") label(2 "LLCs and Partnerships") order(1 2))
	xtitle("Emprical Quality = Mean ({it:Growth}) ") ytitle("P(Quality > X)")
	ylabel(0 "100%" -1 "10%" -2 "1%" -3 "0.1%" -4 ".01%" -5 "1/100,000" -6 "1/1,000,000", angle(0))
	xlabel(0 "1" -1 ".1" -2 ".01" -3 ".001" -4 ".0001" -5 ".00001")
	title("Cumulative Distribution of Quality in Population");
	
	
	# delimit ;
scatter log10share rounded_quality  if patent , msymbol(d) mcolor(blue) msize(medium)  jitter(2 2)
	|| scatter log10share rounded_quality  if !patent ,  msymbol(o) mcolor(green) msize(medium)  jitter(2 2)
        || lfit log10share rounded_quality if log10share > -3.3, range(-5 -.6)
	|| lfit log10share rounded_quality if log10share <= -3.3 , range(-1.5 0)
	legend(label(1 "Has Early Patent") label(2 "Does not Have Early Patent") order(1 2))
	xtitle("Emprical Quality = Mean ({it:Growth}) ") ytitle("P(Quality > X)")
	ylabel(0 "100%" -1 "10%" -2 "1%" -3 "0.1%" -4 ".01%" -5 "1/100,000" -6 "1/1,000,000", angle(0))
	xlabel(0 "1" -1 ".1" -2 ".01" -3 ".001" -4 ".0001" -5 ".00001")
	title("Cumulative Distribution of Quality in Population");




