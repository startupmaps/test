program define jgtrace, rclass
     syntax anything , ifx(integer)

                 if `ifx' == 1 {
                     local param = subinstr("`1'",",","",.)
                     set trace `1'

                 }
end 
                
