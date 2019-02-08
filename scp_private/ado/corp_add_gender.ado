capture program drop corp_add_gender


program define corp_add_gender,rclass
	syntax, DTApath(string) NAMESpath(string) DIRectorspath(string) [ precision(integer 5) ]

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
	 
	 replace firstname = trim(itrim(upper(firstname)))
	 gsort -obs
	 merge 1:m firstname using `directorspath'
	 gen male = gender == "M"
	 gen female = gender == "F"
	 collapse (mean) male female, by(dataid)
	 merge 1:m dataid using `dtapath'
	 drop if _merge == 1
	 drop _merge
	 save `dtapath',replace
end
