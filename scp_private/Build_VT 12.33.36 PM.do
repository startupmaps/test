clear
cd /NOBACKUP/scratch/share_scp/scp_private/scp2018

local files `" "dpc" "dllc" "Partnerships" "fpc" "fllc"  "'
 
clear
gen datafile = ""
save VT.start.dta, replace

foreach file of local files {
    di "Loading: `file'.xls"
    clear
    import excel using "/NOBACKUP/scratch/share_scp/raw_data/Vermont/2018/`file'.xlsx", firstrow allstring
   gen datafile = "`file'"
    append using VT.start.dta, force
    save VT.start.dta, replace
}
rename *, lower
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

replace businesstype = trim(itrim(businesstype))
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


	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(VT.dta)
        corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(VT.dta)


        //corp_add_eponymy, dtapath(VT.dta) directorpath(VT.directors.dta)
        
        # delimit ;
        corp_add_trademarks VT , 
                dta(VT.dta) 
                trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
                ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
                var(trademark) 
                frommonths(-12)
                tomonths(12)
                statefileexists;
        
        
        # delimit ;
        corp_add_patent_applications VT VERMONT , 
                dta(VT.dta) 
                pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
                var(patent_application) 
                frommonths(-12)
                tomonths(12)
                statefileexists;
        
        corp_add_patent_assignments  VT VERMONT , 
                dta(VT.dta)
                pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
                frommonths(-12)
                tomonths(12)
                var(patent_assignment)
                statefileexists;
        
        # delimit cr    
        corp_add_ipos    VT ,dta(VT.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta) longstate(VERMONT)
        corp_add_mergers VT ,dta(VT.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers_2018.dta) longstate(VERMONT)
        corp_add_vc 	 VT ,dta(VT.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(VERMONT)

        //corp_add_vc2     VT  ,dta(VT.dta) vc(VC.investors.withequity.dta)  longstate(VERMONT) dropexisting 
	//corp_has_last_name, dtafile(VT.dta) lastnamedta(~/ado/names/lastnames.dta) num(5000)
        //corp_has_first_name, dtafile(VT.dta) num(1000)
        //corp_name_uniqueness, dtafile(VT.dta)


clear
u VT.dta
duplicates drop
compress
//gen has_unique_name = uniquename <= 5
save VT.dta, replace








