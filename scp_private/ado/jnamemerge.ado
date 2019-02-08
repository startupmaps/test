*  Summary:
*   ^namemerge^ does a matching of two different firm databases based on name.
*   The matching is a left join, keeping all observations from the first file
*   but only the matched ones from the second file. ^namemerge^ requires that  
*   ^tomname^ has already been run on both datasets and uses the parameters 
*   created by ^tomname^ to do the matching. It additionally allows the user
*   to add other parameters to the matching criteria.
*
*   Matching is done in the following order:
*       1. Match both match_name and match_type
*       2. Match only match_name
*       3. Match match_collapsed
*
*   Requires @tomanme@ and @safedrop@

* Parameters:
*   namelist   the list of the two .dta files to merge
*   extravar   matching can add extravariables besides the ones generated by tomname
*              which are then included in all matching (e.g. state)
*   tempfolder This script generates temp files through the merging. If the files
*               are very large another path might be preferred.
*
*
* Output:
*   _mergex contains the results from this merge, which can either be a match of:
*      name and type, name only, collapsed, or no match
*

capture program drop jnamemerge

program define jnamemerge,rclass
	syntax anything, [EXTRAvars(string)] [TEMPfolder(string)] [NOSAVE] [origlocal(string)] [both] [skipcollapsed] [nameandtypeonly]
	
	if "`extravars'" != "" {
		di "Matching also on secondary parameterss: `extravars'"
	}
	
	set more off
	
	
	if "`tempfolder'" == "" {
		local root_folder = "/NOBACKUP/scratch/share_scp/temp/"
	}
	else{
		local root_folder = "`tempfolder'"
	}
	
	
	local merge1 = "`root_folder'merge1.$mergetempsuffix.dta"
	local merge2 = "`root_folder'merge2.$mergetempsuffix.dta"
	
	capture confirm file `merge1'
	if _rc == 0{
		if "`safe'" == "safe"{
			di "Error. File `merge1' exists.", as error
			local _rc=1
			error `_rc'
		}
	
		di "File `merge1' exists. Dropping." 
		rm `merge1'
	}
	
	capture confirm file "`merge2'"
	if _rc == 0{
		if "`safe'" == "safe"{
			di "Error. File `merge2' exists.", as error
			local _rc=1
			error `_rc'
		}
		di "File `merge2' exists. Dropping."
		rm `merge2'
	}

	/* Load the first file */
	use `1',replace
	saferename mfull_leftname mfull_name

	qui:compress
	
	foreach v of varlist match_name match_collapsed {
		replace `v' = string(runiform()) if length(`v') == 0
	}
	
	
	/* This is temporary change used to compare the full names
	   of the left and right files. It is later undone. */
	rename mfull_name mfull_leftname
	
	if "`safe'" == "safe"{
		foreach v on _merge _mergex {
			capture confirm var `v'
			if _rc == 0 {
				di "Error. Variable `v' exists.", as error
				local _rc=1
				error `_rc'
			}
		}
	}
	
	safedrop _merge _mergex

	/* Get the list of all vars in the left dataset so that we 
	 * only keep those after we do merge operations
	 */
	local originalvars   = ""
	foreach var of varlist _all {
		local originalvars = "`originalvars' `var'"  
	}

	keep `originalvars'
	
	/* Merge by name and type
	 */
	joinby match_name match_type `extravars' using `2', unmatched(master)
	
	/* This program uses the file merge1.dta to keep all observations 
	 * that have not been matched and file merge2.dta to keep those that already have a match.	
	 */
	drop if _merge == 2
	save `merge1',replace
	keep if _merge ==3
	gen _mergex = "name and type"
	save `merge2',replace


        /* If parameter `nameandtypeonly' is set, merge only through name and type together.
         */
        if "`nameandtypeonly'" == "" {
            use `merge1',replace
            *only the left observations that do not have a match
            keep if _merge == 1 
            keep `originalvars'

            /* Merge by name only
             */
            joinby  match_name `extravars'  using `2', unmatched(master)
            rename mfull_name mfull_rightname
            drop if _merge == 2

            /* Drops cases where two firms have almost the same name but one is a corporation and the 
             * other one an LLC. This is not uncommon. 
             */
            replace _merge = 1 if strpos(mfull_rightname," LLC") >0 & (strpos(mfull_leftname," INCORPORATED") > 0 | strpos(mfull_leftname," CORPORATION") > 0)
            replace _merge = 1 if strpos(mfull_leftname," LLC") >0 & (strpos(mfull_rightname," INCORPORATED") > 0 | strpos(mfull_rightname," CORPORATION") > 0)

            save `merge1',replace
            keep if _merge == 3 
            gen _mergex = "only name" 
            append using `merge2' //add to the previously matched observations
            save `merge2',replace //and store them 



            use `merge1',replace
            keep if _merge == 1
            keep `originalvars'
            joinby  match_collapsed `extravars'  using `2', unmatched(both)

            if "`both'" == "" {
                    keep if _merge == 3 | _merge == 1
            }

            gen _mergex = "collapsed name" if _merge == 3

        } /*End if "`nameandtypeonly'" clause */

            
	replace _mergex = "no match" if _merge == 1
	replace _mergex = "no match (rightfile)" if _merge == 2
	append using `merge2'

	safedrop mfull_rightname
	safedrop mfull_name

	rename mfull_leftname mfull_name


	//Drop the temp file
	rm `merge1'
	rm `merge2'
	
	if "`origlocal'" != "" {
		c_local `origlocal' = "`originalvars'"
	}

	tab _mergex
end

