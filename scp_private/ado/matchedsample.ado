
capture program drop matchedsample

program define matchedsample, rclass
	syntax varlist [if] , samplevar(string) [matchvar(string)] [matchofvar(string)] [inanalysis(string)] [ITERations(integer 20)] [dropexisting] [stringdataid] [record(string)] [matchrequire(string)]
	
	
	if "`matchvar'" == "" local matchvar="match"
	if "`matchofvar'" == "" local matchofvar="matchof"
	if "`inanalysis'" == "" local inanalysis ="inanalysis"
	

        if "`matchrequire'" != "" {
            local matchrequire & `matchrequire'
            
            local matchrequire_m1 `matchrequire'[_n+1]
        }

**** Create Matched dataset: incyear and stategrowth
	* This is EXACT matching, not coarsened in any way
	if "`dropexisting'" == "dropexisting" {
		safedrop `inanalysis' `matchvar' `matchofvar'
	}
	
	local matchcriteria = ""
	foreach v of varlist `varlist'  {
		local matchcriteria = "`matchcriteria' & `v'[_n] == `v'[_n-1] "
	}
	
	
	if "`stringdataid'" == "" {
		gen `matchvar' = .
		gen `matchofvar' = .
	}
	else {
		gen `matchvar' = ""
		gen `matchofvar' = ""
	}
	
	local ifx = "if"
	if "`if'" != "" {
		local ifx = "`if' & "
	}
	
	
	
	forvalues i=1/`iterations' {
		
	
		qui: safedrop rsort
		gen rsort = runiform()
		gsort `varlist' rsort
		di "Iteration: `i'"
		# delimit ;
		replace `matchofvar' = dataid[_n-1] 
			`ifx'
                        `samplevar'[_n]==0   & `samplevar'[_n-1]==1
                        & missing(`matchvar'[_n-1])	
			`matchcriteria'
                         `matchrequire'
			& missing(`matchofvar')			
			;
			
		
			
		replace `matchvar' = dataid[_n+1] 
			`ifx'
			 `matchofvar'[_n+1] == dataid
 		         `matchrequire_m1'
			& missing(`matchvar')				
			;
			
		# delimit cr
			
	}

	
	gen `inanalysis' = !missing(`matchvar') | !missing(`matchofvar')
	
	
	tabstat `varlist' if `inanalysis' , by(`samplevar') stats(N mean sd)
end
