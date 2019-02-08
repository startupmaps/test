capture program drop gender


program define gender,rclass
	syntax varlist, gen(string) NAMESpath(string) [ precision(integer 5) ]

	tempfile tomatchdata
	safedrop _merge 
	save `tomatchdata',replace

	clear
	 insheet firstname gender obs using `namespath', comma  
	 collapse (sum) obs, by(firstname gender)
	 
	 by gender,sort:egen tot = sum(obs)
	 sort firstname gender
	 by firstname (gender):egen both = sum(1)
	 gen share = obs/tot
	 
	 gen clean_gender = both ==1
	 by firstname (share) ,sort: replace clean_gender = 1 if (both == 2 & share[_n-1] < share[_n]*`precision')
	 keep if clean_gender
	 
	 keep firstname gender
	 replace firstname = trim(itrim(upper(firstname)))

	 rename (firstname gender) (`1' `gen')
	 qui: merge 1:m `1' using `tomatchdata'
	 drop if _merge ==1
	 drop _merge 
	tab `gen',missing
end
