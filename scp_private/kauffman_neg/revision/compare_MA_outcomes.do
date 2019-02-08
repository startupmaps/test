
cd ~/kauffman_neg/revision/

/** Create a file from MA data yo match to **/
clear
u ~/projects/reap_proj/final_datasets/MA.dta
keep if state == "MA"
keep entityname dataid incdate state
tomname entityname
save MA.zephyr.dta , replace


/** Match to the Zephyr acquisitions **/
jnamemerge MA.zephyr.dta ~/projects/reap_proj/data/zephyr/MA.acq.zephyr.dta

gen     deal_value = subinstr(dealvalue,"*","",.)
replace deal_value = subinstr(deal_value,",","",.)

destring deal_value, replace

gen zephyr_mergerdate = date(announceddate, "DMY")
gen zephyr_mergerdate_comp = date(completeddate, "DMY")

gen time_to_merge = floor((zephyr_mergerdate - incdate)/30)
gsort -zephyr_mergerdate
duplicates drop dataid , force
gen fin = floor(targetpr/1000)
gen fin2 = floor(targetpr/100)
collapse (min) *mergerdate* fin fin2 deal_value, by(dataid entityname)
gen datastate = "MA"
tostring dataid, replace


/** Merge back to the original file for SAOE **/
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
