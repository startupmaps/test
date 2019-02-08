program define clearmerge, rclass
	clear
	u `1'
	drop _merge
	save `1', replace

end
