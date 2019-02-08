program define map_buckets2, rclass
      syntax varlist , [bucketvar(string)] [by(string)]

    if "`bucketvar'" == "" {
        local bucketvar map_bucket
    }

    safedrop `bucketvar' percentile ,v 
    sort `by'  `1'

    if "`by'" == "" {
        gen percentile = _n/_N * 100
    }
    else {
        by `by': gen percentile = _n/_N * 100

    }
    gen `bucketvar' = 1 if percentile <= 90
    replace `bucketvar' = 6 if inrange(percentile,90,95)
    replace `bucketvar' = 7 if inrange(percentile,95,97)
    replace `bucketvar' = 8 if inrange(percentile,97,99)
    replace `bucketvar' = 8 if inrange(percentile,99,99.5)
    replace `bucketvar' = 9 if percentile >= 99.5

    di "Result stored in `bucketvar'"

end
