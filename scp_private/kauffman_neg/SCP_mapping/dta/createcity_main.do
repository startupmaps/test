cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping


set trace on
set tracedepth 1

global statelist AK AR AZ CA CO FL GA IA ID IL KY MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
 
global states50 AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY 


global statelist  AR AZ CA CO FL GA IA ID IL KY MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
ssc install winsor


foreach s in $statelist {
     build_city_map_file `s'
}

append_all_states $statelist , file_suffix(_cities.dta)
add_quality_percentiles $statelist , file_suffix(_cities.dta) keep(city state)
output_files $statelist , file_suffix(_cities.dta)

