

clear
cd ~/final_datasets/

local files `" "Domestic Corp" "Domestic LLC" "Domestic Partnership" "Foreign Corp" "Foreign LLC" "Partnership"  "'
 
clear
gen datafile = ""
save VT.start.dta, replace

foreach file of local files {
    di "Loading: `file'.txt"
    clear
    import delimited using "/projects/reap.proj/raw_data/Vermont/`file'.txt", delim(tab) varnames(1)
   gen datafile = "`file'"
    append using VT.start.dta, force
    save VT.start.dta, replace
}


rename businessid dataid
rename principaloffice* *
rename zip zipcode

drop mailing* foreign* agent*

gen jurisdiction = "VT" if placeof == "Vermont"
replace jurisdiction = "DE" if placeof == "Delaware"
gen is_DE = jurisdiction == "DE"

gen stateaddress = state
gen local_firm= inlist(jurisdiction, "VT","DE") & stateaddress == "VT"
    
gen incdate = date(businessorigindate, "YMD")
gen incyear = year(incdate)
gen is_corp = strpos(businesstype,"Corporation") > 0

rename businessname entityname
gen address = trim(itrim(address1  + " " + address2)) 
gen is_nonprofit= 0
gen shortname = wordcount(entityname) <= 3
 

keep shortname dataid entityname address zipcode city state jurisdiction is_DE incdate incyear is_corp is_nonprofit stateaddress local_firm
save VT.dta ,replace



clear
cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets/
local files `" "Domestic Corp" "Domestic LLC" "Domestic Partnership" "Foreign Corp" "Foreign LLC" "Partnership"  "'
gen datafile = ""
save VT.directors.dta, replace

foreach file of local files {
    di "Loading: `file' Principal.txt"
    clear
    import delimited using "/NOBACKUP/scratch/share_scp/raw_data/Vermont/`file' Principal.txt", delim(tab) varnames(1)
   gen datafile = "`file'"
    append using VT.directors.dta, force
    save VT.directors.dta, replace
}

rename (businessid principalname principaltitle) (dataid fullname role)
keep dataid fullname role
replace fullname = upper(trim(itrim(subinstr(fullname,"."," ",.))))
split fullname, parse(,)
gen name = fullname2 + " " + fullname3 + " " + fullname1 

replace name = fullname3 + " " + fullname2 + " " + fullname1 if length(trim(itrim(fullname3)))>2
replace fullname = upper(trim(itrim(name)))

// keep if inlist(role, "President","Member","Manager","Partner","General Partner") *for legislator task
save VT.directors.dta, replace



**
**
** Section 2: Adding other observables
**
**


 clear
u VT.dta
tomname entityname
save VT.dta, replace


corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(~/final_datasets/VT.dta)
        corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/final_datasets/VT.dta)


        corp_add_eponymy, dtapath(~/final_datasets/VT.dta) directorpath(~/final_datasets/VT.directors.dta)
        
        # delimit ;
        corp_add_trademarks VT , 
                dta(~/final_datasets/VT.dta) 
                trademarkfile(/projects/reap.proj/data/trademarks.dta) 
                ownerfile(/projects/reap.proj/data/trademark_owner.dta)
                var(trademark) 
                frommonths(-12)
                tomonths(12)
                class(/projects/reap.proj/data/trademarks/classification.dta)
                statefileexists;
        
        
        # delimit ;
        corp_add_patent_applications VT VERMONT , 
                dta(~/final_datasets/VT.dta) 
                pat(/projects/reap.proj/data_share/patent_applications.dta) 
                var(patent_application) 
                frommonths(-12)
                tomonths(12)
                statefileexists;
        
        corp_add_patent_assignments  VT VERMONT , 
                dta(~/final_datasets/VT.dta)
                pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta")
                frommonths(-12)
                tomonths(12)
                var(patent_assignment)
                statefileexists;
        
        # delimit cr    
        corp_add_ipos    VT ,dta(~/final_datasets/VT.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(VERMONT)
        corp_add_mergers VT ,dta(~/final_datasets/VT.dta) merger(/projects/reap.proj/data/mergers.dta) longstate(VERMONT)
        

        corp_add_vc2     VT  ,dta(~/final_datasets/VT.dta) vc(~/final_datasets/VC.investors.withequity.dta)  longstate(VERMONT) dropexisting 
	corp_has_last_name, dtafile(~/final_datasets/VT.dta) lastnamedta(~/ado/names/lastnames.dta) num(5000)
        corp_has_first_name, dtafile(~/final_datasets/VT.dta) num(1000)
        corp_name_uniqueness, dtafile(~/final_datasets/VT.dta)


clear
u ~/final_datasets/VT.dta
gen is_DE = jurisdiction == "DE"
gen has_unique_name = uniquename <= 5
save ~/final_datasets/VT.dta, replace








