
/**
 to make ZIP_CBSA.dta, do:

 clear
 import delimited using "~/ado/zip07_cbsa06.txt", varnames(1) delim(",")  stringcols(1)
 keep if cbsalsad == "Metropolitan Statistical Area"
 keep zip5 cbsacode cbsatitle
 rename (cbsacode cbsatitle) (cbsa area)
 rename zip5 zip
 replace area = subinstr(area,"(Metropolitan Statistical Area)","MSA",.)
 duplicates drop

save ~/ado/ZIP_CBSA.ado ,replace
 **/



capture program drop add_cbsa
program define add_cbsa , rclass
      syntax , zipcode(string) [dropexisting]
{
    if "`dropexisting'" == "dropexisting" {
        capture  drop cbsa
        capture  drop area
    }
    
    capture gen zip = `zipcode'
    if _rc != 0 {
        drop zip
        gen zip = `zipcode'
    }
    
    joinby zip using ~/ado/ZIP_CBSA.dta , unmatch(both)
    tab _merge
    drop if _merge == 2
    drop _merge

}
end
