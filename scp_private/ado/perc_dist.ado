capture program drop perc_dist

program define perc_dist , rclass
     syntax , prob(varname) y(varname) [np(integer 20)]
{
    tempvar percentile
    sort `prob'
    gen `percentile' = floor(_n/_N*`np')*100/`np'
    replace `percentile' = floor((_n-1)/_N*`np')*100/`np' if _n == _N // just an annoying bug
    recast int `percentile'
    
    tabstat `y', by(`percentile') stats(mean sum N) 
}

end 
