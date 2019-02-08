u analysis34.minimal.dta,clear
keep datastate city
replace city = subinstr(city,","," ",.)
replace city = subinstr(city,"-"," ",.)
replace city = subinstr(city,"."," ",.)

replace city = strtrim(stritrim(strupper(city)))

gen id = 1
collapse (sum) id, by(city datastate)
drop if city == ""
drop if strpos(city, "*")
drop if strpos(city, "#")
drop if strpos(city, "&")
drop if strpos(city, "(")
drop if strpos(city, ")")
drop if strpos(city, "'")
drop if strpos(city, "/")
drop if strpos(city, ":")
drop if strpos(city, "`")
drop if strpos(city, ";")
drop if strpos(city, "@")
drop if strpos(city, "?")
drop if strpos(city, "!")
drop if strpos(city, "0")
drop if strpos(city, "1")
drop if strpos(city, "2")
drop if strpos(city, "3")
drop if strpos(city, "4")
drop if strpos(city, "5")
drop if strpos(city, "6")
drop if strpos(city, "7")
drop if strpos(city, "8")
drop if strpos(city, "9")
drop if id < 10

save cityname.dta
outsheet cityname.csv,comma
