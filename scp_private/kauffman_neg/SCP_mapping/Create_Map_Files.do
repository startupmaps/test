cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping


set trace on
set tracedepth 1

global statelist AK AR AZ CA CO FL GA IA ID IL KY MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
 
global states50 AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY 

do program.Create_Map_Files.do


/***
 Create the cities lat_lon file

foreach s in  AK AR AZ CA CO FL MI NJ NY WI WY{
     build_city_map_file `s' , refresh
}


***/

append_all_states $statelist , file_suffix(_cities.dta)
add_quality_percentiles $statelist , file_suffix(_cities.dta) keep(city state)
output_files $statelist , file_suffix(_cities.dta)

exit

*********************** program stops ***********************

foreach s in $states50 {
    build_county_map_file `s'
}


append_all_states $states50 , file_suffix(_counties.dta)


foreach s in $statelist {
    if !inlist("`s'", "MI","MN","MO") {
        build_address_map_file `s'
    }
}

append_all_states $statelist , file_suffix(_address.dta)
add_quality_percentiles $statelist , file_suffix(_address.dta) 
output_files $statelist , file_suffix(_address.dta)


output_files $states50 , file_suffix(_counties.dta)


build_all_states_map_file
output_all_states_file

output_agg_by_state_file $statelist


/*** City Files ***/

global statelist  AR AZ CA CO FL GA IA ID IL KY MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
ssc install winsor


foreach s in $statelist {
     build_city_map_file `s'
}

append_all_states $statelist , file_suffix(_cities.dta)
add_quality_percentiles $statelist , file_suffix(_cities.dta) keep(city state)
output_files $statelist , file_suffix(_cities.dta)







/****************************/
/* Temporary Fix and Output */
/****************************/
if 0==1{
    // Added to account for some of RJ's comments
    // at the lsat minute

    clear    
    u dta/allstates_counties.dta
    destring reai_* , replace force
    
    foreach reai of varlist reai_* { 
        replace `reai' = floor(`reai' * 100)
        replace `reai' = 1 if `reai' == 0
    
    }

    tostring reai_* , replace
    
    save dta/allstates_counties.dta , replace


}



exit

/**********************************/
/* Info Graphic Distribution Data */
/**********************************/
{

    clear
    u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/analysis34.minimal.dta
    sort quality
    drop if quality == .
    gen percentile = floor((_n-1)/_N*100)
    collapse (mean) quality , by(percentile incyear)
    rename incyear year


    keep  year percentile quality
    order year percentile quality
    outsheet using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/output/Average_Quality_100percentiles_by_year.csv, comma names replace

    

    
    clear
    u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/analysis34.minimal.dta 
    sort quality
    gen percentile = floor((_n-1)/_N*100)
    safedrop obs
    gen obs = 1
    collapse (sum) obs , by(percentile incyear)
    rename incyear year

    bysort year: egen ytot = sum(obs)

    gen year_adj = ytot/ytot[1]
    gen obs_adj = obs * year_adj
    
    bysort percentile: egen ptot = sum(obs_adj)
    gen share = obs_adj/ptot

    keep  year percentile obs_adj share
    order year percentile obs_adj share
    outsheet using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/output/geocode/Yearly_Distribution_5pct_Groups_bypct.csv, comma names replace



    clear
    u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/analysis34.minimal.dta
    sort quality 
    gen percentile = min(floor(_n/_N*20)*5,95)
    safedrop obs
    gen obs = 1
    collapse (sum) obs , by(percentile incyear)
    rename incyear year
    
    bysort year: egen ytot = sum(obs)
    gen share = obs/ytot

    keep  year percentile obs share
    order year percentile obs share
    outsheet using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/output/geocode/Yearly_Distribution_5pct_Groups.csv, comma names replace


    clear
    u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/analysis34.minimal.dta
    sort quality
    gen percentile = min(floor(_n/_N*10)*10,90)
    safedrop obs
    gen obs = 1
    collapse (sum) obs , by(percentile incyear)
    rename incyear year
    bysort year: egen ytot = sum(obs)
    gen share = obs/ytot

    keep  year percentile obs share
    order year percentile obs share
    outsheet using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/output/geocode/Yearly_Distribution_10pct_Groups.csv, comma names replace
}
