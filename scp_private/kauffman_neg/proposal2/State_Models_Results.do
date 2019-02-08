cd ~/kauffman_neg
global datafile analysis15.collapsed.dta

*clear
* u $datafile
   
         # delimit ;
         local full_model_params is_corp
                         shortname eponymous
                        trademark patent_noDE nopatent_DE patent_and_DE 
                        clust_local  clust_resource_int clust_traded
                        is_biotech is_ecommerce is_IT is_medicaldev is_semicond  ib11.statecode
                        ;
         # delimit cr
   eststo clear
        safedrop qualitydiff  qualitytest
        gen qualitydiff = .
        gen qualitytest = .
safedrop rsort
gen rsort=runiform()
sort rsort
safedrop trainingsample
gen trainingsample = trainingyears & _n/_N <= .7
         display as text %12s "Statistics  num_growth mean sd skewness kurtosis p5 p95" 
**         foreach state in CA FL MA WA TX NY WY AK OR GA MI VT MI OK IA{
    keep if inlist(datastate,"MO","OK","ID")
    foreach state in MO OK  ID{
             di "Building State stats `state'"

             quietly {
                 sum growthz if trainingsample & datastate == "`state'"
                 local gn = `r(sum)'
                 if `gn' < 3 {
                     di "Skipping state `state'"
                     continue
                 }
                 
                 safedrop qualitytest`state'
                 eststo `state', title("`state'"): logit growthz `full_model_params' if trainingsample & datastate == "`state'", vce(robust) or
                 predict qualitytest`state' if datastate == "`state'" & !trainingsample
                 replace qualitytest = qualitytest`state' if datastate == "`state'" & !trainingsample
             }
         }

   pwcorr quality qualitytest* if !trainingsample & inrange(incyear,1988,2008)
   tabstat growthz , by(datastate) statistics(sum mean)
    tabstat growthz if trainingsample, by(datastate) statistics(sum mean)

      output_model using  ~/kauffman_neg/output/RegressionModel_by_state$output_suffix.csv




    eststo clear
    estpost tabstat obs quality qualitynow, by(datastate) statistics(count mean sd) columns(statistics) 
    esttab , cells("count mean sd")  noobs nomtitle nonumber eqlabels("`e(labels)'") 
    esttab using output/QualityStatistics_by_State$output_suffix.csv , cells("count mean sd")  noobs nomtitle nonumber eqlabels("`e(labels)'") replace


*cd ~/kauffman_neg
*u $datafile, replace

keep if trainingyears
by datastate, sort: egen totalgrowthz = sum(growthz)
keep if !trainingsample
drop if missing(quality)
by  datastate, sort: egen intestsamplegrowthz = sum(growthz)
by datastate (quality), sort: gen percentile = floor(_n/_N*20)/20
replace percentile = .95 if percentile == 1 
replace percentile = percentile * 100
recast  int percentile, force
gen top10growth = growthz if percentile >= 90
gen top5growth = growthz if percentile >= 95
collapse (sum) intestsamplegrowthz= growthz top10growth top5growth (max) totalgrowthz,by( datastate)
gen sharetop10 = top10/intestsample
gen sharetop5 = top5/intestsample
list, noobs clean
outsheet using output/PercentileQuality_ByState$output_suffix.csv, replace comma names 
