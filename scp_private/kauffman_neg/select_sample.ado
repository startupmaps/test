program define select_sample, rclass
   syntax, [maketrain]  [trainingsample(string)] [savetrain]
    di "Preliminary Steps"
    if "`maketrain'" == "maketrain" { 
        di "Making new training sample and storing to `trainingsample'"
        safedrop rsort
        safedrop trainingyears trainingsample
        gen rsort = runiform()
        gen trainingyears = inrange(incyear,1988,2008)
        sort datastate trainingyears rsort
        by datastate trainingyears, sort: gen trainingsample = _n/_N <= .7
        replace trainingsample = 0 if !trainingyears

        if "`savetrain'"=="savetrain" {
            /*Only save it if specifically told to do so*/
            keep  dataid datastate trainingsample trainingyears
            duplicates drop
            save `trainingsample', replace
            di "Training Sample Saved!!!!"
        }
        
        di "Training Sample Done"
    }
    else {
        di "Dropping all data not from 1988 to 2015"
        drop if !inrange(incyear,1988,2015)
        
        di "Using existing training sample `trainingsample'"
        safedrop trainingyear trainingsample _merge
        merge m:1 dataid datastate using `trainingsample'
        keep if _merge ==3
        drop _merge
    }


end
