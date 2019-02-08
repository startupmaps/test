 clear
 gen dataid = ""
 save ~/kauffman_neg/zipcode_dataid.dta, replace
 
 foreach state in /*CA*/ MA TX NY WA {
	u ~/final_datasets/`state'.dta, replace
	safedrop datastate 
	gen datastate = "`state'"
	
	keep dataid entityname datastate zipcode
	
	duplicates drop
	
	append using ~/kauffman_neg/zipcode_dataid.dta, force
	save ~/kauffman_neg/zipcode_dataid.dta, replace
 }
