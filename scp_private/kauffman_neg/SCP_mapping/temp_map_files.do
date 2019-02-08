global statelist NC  MI

clear
u analysis34.minimal.dta

safedrop obs
gen obs = 1

replace city = trim(itrim(upper(city)))
collapse (sum) obs , by(city datastate)
keep if obs > 50

gen good_state = 0
foreach state in $statelist {
    replace good_state = 1 if datastate == "`state'"   
}


keep if good_state

gen add = city + ", " + datastate + ". USA"
gen id = _n
gen blank = " "
append using map_cities.dta
save map_cities.dta , replace


outsheet id blank add using ~/kauffman_neg/RJ/geocode/infile3.txt , replace
erase ~/kauffman_neg/RJ/geocode/outfile.txt




do program.Create_Map_Files.do
foreach state in $statelist {
    build_city_map_file `state' , usetext(~/kauffman_neg/RJ/geocode/outfile.txt)

}
