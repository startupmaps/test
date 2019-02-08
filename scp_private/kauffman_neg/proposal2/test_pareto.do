cd ~/kauffman_neg

 
clear
u analysis.collapsed.dta
  
gsort datastate incyear -quality 
by datastate incyear: gen logrank = log(_n)
 
gen qualityrank = 10^(floor(log(quality)/.01)*.01)
 
safedrop obs
gen obs = 1


gen log10quality = log10(quality)

gen rsort=  runiform()
sort rsort
keep if mod(_n,20) == 0

# delimit ;
kdensity log10quality, bwidth(.2) title("Density of Entrepreneurial Quality ({&theta})") xtitle("Quality ({&theta})") 
	xlabel(-6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}" -0 "10{superscript:0}");
# delimit cr

tabstat log10density


collapse (sum) obs potential=quality , by(qualityrank datastate incyear)
 
 
by datastate incyear (qualityrank), sort: gen dropme = _n == _N
drop if dropme
 
gsort datastate incyear -qualityrank
by datastate incyear: gen numabove = sum(obs)
by datastate incyear: egen total = sum(obs)
gen shareabove = numabove / total
 
  
scatter numabove qualityrank   if datastate == "CA" & incyear == 1998 , yscale(log) xscale(log) ylabel(1 10 100 1000 10000) xlabel( 1E-10 1E-8 1E-6 1E-4  1E-2) 


# delimit ;
  twoway 
	(scatter numabove qualityrank   if datastate == "CA" & incyear == 1998 , 
				yscale(log) xscale(log) ylabel(1 10 100 1000 10000) 
				xlabel( 1E-10 1E-8 1E-6 1E-4  1E-2) ) 
	(lfit numabove qualityrank   if datastate == "CA" & incyear == 1998 , 
				 ylabel(1 10 100 1000 10000) 
				xlabel( 1E-10 1E-8 1E-6 1E-4  1E-2) ) 
				;
# delimit cr



# delimit ;
  twoway 
	(scatter shareabove qualityrank   if datastate == "CA" & incyear == 1998 , 
				yscale(log) xscale(log) ylabel(1E-8 1E-6 1E-4  1E-2 1) 
				xlabel( 1E-10 1E-8 1E-6 1E-4  1E-2) ) ;
				;
# delimit cr


safedrop lq lnum
gen lq = log(qualityrank)
gen lnum = log(numabove)

gen lsh = log(shareabove)




# delimit ;
twoway (scatter lsh lq  if datastate == "CA" & incyear == 1995 ) 
	(scatter lsh lq  if datastate == "CA" & incyear == 2008 ) 
	(lfit lsh lq  if datastate == "CA" & incyear == 1995) 
	(lfit lsh lq  if datastate == "CA" & incyear == 2008 ),
	legend(label(1 "California 1995") label(2 "California 2008"));
# delimit cr



# delimit ;
twoway (scatter lsh lq  if datastate == "CA" & incyear == 1995 ) 
	(scatter lsh lq  if datastate == "CA" & incyear == 2008 ) 
	(lfit lsh lq  if datastate == "CA" & incyear == 1995) 
	(lfit lsh lq  if datastate == "CA" & incyear == 2008 ),
	legend(label(1 "California 1995") label(2 "California 2008"))
	 xtitle("quality") ytitle("share of firms above > quality")
	ylabel(-10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}" ) 
	xlabel(-20 "10{superscript:-20}" -15 "10{superscript:-15}"  -10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}") 
	;
# delimit cr




# delimit ;
twoway (scatter lsh lq  if datastate == "MA" & incyear == 1995 ) 
	(scatter lsh lq  if datastate == "MA" & incyear == 2008 ) 
	(lfit lsh lq  if datastate == "MA" & incyear == 1995) 
	(lfit lsh lq  if datastate == "MA" & incyear == 2008 ),
	legend(label(1 "Massachusetts 1995") label(2 "Massachusetts 2008")) xtitle("quality") ytitle("share of firms above > quality")
	ylabel(-10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}" ) 
	xlabel(-20 "10{superscript:-20}" -15 "10{superscript:-15}"  -10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}") 
	;
# delimit cr



# delimit ;
twoway (scatter lsh lq  if datastate == "CA" & incyear == 1995 ) 
	(scatter lsh lq  if datastate == "FL" & incyear == 2008 ) 
	(lfit lsh lq  if datastate == "CA" & incyear == 1995) 
	(lfit lsh lq  if datastate == "FL" & incyear == 2008 ),
	legend(label(1 "Florida 1995") label(2 "California 2008"))
	 xtitle("quality") ytitle("share of firms above > quality")
	ylabel(-10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}" ) 
	xlabel(-20 "10{superscript:-20}" -15 "10{superscript:-15}"  -10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}") 
	;
# delimit cr




