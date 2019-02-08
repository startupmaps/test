/*
 * Initially Created: Februrary 13, 2017
 * This file analyzes the right threshold at which data can be summarized without having
 * extreme outliers
 *
 * The algorithm seeks to not have a REAI higher than 3. 
 *    Since the value of REAI is bounded from below at 0. 
 */


cd ~/kauffman_neg/

/** Create a file containing the name of all counties **/
	/*
	clear
	import delimited stateabbr statecode countycode countyname countytype using RJ/national_county.txt , delim(",")
	gen county = statecode*1000 + countycode
	save RJ/counties.dta , replace
	 */
 
    
clear
/*
u analysis34.minimal.dta
keep if incyear <= 2008
collapse (sum) growthz recpi=quality, by(zipcode incyear)
gen reai = growthz/recpi
*/

/*
 * REAI by county
 */

/** Create a file with stats for all counties **/ 

/*
	clear
	u analysis34.minimal.dta
	keep if incyear <= 2008
	safedrop _merge
	merge m:m zipcode using county_zipcode.dta
	keep if _merge == 3
	replace growthz = growthz * bus_ratio
	safedrop obs
	gen obs = bus_ratio
	collapse (sum) obs growthz (mean) quality , by(county incyear)
	gen reai = growthz/ (obs * quality)
	sort reai
	merge m:1 county using RJ/counties.dta
	drop if _merge == 2
	save RJ/counties_reai.dta , replace
*/

/** Record the performance of different thresholds **/


    local threshold_year 2003
    local aggregate 1
	clear
	u RJ/counties_reai.dta , replace

        if "`threshold_year'" != "" {
            keep if incyear >= `threshold_year'

        }

	capture postclose reai_thresholds
	postfile reai_thresholds obs_threshold num_counties firms_in_sample avg_reai  share_over_2 share_over_3 share_over_4 share_over_5 share_over_6 using RJ/reai_thresholds.dta , replace every(1) 

       if "`aggregate'" == "1" {
           by county, sort: egen totfirms = sum(obs)
           gen weight = obs/totfirms
           gen wreai = reai*weight
           collapse (sum) reai=wreai obs , by(county)
       }

	gen county_count= 1
	foreach tr in 10000 9000 8000 5000 3000 2000 1000 500 300 200 100 60 50 30 10 1 {

	    di "Estimating stats for obs_thresholds == `tr'"
	    quietly {
		sum county_count if obs >= `tr'
		local num_counties `r(sum)'

		sum reai if obs >= `tr'
		local avg_reai `r(mean)'

		sum obs if obs >= `tr'
		local firms_in_sample `r(sum)'

		sum county_count if obs >= `tr' & reai > 2
		local share_over_2 = `r(sum)'/`num_counties'

		sum county_count if obs >= `tr' & reai > 3
		local share_over_3 = `r(sum)'/`num_counties'

		sum county_count if obs >= `tr' & reai > 4
		local share_over_4 = `r(sum)'/`num_counties'
	    
		sum county_count if obs >= `tr' & reai > 5
		local share_over_5 = `r(sum)'/`num_counties'
	    
		sum county_count if obs >= `tr' & reai > 6
		local share_over_6 = `r(sum)'/`num_counties'
	    }

	    post reai_thresholds (`tr') (`num_counties') (`firms_in_sample') (`avg_reai') (`share_over_2') (`share_over_3') (`share_over_4') (`share_over_5') (`share_over_6')

	    di "    --> post reai_thresholds (`tr') (`num_counties') (`firms_in_sample') ( (`avg_reai') (`share_over_2') (`share_over_3') (`share_over_4') (`share_over_5') (`share_over_6')"
	}

	postclose reai_thresholds

	clear 
	u RJ/reai_thresholds
	egen tot_firms = max(firms_in_sample)
	gen share_firms = firms_in_sample / tot_firms
	
	egen tot_counties = max(num_counties)
	gen share_counties = num_counties/tot_counties

	save RJ/reai_thresholds.dta , replace


/** 
 *
 * A full sample
 */

     local collapse_suffix
     if "`aggregate'" == "1" {
         local collapse_suffix .aggregated
     }
	# delimit ;
	outsheet obs_threshold num_counties share_counties share_firms avg_reai share_over_2 share_over_3 share_over_4 share_over_5 share_over_6
		using output/RJ/reai_threshold_share`threshold_year'`collapse_suffix'.csv , replace comma names
		;
	# delimit cr
