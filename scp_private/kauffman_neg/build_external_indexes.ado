
/**
 ** This file builds external indexes that are used by all programs.
 **/



program define build_external_indexes, rclass
       syntax , [skipstates(string)] [datafile(string)]
{
    if "`datafile'" == "" {
        local datafile $datafile
    }

    /* the list of all states */
      clear
      u `datafile'
      levelsof datastate, local(states_in_sample)
      
    /* Add statecodes */
      clear
      import delimited using state_fips_code.csv, delim(",") varnames(1)
      keep statename stateabbr fipscode
      save statecodes.dta, replace

    /* Add the BDS number of births */
      clear
      import delimited using bds_f_agest_release.csv, delim(",") varnames(1)
      keep if fage == "a) 0"
      rename state fipscode
      rename firms firmbirthsbds
      rename year2 year
      keep fipscode firmbirthsbds year 
      merge m:1 fipscode using statecodes.dta
      keep if _merge == 3
      drop _merge
      save state_external.dta, replace

      /* Add Reallocation Rate */
      clear
      import delimited using bds_f_st_release.csv, delim(",") varnames(1)
      rename state fipscode
      rename year2 year
      keep fipscode reallocation_rate year 
      merge 1:1 fipscode year using state_external.dta
      keep if _merge == 3
      drop _merge
      save state_external.dta, replace


    /* Add State GDP from 1997 to 2014 */
      clear 
      import delimited using "/projects/reap.proj/raw_data/gsp_naics_all_R.csv", delim(",") varnames(1)

      keep if industryid == 1
      forvalues i=9/26 {
          local year=`i' - 9 + 1997
          rename v`i' gsp`year'
      }
      gen fipscode = substr(geofips,1,2)
      destring fipscode, replace
      keep gsp* fipscode geoname 
      reshape long gsp, i(fipscode) j(year)
      gen gspyear = 2009
      destring gsp, replace
      save GSP.dta, replace

    /* Add State GDP from 1988 to 1996 */
      clear 
      import delimited using "/projects/reap.proj/raw_data/gsp_sic_all_R.csv", delim(",") varnames(1)

      keep if industryid == 1
      forvalues i=9/43 {
          local year=`i' - 9 + 1963
          rename v`i' gsp`year'
      }
      gen fipscode = substr(geofips,1,2)
      destring fipscode, replace
      keep gsp* fipscode geoname 
      reshape long gsp, i(fipscode) j(year)
      gen gspyear = 1997
      replace  gsp = "" if gsp == "(NA)"
      destring gsp, replace
      append using  GSP.dta
      save GSP.dta, replace

      by fipscode year (gspyear), sort: gen adjustment_2009gdp = gsp[_n+1]/gsp if fipscode == 0
      egen adj = max(adjustment_2009gdp)
      replace gsp = gsp* adj if gspyear == 1997
      drop if gspyear == 1997 & year == 1997
      drop adj*
      save GSP.dta, replace

      merge m:1 fipscode using statecodes.dta
      keep if _merge == 3
      drop _merge
      save GSP.dta, replace


    /* Keep only the states for which we are doing our analysis */
        clear
      u GSP.dta 
      merge 1:1 fipscode year using state_external.dta

      drop if _merge == 1 & year < 2013
      drop _merge

      
      gen insample =0
      foreach st in `states_in_sample' {
          replace insample = 1 if stateabbr == "`st'"
      }
      

    if "`skipstates'" != "" {
        foreach state in `skipstates' {
            di "Skipping state in external indexes: `state'"
            drop if stateabbr == "`state'"
        }
    }


      by year insample, sort: egen samplegsp = sum(gsp)
      by year insample, sort: egen samplebdsbirths = sum(firmbirthsbds)
      replace samplegsp =. if !insample
      replace samplebdsbirths =. if !insample

      save external_data.dta, replace


      u external_data.dta, replace
      drop if !insample
      keep year samplegsp samplebdsbirths
      duplicates drop
      sort year
      /*Create GDP of 2015 = GDP 2014 + 2% Growth */
      local obs_plus_1 = _N+1
      set obs `obs_plus_1'
      replace  year = 2015 if _n==_N
      replace  samplegsp = samplegsp[_n-1]*1.02 if _n==_N
      save external_data_yearly.dta, replace




      /*MSA Results*/
      clear
      import delimited using /projects/reap.proj/raw_data/zcta_cbsa_rel_10.txt, delim(",") varnames(1)
      keep zcta cbsa memi
      keep if memi == 1
      rename (zcta cbsa) (zipcode msacode)
      save zipcode_to_msa.dta, replace

      clear
      import delimited using /projects/reap.proj/raw_data/Gross_MSA_Product_allMSA.csv, delim(",") varnames(1)

      local startyear = 2001

      forvalues i=9/21 {
          rename v`i' msagdp`startyear'
          local startyear = `startyear' + 1
      }
      keep if description  == "All industry total"
      keep if componentname == "GDP by Metropolitan Area (millions of current dollars)"
      destring geofips, replace
      rename geofips msacode
      rename geoname msaname
      reshape long msagdp, i(msacode) j(year)
      save msagdp.dta, replace


      clear
      import delimited using /projects/reap.proj/raw_data/zip07_cbsa06.txt, delim(",") varnames(1)
      keep zip5 state countyname
      rename zip5 zipcode
      tostring zipcode, replace
      duplicates drop
      save ~/kauffman_neg/zipcode_to_county.dta,replace
  }
end

