
cd ~/kauffman_neg/revision/



    
capture program drop add_zephyr_for_state
program define add_zephyr_for_state , rclass
     syntax  , state(string) longstate(string)
{

    /** Create a file from  data to match to **/
    clear
    u ~/projects/reap_proj/final_datasets/`state'.dta
    keep if state == "`state'" | state == ""
    keep entityname dataid incdate state
    tomname entityname
    save ~/temp/`state'.left_merge_zephyr.dta , replace

    use ~/projects/reap_proj/data/zephyr/acq.zephyr.dta    , clear
    tomname targetname
    keep if upper(itrim(trim(targetstate))) == "`longstate'"
    
    save ~/temp/`state'.right_merge_zephyr.dta , replace


    /** Merge the files **/ 
    jnamemerge ~/temp/`state'.left_merge_zephyr.dta    ~/temp/`state'.right_merge_zephyr.dta

    keep if _mergex != "no match"
    drop _mergex
     
    /** setup a bunch of details on the data  **/   
    rename dealvaluetheur deal_value
    gsort -zephyr_mergerdate
    duplicates drop dataid , force
    gen fin = floor(targetpr/1000)
    gen fin2 = floor(targetpr/100)
    collapse (min) *mergerdate* fin fin2 deal_value, by(dataid entityname)
    gen datastate = "`state'"
    tostring dataid, replace

    
}
end



/***
 ** Setup Pieces
 **/
use ~/kauffman_neg/analysis34.minimal.dta , replace
save ~/kauffman_neg/analysis34.revision.dta , replace
    

local statelist AK AR AZ CA CO CT FL GA IA ID IL KY MA ME NC ND NJ NM NY OH OK OR RI TN TX UT VA VT WA WY
local longstatelist ALASKA ARKANSAS ARIZONA CALIFORNIA COLORADO CONNECTICUT FLORIDA GEORGIA IOWA IDAHO ILLINOIS KENTUCKY MASSACHUSETTS MAINE  NORTH_CAROLINA NORTH_DAKOTA NEW_JERSEY NEW_MEXICO NEW_YORK OHIO OKLAHOMA OREGON RHODE_ISLAND TENNESSEE TEXAS UTAH VIRGINIA VERMONT WASHINGTON WYOMING



/**
 ** Loop and load all the states
 **/

clear
gen dataid = ""
save ~/kauffman_neg/revision/zephyr.merged.dta, replace

local n: word count `statelist'
forvalues i=1/`n' {
    local shortstate: word `i' of `statelist'
    local longstate: word `i' of `longstatelist'
    local longstate= subinstr("`longstate'","_"," ",.)
    add_zephyr_for_state , state(`shortstate') longstate(`longstate')

    append using ~/kauffman_neg/revision/zephyr.merged.dta
    save ~/kauffman_neg/revision/zephyr.merged.dta, replace
}



if 1 == 0 { 

    /** Merge back to the original file for SAOE
        TODO: Needs to be implemented
     **/
    merge 1:m dataid datastate using ~/kauffman_neg/analysis34.minimal.dta 

    keep if _merge == 3 
    drop _merge
    drop if incyear < 1993 | incyear > 2008


    replace mergerdate = . if mergerdate < incdate + 180
    replace zephyr_mergerdate = . if zephyr_mergerdate < incdate + 180

    capture drop acq_in_zephyr*
    capture drop acq_in_sdc*

    capture drop in_both*


    gen acq_in_zephyr = (zephyr_mergerdate - incdate)> 180 & zephyr_mergerdate != . & (ipodate > zephyr_mergerdate)
    gen acq_in_zephyr_6y = inrange((zephyr_mergerdate - incdate), 180, 365*6) & (ipodate > zephyr_mergerdate)


    gen acq_in_sdc = (mergerdate - incdate)> 180 & mergerdate != . & (ipodate > mergerdate)
    gen acq_in_sdc_6y = inrange((mergerdate - incdate), 180, 365*6) & (ipodate > mergerdate)

    gen in_both = acq_in_sdc == 1  & acq_in_zephyr == 1
    gen in_both_6y = acq_in_sdc_6y == 1  & acq_in_zephyr_6y == 1

    tabstat acq_in_sdc_6y acq_in_zephyr_6y in_both_6y , stats(sum)

    stop hers ;

    list incdate entityname acq_in_sdc_6y acq_in_zephyr_6y zephyr_mergerdate mergerdate  growthz if acq_in_zephyr_6y == 1 | acq_in_sdc_6y == 1 , clean



     local full_model_params is_corp shortname eponymous trademark patent_noDE nopatent_DE patent_and_DE                         clust_local  clust_resource_int clust_traded                         is_biotech is_ecommerce is_IT is_medicaldev is_semicond


    gen in_either_6y  = acq_in_zephyr_6y ==1 | acq_in_sdc_6y == 1

    eststo clear
    eststo, title("SDC"): logit acq_in_sdc_6y `full_model_params' , vce(robust)
    safedrop sdcp
    predict sdcp

    eststo, title("Zephyr"): logit acq_in_zephyr_6y `full_model_params' , vce(robust)
    safedrop zephyrp
    predict zephyrp


    eststo, title("In Both"): logit in_both_6y `full_model_params' , vce(robust)
    eststo, title("In Either"): logit in_either_6y `full_model_params' , vce(robust)

    esttab , eform pr2 scalar(ll) se


    gen growth_all = growthz | acq_in_zephyr_6y
    safedrop quality
    eststo clear
    eststo, title("SDC"): logit growthz `full_model_params' , vce(robust)
    safedrop q_current
    predict q_current

    eststo, title("SDC"): logit growth_all `full_model_params' , vce(robust)
    safedrop q_new
    predict q_new

    esttab , eform pr2 scalar(ll) se

    collapse (sum) q_current q_new growthz growth_all, by(incyear)

    gen reai_current = growthz/q_current
    gen reai_new = growth_all / q_new
}
