program define build_preliminary_model, rclass 
    syntax , fe(string)

    levelsof datastate, local(states)

   safedrop statecode
   encode datastate, gen(statecode)

    di "Running Models"
    eststo clear        

   # delimit ;

         eststo: logit growthz  is_corp  is_DE ib`fe'.statecode
                       if trainingyears, vce(robust) or;



         eststo: logit growthz   shortname eponymous  ib`fe'.statecode
                       if trainingyears, vce(robust) or;


        eststo: logit growthz patent trademark 
                       ib`fe'.statecode
                        if trainingyears, vce(robust) or;


  
     
       
# delimit cr
    
 esttab, pr2 eform indicate( "State FE=*statecode") order(*name eponymous is_corp is_DE patent trademark)

end
