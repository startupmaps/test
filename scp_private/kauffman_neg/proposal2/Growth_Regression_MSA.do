capture log close growthregmsa
log using ~/kauffman_neg/output/Growth_Regression_MSA.log, name(growthregmsa) text replace 

cd ~/kauffman_neg
set matafavor speed
global do_pvar 0

clear
u msa_indexes.dta, replace
destring msagdp, replace
gen id = msacode
sort id year

drop if year > 2013
replace recpi = recpinow if missing(recpi) | recpi == 0
foreach v of varlist recpi recpinow obs msagdp  { 
    replace `v' = ln(`v')
}

xtset id year



if $do_pvar == 1{
	preserve

	helm msagdp obs recpi quality gdprecpi 
	
	pvar2 msagdp recpi, lag(3) gmm monte 200 12 
	graph save gr1_2 output/irf_recpi_gdp$output_suffix.gph, replace
	pvar2 msagdp obs, lag(3) gmm monte 200 12 
	graph save gr1_2 output/irf_obs_gdp$output_suffix.gph, replace
	pvar2 msagdp quality, lag(3) gmm monte 200 12 
	graph save gr1_2 output/irf_quality_gdp$output_suffix.gph, replace

	restore
}


local FL F5
local lag_structure 2 7


eststo clear
eststo: xtabond2 `FL'.msagdp msagdp obs  , gmm( obs `FL'.msagdp, lag(`lag_structure')) iv(msagdp) noleveleq small cluster(id) twostep
eststo: xtabond2 `FL'.msagdp msagdp quality  , gmm( quality `FL'.msagdp, lag(`lag_structure')) iv(msagdp) noleveleq small cluster(id) twostep
eststo: xtabond2 `FL'.msagdp msagdp recpi  , gmm( recpi `FL'.msagdp, lag(`lag_structure')) iv(msagdp) noleveleq small cluster(id) twostep
eststo: xtabond2 `FL'.msagdp msagdp obs quality recpi  , gmm( obs recpi quality `FL'.msagdp, lag(`lag_structure')) iv(msagdp) noleveleq small  cluster(id) twostep



 esttab using ~/kauffman_neg/output/GrowthRegression_MSA_5yrsout$output_suffix.csv, se r2 star( + .1 * .05) scalars("hansen Hansen J-Test" "hansen_df J-Test Deg. Freedom" "N_g # of Groups" "j # of Instruments" "ar2 AR(2) Autocorrelation Test" "ar2p AR(2) P-Value") replace varwidth(20)
esttab, se star( + .1 * .05) scalars("hansen Hansen J-Test" "hansen_df J-Test Deg. Freedom" "N_g # of Groups" "ar2 AR(2) Autocorrelation Test" "ar2p AR(2) P-Value" "j # of Instruments") varwidth(20)

quietly { 

local FL F3


    eststo clear
eststo: xtabond2 `FL'.msagdp msagdp obs  , gmm( obs `FL'.msagdp, lag(`lag_structure')) iv(msagdp) noleveleq small cluster(id) twostep
eststo: xtabond2 `FL'.msagdp msagdp quality  , gmm( quality `FL'.msagdp, lag(`lag_structure')) iv(msagdp) noleveleq small cluster(id) twostep
eststo: xtabond2 `FL'.msagdp msagdp recpi  , gmm( recpi `FL'.msagdp, lag(`lag_structure')) iv(msagdp) noleveleq small cluster(id) twostep
eststo: xtabond2 `FL'.msagdp msagdp obs quality recpi  , gmm( obs recpi quality `FL'.msagdp, lag(`lag_structure')) iv(msagdp) noleveleq small  cluster(id) twostep
}

esttab, se star( + .1 * .05) scalars("hansen Hansen J-Test" "hansen_df J-Test Deg. Freedom" "N_g # of Groups" "ar2 AR(2) Autocorrelation Test" "ar2p AR(2) P-Value" "j # of Instruments") varwidth(20)
esttab using ~/kauffman_neg/output/GrowthRegression_MSA_3yrsout$output_suffix.csv, se r2 star( + .1 * .05) scalars("hansen Hansen J-Test" "hansen_df J-Test Deg. Freedom" "N_g # of Groups" "j # of Instruments"< "ar2 AR(2) Autocorrelation Test" "ar2p AR(2) P-Value") replace varwidth(20)





log close growthregmsa
