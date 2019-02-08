**
*
* Summary:
*   Drops variables if they exist, does nothing if not 
*
*

capture confirm program drop safedrop

program define safedrop, rclass
	syntax anything, [onlyexisting] [Verbose]
        local params = substr("`0'",1, strpos("`0'", ","))

        if "`params'" == "" {
            local params `0'
        }

	foreach v in `params' {
            if strpos("`v'",",") >0 {
                continue
            }
            
		capture confirm variable `v' 
		
		if _rc == 0 {
                    
			drop `v'
			if "`verbose'" != ""{
				display "Dropping variable `v'", as text
			}
		}
		else{
			if "`onlyexisting'" == "" & "`verbose'" != ""{
				display "Variable `v' not dropped since it does not exist", as text
			}
		}
	}
end
