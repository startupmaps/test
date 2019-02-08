
program define longstate , rclass
      syntax namelist(min=1 max=1)
{
    local local longstate
    # delimit ;
    if "`1'" == "AK"{;return local `local' ALASKA; };
    if "`1'" == "CA"{;return local `local' CALIFORNIA; };
    if "`1'" == "FL"{;return local `local' FLORIDA; };
    if "`1'" == "GA"{;return local `local' GEORGIA; };
    if "`1'" == "MA"{;return local `local' MASSACHUSETTS; };
    if "`1'" == "MI"{;return local `local' MICHIGAN; };
    if "`1'" == "OK"{;return local `local' NEW YORK; };
    if "`1'" == "OK"{;return local `local' OKLAHOMA; };
    if "`1'" == "OR"{;return local `local' OREGON; };
    if "`1'" == "TX"{;return local `local' TEXAS; };
    if "`1'" == "VT"{;return local `local' VERMONT; };
    if "`1'" == "WA"{;return local `local' WASHINGTON; };
    
    # delimit cr
}

end
