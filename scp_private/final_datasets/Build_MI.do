
clear
cd ~/final_datasets

global mergetempsuffix MIaa

import delimited using ~/projects/reap_proj/raw_data/Michigan/Michigan_19Aug2015.csv, delim(",") bindquote(strict) varnames(1)
rename (name company_number) (entityname corp_number)
gen dataid = corp_number
gen is_corp = strpos(company_type,"Corporation") > 0
gen is_nonprofit= strpos(company_type,"Nonprofit") > 0

drop *in_full
rename headquarters_address_* *

foreach v in street_addr postal_code locality region{
    di "More address info: `v'"
    gen orig_`v' = `v'
    replace `v' = registered_address_`v' if missing(`v')
    replace `v' = mailing_address_`v' if missing(`v')
}

drop registered_address* mailing_address*
rename postal_code zipcode
rename street_addr address
gen incdate= date(incorporation_date,"YMD")

drop if is_nonprofit
rename home_jurisdiction jurisdiction
replace jurisdiction = "MI" if inlist(jurisdiction,"","us_mi")
replace jurisdiction = trim(upper(subinstr(jurisdiction, "us_","",.)))


replace region = "MI" if region == "" & jurisdiction == "MI"
rename region state
gen local_firm = inlist(jurisdiction,"MI","DE") & state == "MI"
gen stateaddress = state

gen city = locality
gen incyear = year(incdate)

drop if missing(incyear)

save MI.dta, replace

        
**
**
** STEP 2: Add variables. These variables are within the first year
**              and very similar to the ones used in "Where Is Silicon Valley?"
**
**      

    clear
    u MI.dta, replace
        tomname entityname
        save MI.dta, replace
        corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(~/migration/datafiles/MI.dta)
        corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/migration/datafiles/MI.dta)




        # delimit ;
        corp_add_trademarks MI , 
                dta(~/migration/datafiles/MI.dta) 
                trademarkfile(/projects/reap.proj/data/trademarks.dta) 
                ownerfile(/projects/reap.proj/data/trademark_owner.dta)
                var(trademark) 
                frommonths(-12)
                tomonths(12)
                statefileexists;
        
        
        # delimit ;
        corp_add_patent_applications MI MICHIGAN , 
                dta(~/migration/datafiles/MI.dta) 
                pat(/projects/reap.proj/data_share/patent_applications.dta) 
                var(patent_application) 
                frommonths(-12)
                tomonths(12)
                statefileexists;
        
        corp_add_patent_assignments  MI MICHIGAN , 
                dta(~/migration/datafiles/MI.dta)
                pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta")
                frommonths(-12)
                tomonths(12)
                var(patent_assignment)
        	statefileexists;
	
	# delimit cr	
corp_add_ipos MI  ,dta(~/migration/datafiles/MI.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(MICHIGAN)
corp_add_mergers MI  ,dta(~/migration/datafiles/MI.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(MICHIGAN)
corp_add_vc2  MI  ,dta(~/migration/datafiles/MI.dta) vc(~/final_datasets/VC.investors.withequity.dta)  longstate(MICHIGAN) dropexisting
                       

corp_name_uniqueness, dtafile(~/migration/datafiles/MI.dta)
corp_has_first_name ,dta(~/migration/datafiles/MI.dta) num(5000)
corp_has_last_name ,dta(~/migration/datafiles/MI.dta) num(1000)



				

clear
u ~/migration/datafiles/MI.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
 save MI.dta, replace


