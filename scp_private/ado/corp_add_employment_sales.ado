capture program drop corp_add_employment_sales

program define corp_add_employment_sales,rclass
	syntax namelist(min=1 max=1), DTApath(string) yearlag(integer)  varemployment(string) varsales(string) [STATEfileexists]  [skipcollapsed] [dropexisting]
 {

     local state `1'
     local statetemp ~/temp/`state'.infogroup.dta
     capture confirm file `statetemp'

     if _rc != 0 | "`statefileexists'" == "" {
         clear
         gen state = ""
         save `statetemp' , replace
         

         forvalues y=1997/2011 {
             clear
             u "~/projects/reap_proj/data_share/infogroup/infogroup_`y'.dta"

             keep if state == "`state'"
             keep if is_main_branch == 1
             keep empsiz salvol fileyear mfull_name match_type match_name match_collapsed

             gen employment =.

             // This is the min value of the range. Should be improved to
             // create a better dataset.
             // Maybe the geometric mean of the range can approximate to log-normal?
             
             replace employment = 1 if empsiz == "A"
             replace employment = 5 if empsiz == "B"
             replace employment = 10 if empsiz == "C"
             replace employment = 20 if empsiz == "D"
             replace employment = 50 if empsiz == "E"
             replace employment = 100 if empsiz == "F"
             replace employment = 250 if empsiz == "G"
             replace employment = 500 if empsiz == "H"
             replace employment = 1000 if empsiz == "I"
             replace employment = 5000 if empsiz == "J"
             replace employment = 10000 if empsiz == "K"

             gen sales = .

             // A is < 500K, choosing 100K for now
             replace sales =    100000 if salvol == "A"
             replace sales =    500000 if salvol == "B"
             replace sales =   1000000 if salvol == "C"
             replace sales =   2500000 if salvol == "D"
             replace sales =   5000000 if salvol == "E"
             replace sales =  10000000 if salvol == "F"
             replace sales =  20000000 if salvol == "G"
             replace sales =  50000000 if salvol == "H"
             replace sales = 100000000 if salvol == "I"
             replace sales = 500000000 if salvol == "J"
             replace sales =1000000000 if salvol == "K"

             //this is the match process
             gen incyear = fileyear - `yearlag'
             append using `statetemp'
             save `statetemp' , replace
             
         } //End of for loop to create temp file
     } // End of If statement
         
         
         
     //merge both files but also including the year of matching
     jnamemerge `statetemp' `dtapath' , extra(incyear)

     collapse (max) employment sales  , by(dataid)
     rename (employment sales) (`varemployment' `varsales')

     merge 1:m dataid using `dtapath'
     drop if _merge == 1
     drop _merge
     save `dtapath' , replace
         
     
 }
end

