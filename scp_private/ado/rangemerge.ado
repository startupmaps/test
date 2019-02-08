capture program drop rangemerge 
program define rangemerge, rclass
	syntax varname using , start(name) end(name) val(name)
{
	preserve
	clear
	use `using'
	local startingpoints
	local endingpoints
	
	levelsof `val', local(valuepoints)
	
	local n: word count `valuepoints' 
	forvalues i=1/`n'{
                local xs = `start'[`i']
		local startingpoints `startingpoints' `xs'
                local xe = `end'[`i']
		local endingpoints `endingpoints' `xe'
	}
	
	clear
	restore
	
	capture confirm variable `val'
	if _rc == 0 { 
		drop `val'
	}
	qui: gen `val' = .
	
	local n: word count `valuepoints'
	forvalues i=1/`n' { 
		di "merging word `i' of `n'"
		local s: word `i' of `startingpoints'
		local e: word `i' of `endingpoints'
		local v: word `i' of `valuepoints'
		
		qui: replace `val' = `v' if inrange(`1',`s',`e')
	}
}
end
