program test_diff, rclass
     syntax anything  , [start] [close] [add] name(string)

     if "`start'" == "start" {
         postfile `name' `anything' using `using', replace
     }

end
