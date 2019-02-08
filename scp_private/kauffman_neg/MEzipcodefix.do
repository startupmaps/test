clear
u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/analysis34.minimal.dta
replace zipcode = "0"+zipcode if strlen(zipcode) ==4 & datastate =="ME"
save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/analysis34.minimal.dta, replace
