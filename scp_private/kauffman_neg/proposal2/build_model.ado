program define build_model, rclass
    syntax , [include_preliminary_models]


    safedrop rsort
    safedrop trainingyears trainingsample

    gen rsort = runiform()
    gen trainingyears = inrange(incyear,1995,2008)
    by datastate trainingyears (rsort), sort: gen trainingsample = _n/_N <= .7
    replace trainingsample = 0 if !trainingyears

    label variable haslastname "Firm Name has Last Name"
    label variable haspropername "Firm Name has Proper Name"

    /*
     * Build Model
     */


    eststo clear        
    if "`include_preliminary_models'" != "" {

        # delimit ;
        eststo: logit growthz is_corp  shortname haslastname haspropername is_DE   
                        if trainingsample, vce(robust) or;

        # delimit ;
        eststo: logit growthz is_corp  shortname  haslastname haspropername is_DE 
                        clust_local clust_high_tech clust_resource_int clust_traded  is_biotech is_ecommerce is_IT is_medicaldev is_semicond
                        if trainingsample, vce(robust) or;


        eststo: logit growthz patent trademark
                        if trainingsample, vce(robust) or;
    }

    # delimit ;
    eststo: logit growthz is_corp eponymous shortname trademark patent_noDE nopatent_DE patent_and_DE 
                    clust_local clust_high_tech clust_resource_int clust_traded  is_biotech is_ecommerce is_IT is_medicaldev is_semicond
                    if trainingsample, vce(robust) or;

    # delimit cr

    esttab, se pr2 eform order(is_corp shortname haslastname haspropername is_DE patent trademark patent_noDE nopatent_DE patent_and_DE) label



end 
