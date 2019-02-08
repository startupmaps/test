capture program drop weighted_summarize

program define weighted_summarize , rclass
     syntax varname [if], group(varname) 

{
    preserve

    if "`if'" != "" {
        keep `if'
    }

    quietly {
        gen obs = 1
        collapse  (mean) `1' (sum) obs, by(`group')
        egen tot = sum(obs)
        gen weight = obs / tot
        gen vw = `1' * weight
        sum vw
    }
    di "Weighted mean: `r(sum)'"
    return scalar mean = `r(sum)'
    restore
}
end
