capture program drop mcoddsratio 

program define mcoddsratio, rclass
	syntax varlist [if], [use(string)] [LISTparams(string)] [info(string)]
	preserve
	
	if "`if'" != "" {
		qui keep `if'
	}
	
	if "`use'" != "" {
		use `use', replace
		di "File: `use'"
	}
	
	qui collapse (mean) mn=`1' (sd) sd=`1'
	 gen odds_ratio = exp(mn)
	gen odds_ratio_stderr=exp(mn)*sd
        gen odds_ratio_p = normprob((odds_ratio -1)/odds_ratio_stderr)
        replace odds_ratio_p = 1 - odds_ratio_p if odds_ratio_p > .5
        replace odds_ratio_p = odds_ratio_p * 2

	if "`info'" == "" { 
		list odds_ratio* , `listparams'
	}
	
	else{
		gen info= "--`info'--"
		list info odds_ratio*, `listparams'
	}
	
	restore
end
