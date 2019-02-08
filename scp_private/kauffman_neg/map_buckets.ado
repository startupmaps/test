program define map_buckets, rclass
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
    gen `bucketvar' = 1 if percentile <= 25
    replace `bucketvar' = 2 if inrange(percentile,25,50)
    replace `bucketvar' = 3 if inrange(percentile,50,75)
    replace `bucketvar' = 4 if inrange(percentile,75,80)
    replace `bucketvar' = 5 if inrange(percentile,80,85)
    replace `bucketvar' = 6 if inrange(percentile,85,90)
    replace `bucketvar' = 7 if inrange(percentile,90,95)
    replace `bucketvar' = 8 if inrange(percentile,95,99)
    replace `bucketvar' = 9 if percentile >= 99

    di "Result stored in `bucketvar'"

end
