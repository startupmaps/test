****** Bystate*****
clear
cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg


u analysis34.minimal.dta,clear
safedrop obs
gen obs  =1
drop if incyear > 2014 | incyear<1988
collapse (sum) obs, by(datastate)
gen file = "old"
save bystate.dta , replace

u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/allstates.minimal.new.dta, clear
safedrop obs
gen obs  =1
drop if incyear > 2014 | incyear<1988
collapse (sum) obs, by(datastate)
gen file = "new"
append using bystate.dta 
save bystate.dta , replace


use bystate.dta , replace
reshape wide obs , i(datastate) j(file) string
gen diff_new = obsnew - obsold
gen ratio = abs(diff_new/obsold)
sort ratio 

save minimal_state.dta, replace

export delimited using /user/user1/yl4180/save/minimal_state.csv, replace
************** audit **************
global statelist WI OR NY RI KY TX VT WA ME IA UT GA VA TN CA SC CO NJ
//OR,NY,RI, VT, WA, IA, UT, VA, TN, SC. CO, NJ has other states
//NY states name contain longstate
//WI jurisdiction crappy, GA, SC has other juris
//KY dataid completely different, WI dataid totally wrong
//Unknown: ME, TX, CA
u analysis34.minimal.dta,clear
foreach state in $statelist {
savesome if datastate == "`state'" using `state'.m.dta, replace
}

foreach state in $statelist {
u `state'.m.dta, clear
merge m:m dataid using /NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta
keep if _merge == 3
drop _merge
save `state'.merge.dta, replace
}
