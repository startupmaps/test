log using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/output/Build_National_Dataset.log, text replace 
set linesize 120

/*
 * Build the dataset to be used in the paper
 *
 * Performs three important steps:
 *
 *   1. Build Dataset by joining state-level `state'.collapsed.dta files
 *   2. Imputes values for the states that do not have data on specific columns
 *   3. Does a Wald Test on all covariates adding them at the end of the specification to test if
 *      using each measure makes sense.
 */

cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/

local dataset_states $dataset_state_list

if "$collapse_files" == "1" {
    corp_collapse_any_state `dataset_states' , workingfolder(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/)
}

if "$collapse_new_states" == "1" {
   corp_collapse_any_state $new_states , workingfolder(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/)
}


/*
A few  changes taht I have had to make that do not fit anywhere:
u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/CO.collapsed.dta
format dataid %15.0f
tostring dataid, format(%15.0f) replace
save /NOBACKUP/scratch/share_scp/scp_private/final_datasets/CO.collapsed.dta , replace
 */


clear
gen dataid = ""
save mstate.collapsed.new.dta, replace

foreach state in `dataset_states' {
corp_collapse_any_state `dataset_states' , workingfolder(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/) outputsuffix("new") // added
corp_collapse_any_state $new_states , workingfolder(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/) outputsuffix("new")  //added
        di "***************************************"
        di "           Adding State `state'        "
        di "***************************************"

        u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.collapsed.new.dta, replace
        tostring dataid, replace
        safedrop datastate
        gen datastate = "`state'"
        tostring zipcode, replace
        replace zipcode = substr(trim(itrim(zipcode)),1,5)
        qui: append using mstate.collapsed.new.dta
        save mstate.collapsed.new.dta, replace
}







log close
