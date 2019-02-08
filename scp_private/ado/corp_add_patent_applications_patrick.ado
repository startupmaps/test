
capture program drop corp_add_patent_applications

program define corp_add_patent_applications,rclass
	syntax namelist(min=2 max=3), DTApath(string) [NOSave] PATpath(string) [frommonths(integer 0)] [tomonths(integer 12)] var(string) [STATEfileexists] [aroundyear(string)]  [skipcollapsed] EXAMINERdta(string)


	local state="`1'" 
	local longstate=trim("`2' `3'")
	

	capture confirm file ~/temp/`state'.patentapp.dta

	if "`statefileexists'" == "" | _rc != 0 {
		clear
		u `patpath',replace
		keep if inlist(state,"","`state'")
		tomname assignee
		safedrop _merge _mergex
		desc
		save ~/temp/`state'.patentapp.dta,replace
	}
	
	jnamemerge   ~/temp/`state'.patentapp.dta `dtapath' ,  `skipcollapsed'

	drop if _mergex == "no match"
	safedrop _merge _mergex
	
	rename patent_doc_id patentid
	
	merge m:1 patentid using ~/angellist/patents_patrick12_withexaminers.dta
	drop if _merge == 2
	


	safedrop arounddate
	if "`aroundyear'" == "" {
		gen arounddate = incdate
	}
	else {
		gen arounddate = date("1/1/`aroundyear'", "MDY")
	}
	

	rename applicationdate patent_application_date
	gen diffdays = (patent_application_date - arounddate)
	gen `var' = inrange(diffdays,`frommonths'/12*365,`tomonths'/12*365) 


	gen examinerscore_application = **Add Here
	gen numpatents_application = 1
	
	collapse (sum) `var' numpatents_application (mean) examinerscore_application, by(dataid)

	merge 1:m dataid using  `dtapath'
	drop _merge 
	if "`nosave'" == "" {
		save  `dtapath',replace 
	}
end
