cd ~/final_datasets/


global mergetempsuffix "GA_Official"

/*    
clear
import delimited using /projects/reap.proj/raw_data/Georgia/bizEntityData.txt, delim(tab) varnames(1)

rename (bizentityid businessname foreignstate) (corp_number entityname jurisdiction)

gen dataid = corp_number
tab modeltype
gen is_corp = modeltype == "Corp" | strpos(modeltype,"Corporation") > 1
gen is_nonprofit = qualifier == "NonProfit" | strpos(modeltype,"Non-Profit") > 1

gen incdate = date(commencementdate,"MDY")
gen incyear = year(incdate)
gen is_domestic = locale == "Domestic"
tab locale
tab qualifier
tab jurisdiction

gen is_DE = jurisdiction == "DE"

gen local_firm = is_domestic | !is_domestic & is_DE
keep if !is_nonprofit


keep dataid corp_number is_nonprofit is_corp incdate incyear entityname jurisdiction is_domestic local_firm

save GA.dta, replace

* Import the Address of Each Firm *

clear
import delimited using /projects/reap.proj/raw_data/Georgia/bizEntityAddressData.txt, delim(tab) varnames(1)
gen orderid = _n
    
duplicates drop
keep if officetype == "Principal Office"
rename bizentityid dataid

* Keep the first address on file *
by dataid (orderid), sort: gen keepme = _n == 1
keep if keepme

gen address = trim(itrim(line1 + " " + line2))
rename zip zipcode
keep dataid address city state zipcode country

merge 1:1 dataid using GA.dta
drop if _merge != 3
drop _merge

keep if inlist(country,"USA","","United States")
replace local_firm = 0 if ! inlist(state,"GA","")

save GA.dta, replace


clear
import delimited using /projects/reap.proj/raw_data/Georgia/bizOfficersPartnersOrganizersData.txt, delim(tab) varnames(1)

rename bizentityid dataid

gen fullname = firstname + " " + middlename + " " + lastname
replace fullname = trim(itrim(regexr(fullname," +"," ")))

keep if inlist(businesscontacttype, "CEO","Organizer","Incorporator","General Partner")
rename businesscontacttype role
replace role = upper(trim(itrim(role)))
keep dataid fullname role firstname
order dataid fullname role
save GA.directors.dta, replace



 *
 * Step 2: Add Measures
 *
 *
    



 clear
u GA.dta
gen shortname = wordcount(entityname) <= 3
tomname entityname
save GA.dta, replace


corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(~/final_datasets/GA.dta)
        corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/final_datasets/GA.dta)

**        corp_add_gender, dta(~/final_datasets/GA.dta) directors(~/final_datasets/GA.directors.dta) names(~/ado/names/GA.TXT)


*/
        corp_add_eponymy, dtapath(~/final_datasets/GA.dta) directorpath(~/final_datasets/GA.directors.dta)
        
        # delimit ;
        corp_add_trademarks GA , 
                dta(~/final_datasets/GA.dta) 
                trademarkfile(/projects/reap.proj/data/trademarks.dta) 
                ownerfile(/projects/reap.proj/data/trademark_owner.dta)
                var(trademark) 
                frommonths(-12)
                tomonths(12)
                class(/projects/reap.proj/data/trademarks/classification.dta)
                statefileexists;
        
        
        # delimit ;
        corp_add_patent_applications GA GEORGIA , 
                dta(~/final_datasets/GA.dta) 
                pat(/projects/reap.proj/data_share/patent_applications.dta) 
                var(patent_application) 
                frommonths(-12)
                tomonths(12)
                statefileexists;
        
        corp_add_patent_assignments  GA GEORGIA , 
                dta(~/final_datasets/GA.dta)
                pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta")
                frommonths(-12)
                tomonths(12)
                var(patent_assignment)
                statefileexists;
        
        # delimit cr    
        corp_add_ipos    GA ,dta(~/final_datasets/GA.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(GEORGIA)
        corp_add_mergers GA ,dta(~/final_datasets/GA.dta) merger(/projects/reap.proj/data/mergers.dta) longstate(GEORGIA)
        

*        corp_add_vc2     GA  ,dta(~/final_datasets/GA.dta) vc(~/final_datasets/VC.investors.withequity.dta)  longstate(GEORGIA) dropexisting 
*	corp_has_last_name, dtafile(~/final_datasets/GA.dta) lastnamedta(~/ado/names/lastnames.dta) num(5000)
*        corp_has_first_name, dtafile(~/final_datasets/GA.dta) num(1000)
*        corp_name_uniqueness, dtafile(~/final_datasets/GA.dta)


clear
u ~/final_datasets/GA.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
gen has_unique_name = uniquename <= 5
 save ~/final_datasets/GA.dta, replace







