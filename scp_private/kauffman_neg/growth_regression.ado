program define growth_regression, rclass
    syntax , forward_lag(string) iv_lag(string) [save(string)] [iv_full_model_lag(string)] [cum(int 0)] [quietly] [robustness]


if "`robustness'" != "" {
    di " Including running robustness version with all lags in results"
}

if "`iv_full_model_lag'" == "" {
    local iv_full_model_lag `iv_lag'
}



`quietly'{
   if "`robustness'" == "" { 
         eststo clear
         eststo, title("lag=`iv_lag'"): xtabond2 F`forward_lag'.gsp gsp  , gmm(  gsp, lag(`iv_lag'))  noleveleq small cluster(id) twostep
         eststo, title("lag=`iv_lag'"): xtabond2 F`forward_lag'.gsp gsp bdsbirths  , gmm( bdsbirths gsp, lag(`iv_lag'))  noleveleq small cluster(id) twostep
         eststo, title("lag=`iv_lag'"): xtabond2 F`forward_lag'.gsp gsp reallocation_rate  , gmm( reallocation_rate gsp, lag(`iv_lag'))  noleveleq small cluster(id) twostep
         eststo, title("lag=`iv_lag'"): xtabond2 F`forward_lag'.gsp gsp obs  , gmm( obs gsp, lag(`iv_lag'))  noleveleq small cluster(id) twostep
         eststo, title("lag=`iv_lag'"): xtabond2 F`forward_lag'.gsp gsp quality  , gmm( quality gsp, lag(`iv_lag'))  noleveleq small cluster(id) twostep
         eststo, title("lag=`iv_lag'"): xtabond2 F`forward_lag'.gsp gsp recpi  , gmm( recpi gsp, lag(`iv_lag'))  noleveleq small cluster(id) twostep
  }
   else {
         eststo clear
         eststo, title("lag=`iv_lag'"): xtabond2 F`forward_lag'.gsp gsp  , gmm(  gsp, lag(`iv_lag'))  noleveleq small cluster(id) twostep
         eststo, title("lag=`iv_lag'"): xtabond2 F`forward_lag'.gsp gsp bdsbirths  , gmm( bdsbirths gsp, lag(`iv_lag'))  noleveleq small cluster(id) twostep
         eststo, title("lag=`iv_lag'"): xtabond2 F`forward_lag'.gsp gsp reallocation_rate  , gmm( reallocation_rate gsp, lag(`iv_lag'))  noleveleq small cluster(id) twostep
         eststo, title("lag=`iv_lag'"): xtabond2 F`forward_lag'.gsp gsp obs  , gmm( obs gsp, lag(`iv_lag'))  noleveleq small cluster(id) twostep
         eststo, title("lag=`iv_lag'"): xtabond2 F`forward_lag'.gsp gsp quality  , gmm( quality gsp, lag(`iv_lag'))  noleveleq small cluster(id) twostep
         eststo, title("lag=`iv_lag'"): xtabond2 F`forward_lag'.gsp gsp recpi  , gmm( recpi gsp, lag(`iv_lag'))  noleveleq small cluster(id) twostep


         eststo, title("All Lags"): xtabond2 F`forward_lag'.gsp gsp  , gmm(  gsp)  noleveleq small cluster(id) twostep
         eststo, title("All Lags"): xtabond2 F`forward_lag'.gsp gsp bdsbirths  , gmm( bdsbirths gsp)  noleveleq small cluster(id) twostep
         eststo, title("All Lags"): xtabond2 F`forward_lag'.gsp gsp reallocation_rate  , gmm( reallocation_rate gsp)  noleveleq small cluster(id) twostep
         eststo, title("All Lags"): xtabond2 F`forward_lag'.gsp gsp obs  , gmm( obs gsp)  noleveleq small cluster(id) twostep
         eststo, title("All Lags"): xtabond2 F`forward_lag'.gsp gsp quality  , gmm( quality gsp)  noleveleq small cluster(id) twostep
         eststo, title("All Lags"): xtabond2 F`forward_lag'.gsp gsp recpi  , gmm( recpi gsp)  noleveleq small cluster(id) twostep
   }
}


esttab, se star( + .1 * .05) scalars("hansen Hansen J-Test"  "hansenp Hansen P-Value"  "hansen_df J-Test Deg. Freedom" "N_g # of Groups" "ar2 AR(2) Autocorrelation Test" "ar2p AR(2) P-Value" "j # of Instruments") varwidth(20)


if "`save'"  != "" {
    esttab using "`save'", se r2 star( + .1 * .05) scalars("hansen Hansen J-Test"  "j # of Instruments" "ar2 AR(2) Autocorrelation Test" "ar2p AR(2) P-Value") replace varwidth(20)  
}


end
