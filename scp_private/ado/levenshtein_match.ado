
capture program drop levenshtein_match


program define corp_add_vc2,rclass
	syntax namelist(min=2 max=2), threshold(#)
	
	u `1'
	append using `2'
	
	
	
