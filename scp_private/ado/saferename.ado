capture program drop saferename
program define saferename,rclass

	capture confirm variable `1'

	if _rc == 0 {
	       rename `1' `2'
	}
	else {
	       di "var `1' not found"
	}
end
