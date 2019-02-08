


capture program drop corp_collapse_any_state
program define corp_collapse_any_state, rclass
	syntax anything , [outputsuffix(string)] [workingfolder(string)] [extra(string)] [blankfields(string)] [by(string)] [force_local_firm]


local params = substr("`0'",1, strpos("`0'", ","))
di "collapsing files: `params'"

foreach state in `params' {

    if trim("`state'") == "," {
        continue
    }
    
	di "**********************************************"
	di "       Building State:    `state' "   
	di "**********************************************"
	clear
	
	u `workingfolder'`state'.dta

        ** If force_local_firm is set, then you simply assume all firms are local
        ** when local_firm is not found.
        if "`force_local_firm'" == "" {
            keep if local_firm
        }
       else {
           capture confirm variable local_firm
           if _rc == 0 {
               keep if local_firm
           }
       }
	
	foreach v in hasnews tradeclass female male deathdate deathyear firstvc meanvcquality maxvcquality eponymous `blankfields' haslastname haspropername has_unique_name is_nonprofit firstvc_preqin firstvc_capitaliq firstvc_crunchbase { 
		capture confirm variable `v'
		if _rc {
			gen `v' = .
		}
	}
	
	
	
	
	foreach v in region  { 
		capture confirm variable `v'
		if _rc {
			gen `v' = ""
		}
	}
	
	gen is_merger = !missing(mergerdate)
	
	replace region = state if missing(region)
	gen patent_count = patent_assignment + patent_application
	

    replace is_DE = 0 if missing(is_DE)
    
	# delimit ;
	
	collapse (min) incyear incdate firstvc_vx=firstvc firstvc_preqin firstvc_capitaliq firstvc_crunchbase
		(max) female  male deathdate deathyear  tradeclass*
		trademark patent_assignment patent_application hasnews
		is_merger   is_corp
		is_nonprofit is_DE shortname  eponymous
		ipodate mergerdate
		 is_Agriculture_and_Food is_Auto is_Chemical is_Clothing is_Consuma_Appl is_Distribution 
		 is_Energy is_HighTech is_Local is_Mining is_Paper_and_Plastic is_Publishing is_Services 
		is_IT is_biotech is_ecommerce is_medicaldev is_semicond
		meanvcquality* maxvcquality*
		haslastname haspropername has_unique_name
		
		(sum) patent_count patent_application_count=patent_application
		
		`extra'
	, by ( city zipcode dataid `by');
	
	# delimit cr
	
	gen sumvcdate = 0
	foreach v of varlist firstvc* { 
		replace `v' = . if `v' < incdate & `v' != .
		replace sumvcdate = sumvcdate + `v' if `v' != .
	}

	egen nmiss  = rowmiss(firstvc*)
	gen firstvc = sumvcdate/(4-nmiss) if nmiss < 4
	drop sumvcdate nmiss
	
	gen femaleflag = female > 0
	gen maleflag = male > 0
	gen nogender = femaleflag == 0 & maleflag == 0
	
	
	gen diffmerger = month(mergerdate) - month(incdate) + 12*(year(mergerdate) - year(incdate))
	gen diffipo = month(ipodate) - month(incdate) + 12*(year(ipodate) - year(incdate))
	gen growthz = inrange(diffmerger,0,12*6) & !missing(diffmerger) | inrange(diffipo,0,12*6) & !missing(diffipo) 
	
	gen diffdeath = month(deathdate) - month(incdate) + 12*(year(deathdate) - year(incdate))
	gen is_dead = inrange(diffdeath,0,12*6) & !missing(diffdeath)

	gen diffvc = month(firstvc) - month(incdate) + 12*(year(firstvc) - year(incdate))
	gen getsvc2 = inrange(diffvc,0,12*2) & !missing(diffvc)
	gen getsvc4 = inrange(diffvc,0,12*4) & !missing(diffvc)
	gen getsvc6 = inrange(diffvc,0,12*6) & !missing(diffvc)
	gen getsvc8 = inrange(diffvc,0,12*8) & !missing(diffvc)
	gen getsvc = diffvc >= 0 & !missing(diffvc)


	foreach v of varlist patent_assignment patent_application trademark* tradeclass* {
		makedummy `v'
	}
	replace patent_count = 0 if missing(patent_count)
	gen patent = max(patent_assignment, patent_application)
	gen patent_noDE = patent & !is_DE
	gen nopatent_DE = !patent & is_DE
	gen patent_and_DE = patent & is_DE
	
	
		
	 gen clust_local = is_Local
	 gen clust_high_tech = is_HighTech | is_Chemical
	 gen clust_resource_int = is_Energy | is_Agriculture_and_Food | is_Mining
	 gen clust_traded_services = is_Services | is_Publishing
	 gen clust_traded_manufacturing = is_Auto | is_Clothing | is_Distribution | is_Consuma | is_Paper
	 gen clust_traded = max(clust_high_tech, clust_resource_int, clust_traded_services, clust_traded_manufacturing)

	 label variable is_corp "Corporation"
	 label variable shortname "Short Name"
	 label variable eponymous "Eponymous"
	 label variable trademark "Trademark"
	 label variable patent "Patent"
	 label variable patent_noDE "  Patent Only"
	 label variable nopatent_DE  "  Delaware Only"
	 label variable patent_and_DE "  Patent and Delaware"
	 label variable is_DE "Delaware"
	 

	 label variable clust_local "Local"
	 label variable clust_high_tech "Traded High Technology"
	 label variable clust_traded_services "Traded Services"
	 label variable clust_traded_manufacturing "Other Traded Manufacturing"
	 label variable clust_traded "Traded"
	label variable clust_resource_int " Traded Resource Intensive"
	
	
	label variable is_IT "IT Sector"
	label variable is_biotech "Biotech Sector"
	label variable is_ecommerce "Ecommerce Sector"
	label variable is_medicaldev "Medical Dev. Sector"
	label variable is_semicond "Semiconductor Sector"
	
	 
	 if "`outputsuffix'" != ""  {
		local ox = ".`outputsuffix'"
	}
	
	di " `workingfolder'`state'.collapsed`ox'.dta"
	save `workingfolder'`state'.collapsed`ox'.dta, replace
}


end
