cd /NOBACKUP/scratch/share_scp/scp_private/scp2018

u KY.collapsed.new.dta, clear
replace zipcode = substr(zipcode,1,5)
gen rsort = runiform()
gen trainingyears = inrange(incyear,1988,2011)
by trainingyears (rsort), sort: gen trainingsample = _n/_N <= .7
replace trainingsample = 0 if !trainingyears
gen state = "KY"
encode state, gen(statecode)
save KY.collapsed.dta, replace

********** logit ******
u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/allstates.minimal_final.dta, clear
drop quality_old quality_new quality_Z
logit growthz_new eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond i.statecode if inrange(incyear, 1988,2008), vce(robust) or

u KY.collapsed.dta, clear
predict quality, pr
save KY.collapsed.RJ.dta, replace

u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/allstates.minimal_final.dta, clear
drop quality_old quality_new quality_Z
logit growthz_new eponymous shortname is_corp is_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond i.statecode if inrange(incyear, 1988,2008), vce(robust) or

u KY.collapsed.RJ.dta, clear
predict qualitynow, pr
save KY.collapsed.RJ.dta, replace

replace quality = qualitynow if inrange(incyear, 2016,2018)
save KY.collapsed.RJ.dta, replace

*******

corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(KY.dta)
corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(KY.dta)
	
