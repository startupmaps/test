capture program drop firstwordmerge

program define firstwordmerge,rclass
	syntax anything, [drop]
	
	if "`drop'" == "drop" {
		use `1' , replace
		safedrop _merge _mergex
		save `1' , replace
	
	
		use `2' , replace
		safedrop _merge _mergex
		save `2' , replace
	
	}
	
	use `1', replace
	replace match_firstword = string(runiform()) if length(match_firstword) < 3
	
	joinby match_firstword using `2', unmatched(master) _merge(_merge)
	gen _mergex = "first word" if _merge == 3
	replace _mergex = "no match" if missing(_mergex)
	tab _mergex 
end
