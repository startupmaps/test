/*  Tim Simcoe : this version 12/9/2011; Updated 9/21/2015 */
/*  A utility for creating tabular output from many T-tests  */

program define ttable, eclass byable(recall) sort
version 8.0

syntax varlist(numeric) [if] [in], [BY(varname) Pval UNEqual Welch HOTelling]
marksample touse

quietly {	
	noi di

	if ("`pval'"!="") {
		noi disp %-15s "", %-11s "`by'=0", %-11s "`by'=1", %-11s "P-val",  %-11s "Norm. Diff."
	}
	else {
		noi disp %-15s "", %-11s "`by'=0", %-11s "`by'=1", %-11s "T-stat",  %-11s "Norm. Diff." 
	}

	foreach X in `varlist' {
		ttest `X' if `touse', by(`by') `unequal' `welch'
		local delx = abs(r(mu_1) - r(mu_2)) / sqrt(r(sd_1)^2 + r(sd_2)^2)
		
		if ("`pval'"!="") {
			noi display %-15s "`X'", %9.2f r(mu_1), %9.2f r(mu_2), %9.2f r(p), %9.2f `delx'
		}
		else {
			noi display %-15s "`X'", %9.2f r(mu_1), %9.2f r(mu_2), %9.2f abs(r(t)), %9.2f `delx'
		}
	}

	noi display %-15s "Obs.", %9.0f r(N_1), %9.0f r(N_2), %9.2f

	if ("`hotelling'"!="") {
		hotelling `varlist' if `touse', by(`by')

		local farg = r(T2)*(r(N)-r(k)-1)/((r(N)-2)*r(k))
		local pval = fprob(r(k),r(df),`farg')

		noi di		
		noi di in gr "H0: Vectors of means are equal for the two groups"
		noi di in gr _col(10) "     F(" in ye r(k) in gr "," /* 
		*/ in ye r(df) /*
		*/ in gr ") = " in ye %9.4f `farg'
		noi di in gr _col(8) "Prob > F(" in ye r(k) in gr "," /*
		*/ in ye r(df) in gr ") = " in ye %9.4f `pval'
	}		
}

end