postfile coefficients b using coefficients.dta , replace
levelsof datastate, local(states)
foreach state of local states { 
	forvalues y = 1995/2008 {
		di "`state' : `y'"
		qui:regress lsh lq if datastate == "`state'" & incyear == `y'
		post coefficients (_b[lq])
	}	
}
postclose coefficients

preserve
u coefficients , replace
tabstat  b , by(datastate)


preserve
collapse (sum)obs , by(qualityrank datastate)

gsort datastate  -qualityrank
by datastate : gen numabove = sum(obs)
by datastate : egen total = sum(obs)
gen shareabove = numabove / total
 

gen lq = log(qualityrank)
gen lnum = log(numabove)
gen lsh = log(shareabove)





# delimit ;
twoway (scatter lsh lq  if datastate == "CA" ) 
	(scatter lsh lq  if datastate == "FL" ) 
	(lfit lsh lq  if datastate == "CA") 
	(lfit lsh lq  if datastate == "FL"  ),
	legend(label(1 "California ") label(2 "Florida "))
	 xtitle("quality") ytitle("share of firms above > quality")
	ylabel(-10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}" ) 
	xlabel(-20 "10{superscript:-20}" -15 "10{superscript:-15}"  -10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}") 
	;
# delimit cr


# delimit ;
twoway (scatter lsh lq  if datastate == "CA" , msize(vsmall) ) 
	(scatter lsh lq  if datastate == "FL", msize(vsmall) ) 
	(scatter lsh lq  if datastate == "MA", msize(vsmall) ) 
	(scatter lsh lq  if datastate == "AK", msize(vsmall) ) 
	(scatter lsh lq  if datastate == "GA", msize(vsmall) ) 
	(scatter lsh lq  if datastate == "OR", msize(vsmall) ) 
	(scatter lsh lq  if datastate == "NY", msize(vsmall) ) ,
	legend(label(1 "California ") label(2 "Florida ") label(3 "Massachusetts") label(4 "Alaska") label(5 "Georgia") label(6 "Oregon")  label(7 "New York")) 
	 xtitle("quality") ytitle("share of firms above > quality")
	ylabel(-10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}" ) 
	xlabel(-20 "10{superscript:-20}" -15 "10{superscript:-15}"  -10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}") 
	
	title("Size Distribution per State");
# delimit cr





# delimit ;
twoway (lfit lsh lq  if datastate == "CA" ) 
	(lfit lsh lq  if datastate == "FL" ) 
	(lfit lsh lq  if datastate == "MA" ) 
	(lfit lsh lq  if datastate == "AK" ) 
	(lfit lsh lq  if datastate == "GA" ) 
	(lfit lsh lq  if datastate == "OR" ) 
	(lfit lsh lq  if datastate == "NY" ) ,
	legend(label(1 "California ") label(2 "Florida ") label(3 "Massachusetts") label(4 "Alaska") label(5 "Georgia") label(6 "Oregon")  label(7 "New York")) 
	 xtitle("quality") ytitle("share of firms above > quality")
	ylabel(-10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}" ) 
	xlabel(-20 "10{superscript:-20}" -15 "10{superscript:-15}"  -10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}") 
	title("Fitted line for size distribution per state")
	;
# delimit cr



restore 
preserve
collapse (sum)obs , by(qualityrank incyear)

gsort incyear  -qualityrank
by incyear : gen numabove = sum(obs)
by incyear : egen total = sum(obs)
gen shareabove = numabove / total
 

gen lq = log(qualityrank)
gen lnum = log(numabove)
gen lsh = log(shareabove)




# delimit ;
twoway (lfit lsh lq  if incyear == 1995 )  
	(lfit lsh lq  if incyear == 1998 )  
	(lfit lsh lq  if incyear == 2000 )  
	(lfit lsh lq  if incyear == 2003 )  
	(lfit lsh lq  if incyear == 2006 )  ,
	legend(label(1 "1995 ") label(2 "1998 ") label(3 "2000") label(4 "2003") label(5 "2006")) 
	 xtitle("quality") ytitle("share of firms above > quality")
	ylabel(-10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}" ) 
	xlabel(-20 "10{superscript:-20}" -15 "10{superscript:-15}"  -10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}") 
	title("Fitted line for size distribution per Year")
	;
# delimit cr


restore 
preserve
collapse (sum)obs , by(qualityrank )

gsort   -qualityrank
 gen numabove = sum(obs)
 egen total = sum(obs)
gen shareabove = numabove / total
 

gen lq = log(qualityrank)
gen lnum = log(numabove)
gen lsh = log(shareabove)




sum qualityrank, detail
gen ismiddle = qualityrank <= `r(p95)' & qualityrank >= `r(p5)'



# delimit ;
twoway (scatter lsh lq if shareabove < .90)  
	(lfit lsh lq  if shareabove < .90)   ,
	legend(off) 
	 xtitle("quality") ytitle("share of firms above > quality")
	ylabel(-15 "10{superscript:-15}" -10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}" 0 "100%") 
	xlabel(-30 "10{superscript:-30}" -20 "10{superscript:-20}"  -10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}") 
	title("Size distribution in the economy")
	note("Drops worst 10% of firms")
	;
# delimit cr



# delimit ;
twoway (scatter lsh lq if lq > -10)  
	(lfit lsh lq  if lq > -10)   ,
	legend(off) 
	 xtitle("quality") ytitle("share of firms above > quality")
	ylabel(-15 "10{superscript:-15}" -10 "10{superscript:-10}" -8 "10{superscript:-8}") 
	xlabel( -10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}") 
	title("Size distribution in the economy, good firms (P(growth) > 10{superscript:-10}")
	note("Drops worst 10% of firms")
	;
# delimit cr



# delimit ;
twoway (scatter lsh lq   )  
	(lfit lsh lq if q > 10E-30 & q <  10E-3, lwidth(thick) lcolor(green) )   ,
	legend(off) 
	 xtitle("quality") ytitle("share of firms above > quality")
	ylabel(-10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}" 1 ) 
	xlabel( -15 "10{superscript:-15}"  -10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}") 
	title("Size distribution in the economy")
	;
# delimit cr




keep if quality > 10E-15

# delimit ;
twoway (scatter lsh lq    )  
	(lfit lsh lq  )   ,
	legend(off) 
	 xtitle("quality") ytitle("share of firms above > quality")
	ylabel(-10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}" ) 
	xlabel(-20 "10{superscript:-20}" -15 "10{superscript:-15}"  -10 "10{superscript:-10}" -8 "10{superscript:-8}" -6 "10{superscript:-6}" -4 "10{superscript:-4}"  -2 "10{superscript:-2}") 
	title("Size distribution in the economy")
	;
# delimit cr




