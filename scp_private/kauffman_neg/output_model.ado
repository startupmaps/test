
program define output_model, rclass
    syntax [anything] [using] , [nostar] [noparenthesis] [indicate(string)]


    if "`indicate'" != "" {
        local ind = "indicate(`indicate')"

    }

    esttab `using', se pr2 eform order( shortname haslastname haspropername has_unique_name has_eponymous has_eponymous_X_eponymous is_corp is_DE patent trademark patent_noDE nopatent_DE patent_and_DE) label replace mtitle refcat(shortname "Name Based Measures:" is_corp "Corporate Structure Measures:" patent "Intellectual Property:" patent_noDE "Interactions:" clust_local "US Cluster Mapping Clusters:") `nostar' `noparenthesis' 

end

