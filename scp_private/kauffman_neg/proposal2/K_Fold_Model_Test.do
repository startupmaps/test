
cd ~/kauffman_neg/

clear
gen obs = .
save k_fold_result.dta, replace

capture confirm variable fold
if _rc != 0 {
    clear
    u $datafile
    safedrop rsort
    gen rsort = runiform()
    sort rsort
    safedrop fold
    gen fold = floor(_n/_N*10)
    replace fold = 9 if fold == 10
    save $datafile , replace 
}


forvalues testfold=0/9{

    u $datafile, replace
    safedrop statecode
    encode datastate, gen(statecode)
    tab statecode if statecode == 11
    replace trainingyears = inrange(incyear,1988,2008) & fold != `testfold'

    build_model , fe(11)
    keep if inrange(incyear,1988,2008) & fold == `testfold'
    drop if missing(quality)
    sort quality
    gen percentile = _n/_N

    /* top 1% analysis */
    gen top1 = percentile >= .99
    qui: sum growthz
    local totgrowth `r(sum)'
    qui: sum growthz if top1
    local top1growth `r(sum)'
    local sharetop1 = `top1growth'/`totgrowth'
    di "Share of Top 1 Percent: `sharetop1'"
    replace percentile = floor(_n/_N*20)/20
    replace percentile = .95 if percentile == 1
    safedrop obs
    gen obs = 1
    collapse (sum)obs  growthz, by(percentile)
    egen tot = sum(growthz)
    gen sharegrowth = growthz/tot
    gen sharetop1 = `sharetop1'
    gen foldno = `testfold'
    append using k_fold_result.dta
    save k_fold_result.dta , replace
}


outsheet using ~/kauffman_neg/output/K_Fold_Test$output_suffix.csv, names comma replace
