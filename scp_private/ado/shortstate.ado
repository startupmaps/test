capture program drop shortstate

program define shortstate , rclass
      syntax varname , gen(name)
{

    local statelist AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY

    local longstatelist ALABAMA ALASKA ARIZONA ARKANSAS CALIFORNIA COLORADO CONNECTICUT DELAWARE FLORIDA GEORGIA HAWAII IDAHO ILLINOIS INDIANA IOWA KANSAS KENTUCKY LOUISIANA MAINE MARYLAND MASSACHUSETTS MICHIGAN MINNESOTA MISSISSIPPI MISSOURI MONTANA NEBRASKA NEVADA NEW_HAMPSHIRE NEW_JERSEY NEW_MEXICO NEW_YORK NORTH_CAROLINA NORTH_DAKOTA OHIO OKLAHOMA OREGON PENNSYLVANIA RHODE_ISLAND SOUTH_CAROLINA SOUTH_DAKOTA TENNESSEE TEXAS UTAH VERMONT VIRGINIA WASHINGTON WEST_VIRGINIA WISCONSIN WYOMING


    local n: word count `statelist'
    gen `gen' = ""
    forvalues i=1/`n' {
        local shortstate: word `i' of `statelist'
        local longstate: word `i' of `longstatelist'
        local longstate= subinstr("`longstate'","_"," ",.)
        replace `gen' = "`shortstate'" if upper(trim(`1'))== "`longstate'"
    }
        
}


end
