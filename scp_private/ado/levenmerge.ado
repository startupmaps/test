capture program drop levenmerge

program define levenmerge,rclass
	syntax anything
	
	use `1', replace
	saferename match_type match_type_left
	saferename match_name match_name_left
	saferename match_collapsed match_collapsed_left
	saferename mfull_name mfull_name_left


	replace match_firstword = string(runiform()) if length(match_firstword) < 3
	
	joinby match_firstword using `2', unmatched(master) _merge(_merge)
	gen _mergex = "first word" if _merge == 3
end
