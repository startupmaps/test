capture program drop tomname

program define tomname, rclass
	set trace off
	version 9.1
	syntax varname,[COMMAsplit] [DROPexisting] [firstword]

	/* If the necessary variables already exist then:
		- If the dropexisting parameter is provided the program drops them
		- Else the program fails with error
	*/	
	if "`dropexisting'"  == "dropexisting" {
		 safedrop mfull_name match_name match_type match_collapsed match_firstword
	}
	else{
		foreach v in mfull_name match_name match_type match_collapsed {
			capture confirm variable `v' 
			if _rc == 0 {
				local _rc = 1
				di "Error: Variable `v' already exists. Use parameter dropexisting if you wish to delete", as error
				error `_rc'
			}
		}
	}
	 
	
	di "Generating matching name variables", as text
	
	/* Generate variable mfull_name which will hold the full name of the firm */
	gen mfull_name = `1'	
	qui: replace mfull_name = itrim(upper(mfull_name))

	/*  Replace a long set of word abbreviations by their unabbreviated counterparts 
		All the replace commands run twice to account for the unlikely case that a phrase appears twice
	*/
	qui: replace mfull_name = regexs(1) + regexs(2) + "CENTER" + regexs(4) if regexm(mfull_name,"(^.*)([^A-Z])(CTR)([^A-Z].*$)")
	qui: replace mfull_name = regexs(1) + regexs(2) + "SERVICES" + regexs(4) if regexm(mfull_name,"(^.*)([^A-Z])(SVC)([^A-Z].*$)")
	qui: replace mfull_name = regexs(1) + regexs(2) + "COMPANY" + regexs(4) if regexm(mfull_name,"(^.*)([^A-Z])(CO)([^A-Z].*$)")
	qui: replace mfull_name = regexs(1) + regexs(2) + "INCORPORATED" + regexs(4) if regexm(mfull_name,"(^.*)([^A-Z])(INC)([^A-Z].*$)")
	qui: replace mfull_name = regexs(1) + regexs(2) + "CORPORATION" + regexs(4) if regexm(mfull_name,"(^.*)([^A-Z])(CORP)([^A-Z].*$)")
	qui: replace mfull_name = regexs(1) + regexs(2) + "UNIVERSITY" + regexs(4) if regexm(mfull_name,"(^.*)([^A-Z])(UNIV)([^A-Z].*$)")
	qui: replace mfull_name = regexs(1) + regexs(2) + "DEPARTMENT" + regexs(4) if regexm(mfull_name,"(^.*)([^A-Z])(DEPT)([^A-Z].*$)")
	qui: replace mfull_name = regexs(1) + regexs(2) + "CENTER" + regexs(4) if regexm(mfull_name,"(^.*)([^A-Z])(CTR)($)")
	qui: replace mfull_name = regexs(1) + regexs(2) + "SERVICES" + regexs(4) if regexm(mfull_name,"(^.*)([^A-Z])(SVC)($)")
	qui: replace mfull_name = regexs(1) + regexs(2) + "COMPANY" + regexs(4) if regexm(mfull_name,"(^.*)([^A-Z])(CO)($)")
	qui: replace mfull_name = regexs(1) + regexs(2) + "INCORPORATED" + regexs(4) if regexm(mfull_name,"(^.*)([^A-Z])(INC)($)")
	qui: replace mfull_name = regexs(1) + regexs(2) + "CORPORATION" + regexs(4) if regexm(mfull_name,"(^.*)([^A-Z])(CORP)($)")
	qui: replace mfull_name = regexs(1) + regexs(2) + "UNIVERSITY" + regexs(4) if regexm(mfull_name,"(^.*)([^A-Z])(UNIV)($)")
	qui: replace mfull_name = regexs(1) + regexs(2) + "DEPARTMENT" + regexs(4) if regexm(mfull_name,"(^.*)([^A-Z])(DEPT)($)")
	qui: replace mfull_name = subinstr(mfull_name,"LIMITED LIABILITY COMPANY","LLC",.)
	qui: replace mfull_name = regexr(mfull_name," ASSOCIATE( |$)"," ASSOCIATES ")
	
	/* Remove special characters */	
	qui: replace mfull_name = subinstr(mfull_name,"."," ",.)
	qui: replace mfull_name = subinstr(mfull_name,","," ",.)
	qui: replace mfull_name = subinstr(mfull_name,"|","",.)
	qui: replace mfull_name = subinstr(mfull_name,"'","",.)
	qui: replace mfull_name = subinstr(mfull_name,`"""',"",.)
	qui: replace mfull_name = subinstr(mfull_name,"-"," ",.)
	qui: replace mfull_name = subinstr(mfull_name,"@","",.)
	qui: replace mfull_name = subinstr(mfull_name,"_","",.)
	
	/* Remove the word "the" if it's at the start of the word */
	qui: replace mfull_name = regexr(mfull_name,"^THE ","")
	
	/* Trims */
	qui: replace mfull_name = trim(itrim(mfull_name))
	
	
	/* match_type holds the type of firm */
	qui: gen match_type = regexs(1) if regexm(mfull_name,"[ ](CORPORATION|INCORPORATED|COMPANY|LLC)")

	/*  Remove the information after the first comma if the parameter commasplit is passed. 
		This is useful for parsing patent information, where the assignee name might also hold company information
		e.g. "INNOVATIVE FIRM INC, A COMPANY OF DELAWARE" 
	*/
	if ("`commasplit'" == "commasplit"){
		qui: gen match_name = substr(mfull_name,1,strpos(mfull_name,",")-1) if missing(match_type) & strpos(mfull_name,",")
		qui: replace match_name = mfull_name if missing(match_type) & strpos(mfull_name,",") == 0
	}
	else{
		qui: gen match_name = mfull_name if missing(match_type) 
	}
	
	/* Match name holds the name without the type */
	qui: replace match_name = substr(mfull_name,1,strpos(mfull_name,match_type)-1) if !missing(match_type)  


	/* In case we left a comma and do a new full trim to make final */
	qui: replace match_name = itrim(subinstr(match_name,",","",.))
	qui: replace match_name = trim(match_name)
	qui: replace match_type = trim(itrim(match_type))

	
	qui: gen match_collapsed = subinstr(mfull_name," ","",.)
	di "Name matching variables mfull_name match_name match_type match_collapsed  generated from variable `1'"



	if "`firstword'" == "firstword" {
		qui: split mfull_name, limit(1)
		rename mfull_name1 match_firstword
	}
	local _rc = 0

end
