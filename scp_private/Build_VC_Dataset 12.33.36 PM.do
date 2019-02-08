

/*
clear
import delimited using /projects/reap.proj/raw_data/VentureCapital/VC_1950_1995.csv , delim("|") varnames(1)
keep companyname companystateregion firstinvestmentdate
gen firstvc = date(firstinvestmentdate, "MDY")
tomname companyname
append using ~/final_datasets/VC.investors.dta
save ~/final_datasets/VC.investors.1950_2014.dta, replace


*/

clear
gen firstvc=.
save ~/temp/VCvaluations.dta, replace

foreach file in first_round_VC.1995-2010.txt first_round_VC.2010-2015.txt {
    clear
    import delimited using /projects/reap.proj/raw_data/VentureCapital/`file', delim(tab) varnames(1)

    keep companyname nooffirmsintotal  sumofequityinvestedintotalusdmil   sumofdealvalueintotalusdmil companystateregion firstinvestmentreceiveddate firmname


    rename nooffirmsintotal numvcfirms
    rename sumofequityinvestedintotalusdmil vcequityinvested
    rename sumofdealvalueintotalusdmil vcdealvalue
    rename  firstinvestmentreceiveddate firstvcstr
    gen firstvc = date(firstvcstr,"MDY")
    format firstvc %d

    replace vcdealvalue = regexr(vcdealvalue,"[^0-9\.]","")
    replace vcequityinvested = regexr(vcequityinvested,"[^0-9\.]","")

    destring vcdealvalue, replace
    destring vcequityinvested, replace
   
    drop firstvcstr
    drop if companyname == ""
    drop if firstvc == .
    append using  ~/temp/VCvaluations.dta
    save ~/temp/VCvaluations.dta, replace
}



merge 1:1 companyname firstvc using ~/final_datasets/VC.investors.dta
drop if _merge == 1
drop _merge
safedrop firmname
save ~/final_datasets/VC.investors.withequity.dta, replace




clear
import delimited using "/projects/reap.proj/raw_data/VentureCapital/VC Quality Scores.txt", delim(tab) varnames(1)
tomname vcfirmname
save ~/temp/VCQuality.dta, replace

clear
u ~/temp/VCvaluations.dta
keep companyname firstvc firmname
split firmname, parse(",")
drop firmname
reshape long firmname, i(companyname firstvc) j(firmnum)

drop if firmname == ""
tomname firmname
save ~/temp/VC.Investorsset.dta, replace

jnamemerge  ~/temp/VC.Investorsset.dta ~/temp/VCQuality.dta
drop if _mergex == "no match"

replace average = regexr(average,"[^0-9\.]","")
drop if average == "DIV/0!"
destring average, replace
by firmname, sort: egen max_vcscore = max(average)
drop if max_vcscore == .
gsort -max_vcscore
by companyname firstvc, sort: gen leadvc = firmname if _n == 1
keep if leadvc != ""
encode leadvc, gen(leadvc_FE)
keep companyname firstvc leadvc leadvc_FE
merge 1:1 companyname firstvc using ~/final_datasets/VC.investors.withequity.dta
drop if _merge == 1
drop _merge
save ~/final_datasets/VC.investors.withequity.dta, replace
