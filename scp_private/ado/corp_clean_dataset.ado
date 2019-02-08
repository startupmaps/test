program define corp_clean_dataset
    syntax , minimal

{


    safedrop hasnews patent_assignment patent_application patent_count , verbose
    safedrop meanvcquality maxvcquality diffvc getsvc2 getsvc4 getsvc6 getsvc8 , verbose 
    safedrop haslastname haspropername has_unique_name , verbose
    safedrop female male femaleflag maleflag  , verbose
    safedrop is_Agriculture is_Auto is_Chemical is_Consuma is_Distribution is_HighTech , verbose
    safedrop is_Local is_Clothing is_Energy is_Mining is_Paper_and_ is_Publishing is_Services , verbose
    safedrop firstvc deathdate deathyear diffdeath is_dead , verbose

    safedrop is_nonprofit nogender x , verbose
    
    capture confirm variable statey_CA
    if _rc == 0 {
        foreach v of varlist statey_* {
             di "Dropping `v'"
             drop `v'
         }
     
    }

    capture confirm variable tradeclass
     if _rc == 0 {
         foreach v of varlist tradeclass* {
             di "Dropping `v'"
             drop `v'
         }
     }

    replace city = substr(city, 1,20)
    replace zipcode = substr(zipcode, 1,5)

    compress city zipcode
    compress dataid

}

end
