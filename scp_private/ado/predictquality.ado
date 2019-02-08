

/*
 * This model is created based on TSOAE version Feb 15, 2016
 *
 */


program define predictquality , rclass
          syntax    , [datastate(string)] 
{

    if "`datastate'" == "" {
        local datastate datastate
    }
    quietly
    {
    capture drop quality
    gen quality = .0000128
    replace quality=quality*exp(is_corp*1.397275)
    replace quality=quality*exp(shortname*.9145368)
    replace quality=quality*exp(eponymous*-1.197324)
    replace quality=quality*exp(trademark*1.664347)
    replace quality=quality*exp(patent_noDE*3.768784)
    replace quality=quality*exp(nopatent_DE*3.545369)
    replace quality=quality*exp(patent_and_DE*5.275648)
    replace quality=quality*exp(clust_local*-.280563)
    replace quality=quality*exp(clust_reso*.2288134)
    replace quality=quality*exp(clust_traded*.2225421)
    replace quality=quality*exp(is_biotech*.8073917)
    replace quality=quality*exp(is_ecommerce*.1156567)
    replace quality=quality*exp(is_IT*.689856)
    replace quality=quality*exp(is_medical*-.1135839)
    replace quality=quality*exp(is_semicond*.6467625)


    replace quality=quality*exp(1.54338) if `datastate' == "CA"
    replace quality=quality*exp(.314617) if `datastate' == "FL"
    replace quality=quality*exp(.9200471) if `datastate' == "GA"
    replace quality=quality*exp(1.243458) if `datastate' == "MA"
    replace quality=quality*exp(.0153915) if `datastate' == "MI"
    replace quality=quality*exp(.4379826) if `datastate' == "NY"
    replace quality=quality*exp(1.016839) if `datastate' == "OR"
    replace quality=quality*exp(1.489972) if `datastate' == "TX"
    replace quality=quality*exp(-1.489275) if `datastate' == "VT"
    replace quality=quality*exp(.6941483) if `datastate' == "WA"
    replace quality=quality*exp(-.1491003) if `datastate' == "WY"
    replace quality=quality*exp(.2902701) if `datastate' == "ID"
    replace quality=quality*exp(.5373601) if `datastate' == "MO"
    replace quality=quality*exp(1.036417) if `datastate' == "OK"
    

    capture drop qualitylevel
    gen qualitylevel = 0
    replace qualitylevel = 1 if quality > .00007
    replace qualitylevel = 2 if quality > .00182
    replace qualitylevel = 3 if quality > .019392

    capture label drop ql
    label define ql 0 "0-90" 1 "90-95" 2 "95-99" 3 "99-100"
    label values qualitylevel ql
}
}
end
