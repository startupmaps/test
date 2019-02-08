*!version 1.8
*!date: 16apr2014 v1.8
*!v1.7 --> updated based on Kreider Gauss code for grid search under (j=1,i=1) and (j=1,i=2) models
*!v1.7 --> add checks to ensure P00,P01,P10,P11>0 in each MIV cell
*!v1.8 --> updated graph formats

program tebounds, eclass properties(svyb)
	version 10.0
	#delimit ;
	syntax varlist (min=1 max=1) [if] [in] [pw iw], Treat(varname) 
		[MIV(varname) Control(int 0) TReatment(int 1) NCells(int 5) ERATES(string) K(int 100) NP(int 500) NODISPLAY
		IM BS REPS(int 100) NPSU(int -1) SAving(string) REPLACE LEVEL(int 95) GRaph Survey Weights(int 0)];		
	marksample touse;			
	#delimit cr

	gettoken y: varlist

******************************************************************
** 				   Notes					    ** 
******************************************************************
* j = 1 for Exogenous Selection Model
* j = 2 for Worst Case Selection Model
* j = 3 for Monotone Treatment Selection (MTS) Models
* j = 4 for Monotone Instrumental Variable (MIV) Models
* j = 5 for MTS and MTR models

* i = 1 for Assumption A1 only (Arbitrary Errors Model)
* i = 2 for both Assumptions 1 and 2 (No False Positives Model)

* ub_1: ub of P(Y(1)=1)
* lb_1: lb of P(Y(1)=1)
* ub_0: ub of P(Y(0)=1)
* lb_0: lb of P(Y(0)=1)
* ub_ate = ub_1 - lb_0
* lb_ate = lb_1 - ub_0 	

******************************************************************
******************************************************************

	tempvar D y0 y1 yy z zz
	tempname A

	capture _svy_newrule
	if _rc & "`survey'" != ""  {
		dis in red "Data not set up for svy. Please svyset your data in order to use survey weights."
		exit 119
	}
	
*creating treatment dummy and outcome
	qui g `D'=0 if `treat'==`control'
	qui replace `D'=1 if `treat'==`treatment'
	qui g double `y0'=`y' if `D'==0
	qui g double `y1'=`y' if `D'==1
	qui g double `yy'=`y' if `D'==0 | `D'==1

*getting sample size
	qui count if `yy'!=.
	local N=r(N)
	if `N'==0 { 
		error 2000 
	} 

*getting svy details
	if "`survey'" != "" & `weights'==0 {
		qui svyset
		global r_set=r(settings)
		global wtype=r(wtype)
		global wexp=r(wexp)
	}
	
* getting the sample proportion of treated
	tempname mat_z
	if "`survey'" != "" {
		qui svy, subpop(`touse'): mean `D'
		mat `mat_z'=e(b)
		loc mD=`mat_z'[1,1]
	}
	else {
		qui su `D' if `touse', meanonly
		loc mD = r(mean)
	}

* getting the joint probabilities of the various outcomes and the treatment variable
	tempvar d1 d2 d3 d4
	qui g `d1'=(`yy' == 1 & `D'== 1)
	qui g `d2'=(`yy' == 0 & `D'== 0)
	qui g `d3'=(`yy' == 1 & `D'== 0)
	qui g `d4'=(`yy' == 0 & `D'== 1)	
	if "`survey'" != "" {
		qui svy, subpop(`touse'): mean `d1'
		mat `mat_z'=e(b)
		loc p11=`mat_z'[1,1]
		
		qui svy, subpop(`touse'): mean `d2'
		mat `mat_z'=e(b)
		local p00=`mat_z'[1,1]
		
		qui svy, subpop(`touse'): mean `d3'
		mat `mat_z'=e(b)
		local p10=`mat_z'[1,1]
		
		qui svy, subpop(`touse'): mean `d4'
		mat `mat_z'=e(b)
		local p01=`mat_z'[1,1]
	}
	else {
		qui su `d1' if `touse', meanonly
		loc p11=r(mean)
		qui su `d2' if `touse', meanonly
		loc p00=r(mean)
		qui su `d3' if `touse', meanonly
		loc p10=r(mean)
		qui su `d4' if `touse', meanonly
		loc p01=r(mean)
	}
	
* Assumption A1: arbitrary classification errors
	if "`erates'" == "" {
		loc erates "0 0.05 0.10 0.25"
	}
	SetQ `erates'
	loc erates "`r(quants)'"
	tokenize "`r(quants)'"
	loc nq 1
	while "``nq''" != "" {
		loc Q_`nq' ``nq''
		loc nq = `nq' + 1
	}
	loc nq = `nq' - 1

	forval q = 1/`nq' {
		loc QQ_`q'=`Q_`q''*100
		loc t1pos_`q' = min(`Q_`q'',`p11')
		loc t1neg_`q' = min(`Q_`q'',`p10')
		loc t0pos_`q' = min(`Q_`q'',`p01')
		loc t0neg_`q' = min(`Q_`q'',`p00')
	}

***********************************************************************************************************************
******************************* Getting bounds for ATE under different selection models *******************************

*! Exogenous Selection Model (j=1)

	*! Arbitrary Errors Model: Invoking only A1 (j=1 & i=1)
	forval q = 1/`nq' {
		if `Q_`q''==0 {				
			loc ub11_ate_`q' = `p11'/`mD' - `p10'/(1-`mD')
			loc lb11_ate_`q' = `ub11_ate_`q''
		}
		else {
			loc ub11_ate_`q' = -10
			loc lb11_ate_`q' =  10 
			loc inc_b=`t1pos_`q''/(`np'-1)
			loc inc_a=`t1neg_`q''/(`np'-1)
			loc inc_b_temp=`t0neg_`q''/(`np'-1)			
			loc inc_a_temp=`t0pos_`q''/(`np'-1)
			forval b=0(`inc_b')`t1pos_`q'' {
				loc Q_temp_b_max=min(`Q_`q'' - `b',`t0neg_`q'')
				forval Q_temp_b=0(`inc_b_temp')`Q_temp_b_max' {
					loc ratio_1_b=(`p11'-`b')/(`mD'-`b'+`Q_temp_b')
					loc ratio_2_b=(`p10'+`b')/(1-`mD'+`b'-`Q_temp_b')
					if `ratio_1_b'<=1 & `ratio_2_b'<=1 {
						loc lb11_ate_`q' = min(`lb11_ate_`q'',`ratio_1_b'-`ratio_2_b')
					}
				}
			}											
			forval a=0(`inc_a')`t1neg_`q'' {
				loc Q_temp_a_max=min(`Q_`q'' - `a',`t0pos_`q'')
				forval Q_temp_a=0(`inc_a_temp')`Q_temp_a_max' {
					loc ratio_1_a=(`p11'+`a')/(`mD'+`a'-`Q_temp_a')
					loc ratio_2_a=(`p10'-`a')/(1-`mD'-`a'+`Q_temp_a')
					if `ratio_1_a'<=1 & `ratio_2_a'<=1 {
						loc ub11_ate_`q' = max(`ub11_ate_`q'',`ratio_1_a'-`ratio_2_a')
					}
				}
			}
			loc lb11_ate_`q' = max(`lb11_ate_`q'', -1)
			loc ub11_ate_`q' = min(`ub11_ate_`q'', 1)
		}				
	   	ereturn scalar ub11_ate_`QQ_`q''=`ub11_ate_`q''
	 	ereturn scalar lb11_ate_`QQ_`q''=`lb11_ate_`q''
		
	}

    *! No False Positives Model: Invoking both A1 and A2 => Setting `t1pos' = 0 and `t0pos'= 0 (j=1 & i=2)

    forval q = 1/`nq' {
		if `Q_`q''==0 {				
			loc ub12_ate_`q' = `ub11_ate_`q''
			loc lb12_ate_`q' = `lb11_ate_`q''
		}
		else {
			loc ub12_ate_`q' = -10
			loc lb12_ate_`q' =  10 
			loc inc_h=`t0neg_`q''/(`np'-1)
			loc inc_a=`t1neg_`q''/(`np'-1)
			forval h=0(`inc_h')`t0neg_`q'' {
				loc ratio_1_h=(`p11')/(`mD'+`h')
				loc ratio_2_h=(`p10')/(1-`mD'-`h')
				if `ratio_1_h'<=1 & `ratio_2_h'<=1 {
					loc lb12_ate_`q' = min(`lb12_ate_`q'',`ratio_1_h'-`ratio_2_h')
				}
			}											
			forval a=0(`inc_a')`t1neg_`q'' {
				loc ratio_1_a=(`p11'+`a')/(`mD'+`a')
				loc ratio_2_a=(`p10'-`a')/(1-`mD'-`a')
				if `ratio_1_a'<=1 & `ratio_2_a'<=1 {
					loc ub12_ate_`q' = max(`ub12_ate_`q'',`ratio_1_a'-`ratio_2_a')
				}
			}
		}
                                                                        
		loc lb12_ate_`q' = max(`lb12_ate_`q'', -1)
		loc ub12_ate_`q' = min(`ub12_ate_`q'', 1)

	   	ereturn scalar ub12_ate_`QQ_`q''=`ub12_ate_`q''
	 	ereturn scalar lb12_ate_`QQ_`q''=`lb12_ate_`q''
		
	}

*! Worst Case Selection Model (j=2)

    *! Arbitrary Errors Model: Invoking only A1 (j=2 & i=1)
	forval q = 1/`nq' {
		if `Q_`q''==0 {				
			loc ub21_ate_`q' = `p11' + (1 - `mD') - `p10'
			loc lb21_ate_`q' = `p11' - `p10' - `mD'
		}
		else {
			loc ub21_ate_`q' = `p11' + (1 - `mD') - `p10' + min(`Q_`q'',`t0pos_`q''+`t1neg_`q'') 	
			loc lb21_ate_`q' = `p11' - `p10' - `mD' - min(`Q_`q'',`t1pos_`q''+`t0neg_`q'')		
		}

		loc lb21_ate_`q' = max(`lb21_ate_`q'', -1)
		loc ub21_ate_`q' = min(`ub21_ate_`q'', 1)
		            
		ereturn scalar ub21_ate_`QQ_`q''=`ub21_ate_`q''
	 	ereturn scalar lb21_ate_`QQ_`q''=`lb21_ate_`q''
		
	}

                   
    *! No False Positives Model: Invoking both A1 and A2 => Setting `t1pos' = 0 and `t0pos'= 0 (j=2 & i=2)
	forval q = 1/`nq' { 
		if `Q_`q''==0 {				
			loc ub22_ate_`q' = `ub21_ate_`q''
			loc lb22_ate_`q' = `lb21_ate_`q''
		}
		else {
			loc ub22_ate_`q' = `p11' + (1 - `mD') - `p10' + `t1neg_`q'' 	
			loc lb22_ate_`q' = `p11' - `p10' - `mD' - `t0neg_`q'' 		
		}

		loc lb22_ate_`q' = max(`lb22_ate_`q'', -1)
		loc ub22_ate_`q' = min(`ub22_ate_`q'', 1)
		            
	   	ereturn scalar ub22_ate_`QQ_`q''=`ub22_ate_`q''
	 	ereturn scalar lb22_ate_`QQ_`q''=`lb22_ate_`q''
		
	}


*! Monotone Treatment Selection (MTSn) Model (j=3)
	forval q = 1/`nq' {

		loc ub31_ate_`q' = `ub21_ate_`q''
		loc lb31_ate_`q' = `lb11_ate_`q''
		loc ub32_ate_`q' = `ub22_ate_`q''
		loc lb32_ate_`q' = `lb12_ate_`q''

		ereturn scalar ub31_ate_`QQ_`q''=`ub31_ate_`q''
		ereturn scalar lb31_ate_`QQ_`q''=`lb31_ate_`q''
		ereturn scalar ub32_ate_`QQ_`q''=`ub32_ate_`q''
		ereturn scalar lb32_ate_`QQ_`q''=`lb32_ate_`q''

	}


*! Monotone Treatment Selection (MTSp) Model (j=3p)
	forval q = 1/`nq' {

		loc ub31p_ate_`q' = `ub11_ate_`q''
		loc lb31p_ate_`q' = `lb21_ate_`q''
		loc ub32p_ate_`q' = `ub12_ate_`q''
		loc lb32p_ate_`q' = `lb22_ate_`q''

		ereturn scalar ub31p_ate_`QQ_`q''=`ub31p_ate_`q''
		ereturn scalar lb31p_ate_`QQ_`q''=`lb31p_ate_`q''
		ereturn scalar ub32p_ate_`QQ_`q''=`ub32p_ate_`q''
		ereturn scalar lb32p_ate_`QQ_`q''=`lb32p_ate_`q''

	}

	
*! MTSn and MTR Model (j=5)
	forval q = 1/`nq' {
		loc ub51_ate_`q' = `ub31_ate_`q''
		loc lb51_ate_`q' = max(`lb31_ate_`q'',0)
		loc ub52_ate_`q' = `ub32_ate_`q''
		loc lb52_ate_`q' = max(`lb32_ate_`q'',0)
                                                                        
	   	ereturn scalar ub51_ate_`QQ_`q''=`ub51_ate_`q''
	 	ereturn scalar lb51_ate_`QQ_`q''=`lb51_ate_`q''
	   	ereturn scalar ub52_ate_`QQ_`q''=`ub52_ate_`q''
	 	ereturn scalar lb52_ate_`QQ_`q''=`lb52_ate_`q''

	}

*! MTSp and MTR Model (j=5)
	forval q = 1/`nq' {
		loc ub51p_ate_`q' = `ub31p_ate_`q''
		loc lb51p_ate_`q' = max(`lb31p_ate_`q'',0)
		loc ub52p_ate_`q' = `ub32p_ate_`q''
		loc lb52p_ate_`q' = max(`lb32p_ate_`q'',0)
                                                                        
	   	ereturn scalar ub51p_ate_`QQ_`q''=`ub51p_ate_`q''
	 	ereturn scalar lb51p_ate_`QQ_`q''=`lb51p_ate_`q''
	   	ereturn scalar ub52p_ate_`QQ_`q''=`ub52p_ate_`q''
	 	ereturn scalar lb52p_ate_`QQ_`q''=`lb52p_ate_`q''

	}


*! Final results for presentation
	loc slist " "
	forval q=1/`nq' {
		loc slist "`slist' ub11_ate_`QQ_`q'' lb11_ate_`QQ_`q''"
		loc slist "`slist' ub12_ate_`QQ_`q'' lb12_ate_`QQ_`q''"
		loc slist "`slist' ub21_ate_`QQ_`q'' lb21_ate_`QQ_`q''"
		loc slist "`slist' ub22_ate_`QQ_`q'' lb22_ate_`QQ_`q''"
		loc slist "`slist' ub31_ate_`QQ_`q'' lb31_ate_`QQ_`q''"
		loc slist "`slist' ub32_ate_`QQ_`q'' lb32_ate_`QQ_`q''"
		loc slist "`slist' ub51_ate_`QQ_`q'' lb51_ate_`QQ_`q''"
		loc slist "`slist' ub52_ate_`QQ_`q'' lb52_ate_`QQ_`q''"
		loc slist "`slist' ub31p_ate_`QQ_`q'' lb31p_ate_`QQ_`q''"
		loc slist "`slist' ub32p_ate_`QQ_`q'' lb32p_ate_`QQ_`q''"
		loc slist "`slist' ub51p_ate_`QQ_`q'' lb51p_ate_`QQ_`q''"
		loc slist "`slist' ub52p_ate_`QQ_`q'' lb52p_ate_`QQ_`q''"
	}

	loc rlist " "
	forval q=1/`nq' {
		loc rlist `rlist' (e(ub11_ate_`QQ_`q'')) (e(lb11_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub12_ate_`QQ_`q'')) (e(lb12_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub21_ate_`QQ_`q'')) (e(lb21_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub22_ate_`QQ_`q'')) (e(lb22_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub31_ate_`QQ_`q'')) (e(lb31_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub32_ate_`QQ_`q'')) (e(lb32_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub51_ate_`QQ_`q'')) (e(lb51_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub52_ate_`QQ_`q'')) (e(lb52_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub31p_ate_`QQ_`q'')) (e(lb31p_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub32p_ate_`QQ_`q'')) (e(lb32p_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub51p_ate_`QQ_`q'')) (e(lb51p_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub52p_ate_`QQ_`q'')) (e(lb52p_ate_`QQ_`q''))
	}

	** Store results from first run as point estimates (prior to bootstrap replications) 
	foreach stat of loc slist {
		global pe1_`stat'=e(`stat')
	}
	
	
*! BOOTSTRAP CIs
	if "`bs'" != "" {
		foreach stat of loc slist {
			global pe2_`stat'=e(`stat')
		}	
	
		tempfile bsfile
		if "`survey'" != "" {
			qui svydes
			local str_count=r(N_strata)
			if `weights'==0 {
				if `str_count'>1 {
					qui bsweights bsw, reps(`reps') n(`npsu') replace
				}
				else {
					qui bsweights bsw, reps(`reps') n(`npsu') replace nosvy
				}
				qui svyset ${r_set} bsrweight(bsw*)
			}
			qui svy bootstrap `rlist', subpop(`touse') nodots saving(`bsfile', replace): ///
				tebounds `y' if `touse', t(`treat') c(`control') tr(`treatment') erates(`erates') np(`np') npsu(`npsu') ///
				nodisplay survey weights(1)
			drop bsw*
		}
		else {
			qui bootstrap `rlist', reps(`reps') nodots saving(`bsfile', replace): ///
				tebounds `y' if `touse', t(`treat') c(`control') tr(`treatment') erates(`erates') np(`np') npsu(`npsu') ///
				nodisplay 
		}
		preserve
		use `bsfile', clear
		if `"`saving'"' != `""' {
			qui save `"`saving'"', `replace'
		}		
		local z=0
		foreach stat of loc slist {
			local z=`z'+1
			rename _bs_`z' `stat'
			qui su `stat' if `stat' < .
			loc `stat'_sd=r(sd)
			loc nn = r(N)
		}
		
		loc ij "11 12 21 22 31 32 51 52 31p 32p 51p 52p"
		foreach r of loc ij {
			forval q=1/`nq' {
				
				if "`im'" == "" {
					** percentile method
					local low = (100-`level')/2
					local high = 100 - `low'
					_pctile lb`r'_ate_`QQ_`q'', p(`low')
					loc lb`r'_ate_`QQ_`q''_l=max(r(r1),-1)
					_pctile ub`r'_ate_`QQ_`q'', p(`high')
					loc ub`r'_ate_`QQ_`q''_u=min(r(r1),1)
				}
				else {
					loc delta = ${pe2_ub`r'_ate_`QQ_`q''} - ${pe2_lb`r'_ate_`QQ_`q''}
					loc s = 1/max(`lb`r'_ate_`QQ_`q''_sd',`ub`r'_ate_`QQ_`q''_sd')
					loc c = invnormal(1 - ((100-`level')/200))
					loc diff = 99999
					while `diff'>0.00001 {
						loc c = `c' - 0.00001
						loc d = normal(`c'+`s'*`delta') - normal(-`c') - (`level'/100)
						loc diff = min(abs(`d'),`diff')
						if `c' < 1 {
							noi di in red "Error with I-M CIs -> CbarN down to 1 .... `r'; `diff'"
							continue, break		
						}
					}
					local lb`r'_ate_`QQ_`q''_l = max(${pe2_lb`r'_ate_`QQ_`q''} - `c'*`lb`r'_ate_`QQ_`q''_sd', -1)
					local ub`r'_ate_`QQ_`q''_u = min(${pe2_ub`r'_ate_`QQ_`q''} + `c'*`ub`r'_ate_`QQ_`q''_sd', 1)				
				}
			}
		}
		
		restore
		loc slist " "
		forval q=1/`nq' {
			loc slist "`slist' ub11_ate_`QQ_`q'' ub12_ate_`QQ_`q'' ub21_ate_`QQ_`q'' ub22_ate_`QQ_`q''"
			loc slist "`slist' ub31_ate_`QQ_`q'' ub32_ate_`QQ_`q'' ub51_ate_`QQ_`q'' ub52_ate_`QQ_`q''" 
			loc slist "`slist' ub31p_ate_`QQ_`q'' ub32p_ate_`QQ_`q'' ub51p_ate_`QQ_`q'' ub52p_ate_`QQ_`q''"
		}
		foreach stat of loc slist {
			global ub_`stat'=``stat'_u'
		}
		loc slist " "
		forval q=1/`nq' {
			loc slist "`slist' lb11_ate_`QQ_`q'' lb12_ate_`QQ_`q'' lb21_ate_`QQ_`q'' lb22_ate_`QQ_`q''"
           		loc slist "`slist' lb31_ate_`QQ_`q'' lb32_ate_`QQ_`q'' lb51_ate_`QQ_`q'' lb52_ate_`QQ_`q''" 
			loc slist "`slist' lb31p_ate_`QQ_`q'' lb32p_ate_`QQ_`q'' lb51p_ate_`QQ_`q'' lb52p_ate_`QQ_`q''"
		}
		foreach stat of loc slist {
			global lb_`stat'=``stat'_l'	
		}
		ereturn scalar bsreps = `nn'
    	}
	
	if "`survey'" != "" {
		qui svyset, clear
		qui svyset ${r_set}
	}
	
*! MIV	
    	if "`miv'" != "" {
		tebounds_miv `y' if `touse', t(`treat') c(`control') tr(`treatment') miv(`miv') ncells(`ncells') ///
			erates(`erates') k(`k') np(`np') npsu(`npsu') `im' `bs' reps(`reps') saving(`saving') `replace' ///
			level(`level') `survey'
	}

	ereturn clear
	loc slist_pe " "
	loc slist_ub " "	
	loc slist_lb " "		
	forval q=1/`nq' {
		loc slist_pe "`slist_pe' ub11_ate_`QQ_`q'' lb11_ate_`QQ_`q'' ub12_ate_`QQ_`q'' lb12_ate_`QQ_`q''"
		loc slist_pe "`slist_pe' ub21_ate_`QQ_`q'' lb21_ate_`QQ_`q'' ub22_ate_`QQ_`q'' lb22_ate_`QQ_`q''"
		loc slist_pe "`slist_pe' ub31_ate_`QQ_`q'' lb31_ate_`QQ_`q'' ub32_ate_`QQ_`q'' lb32_ate_`QQ_`q''"
		loc slist_pe "`slist_pe' ub51_ate_`QQ_`q'' lb51_ate_`QQ_`q'' ub52_ate_`QQ_`q'' lb52_ate_`QQ_`q''"
		loc slist_pe "`slist_pe' ub31p_ate_`QQ_`q'' lb31p_ate_`QQ_`q'' ub32p_ate_`QQ_`q'' lb32p_ate_`QQ_`q''"
		loc slist_pe "`slist_pe' ub51p_ate_`QQ_`q'' lb51p_ate_`QQ_`q'' ub52p_ate_`QQ_`q'' lb52p_ate_`QQ_`q''"

		if "`miv'" != "" {
			loc slist_pe "`slist_pe' ub41_ate_`QQ_`q'' lb41_ate_`QQ_`q'' ub42_ate_`QQ_`q'' lb42_ate_`QQ_`q''"
			loc slist_pe "`slist_pe' ub43_ate_`QQ_`q'' lb43_ate_`QQ_`q'' ub44_ate_`QQ_`q'' lb44_ate_`QQ_`q''"
			loc slist_pe "`slist_pe' ub41p_ate_`QQ_`q'' lb41p_ate_`QQ_`q'' ub42p_ate_`QQ_`q'' lb42p_ate_`QQ_`q''"
			loc slist_pe "`slist_pe' ub43p_ate_`QQ_`q'' lb43p_ate_`QQ_`q'' ub44p_ate_`QQ_`q'' lb44p_ate_`QQ_`q''"
			
			** Adjustments to ensure MIV bounds are tighter than MTS/MTR bounds
			global pe1_ub41_ate_`QQ_`q''=min(${pe1_ub41_ate_`QQ_`q''},${pe1_ub31_ate_`QQ_`q''})
			global pe1_lb41_ate_`QQ_`q''=max(${pe1_lb41_ate_`QQ_`q''},${pe1_lb31_ate_`QQ_`q''})

			global pe1_ub42_ate_`QQ_`q''=min(${pe1_ub42_ate_`QQ_`q''},${pe1_ub32_ate_`QQ_`q''})
			global pe1_lb42_ate_`QQ_`q''=max(${pe1_lb42_ate_`QQ_`q''},${pe1_lb32_ate_`QQ_`q''})

			global pe1_ub41p_ate_`QQ_`q''=min(${pe1_ub41p_ate_`QQ_`q''},${pe1_ub31p_ate_`QQ_`q''})
			global pe1_lb41p_ate_`QQ_`q''=max(${pe1_lb41p_ate_`QQ_`q''},${pe1_lb31p_ate_`QQ_`q''})

			global pe1_ub42p_ate_`QQ_`q''=min(${pe1_ub42p_ate_`QQ_`q''},${pe1_ub32p_ate_`QQ_`q''})
			global pe1_lb42p_ate_`QQ_`q''=max(${pe1_lb42p_ate_`QQ_`q''},${pe1_lb32p_ate_`QQ_`q''})

			global pe1_ub43_ate_`QQ_`q''=min(${pe1_ub43_ate_`QQ_`q''},${pe1_ub51_ate_`QQ_`q''})
			global pe1_lb43_ate_`QQ_`q''=max(${pe1_lb43_ate_`QQ_`q''},${pe1_lb51_ate_`QQ_`q''})

			global pe1_ub44_ate_`QQ_`q''=min(${pe1_ub44_ate_`QQ_`q''},${pe1_ub52_ate_`QQ_`q''})
			global pe1_lb44_ate_`QQ_`q''=max(${pe1_lb44_ate_`QQ_`q''},${pe1_lb52_ate_`QQ_`q''})

			global pe1_ub43p_ate_`QQ_`q''=min(${pe1_ub43p_ate_`QQ_`q''},${pe1_ub51p_ate_`QQ_`q''})
			global pe1_lb43p_ate_`QQ_`q''=max(${pe1_lb43p_ate_`QQ_`q''},${pe1_lb51p_ate_`QQ_`q''})

			global pe1_ub44p_ate_`QQ_`q''=min(${pe1_ub44p_ate_`QQ_`q''},${pe1_ub52p_ate_`QQ_`q''})
			global pe1_lb44p_ate_`QQ_`q''=max(${pe1_lb44p_ate_`QQ_`q''},${pe1_lb52p_ate_`QQ_`q''})
			
			if "`bs'"!="" {
				global pe2_ub41_ate_`QQ_`q''=min(${pe2_ub41_ate_`QQ_`q''},${pe2_ub31_ate_`QQ_`q''})
				global pe2_lb41_ate_`QQ_`q''=max(${pe2_lb41_ate_`QQ_`q''},${pe2_lb31_ate_`QQ_`q''})

				global pe2_ub42_ate_`QQ_`q''=min(${pe2_ub42_ate_`QQ_`q''},${pe2_ub32_ate_`QQ_`q''})
				global pe2_lb42_ate_`QQ_`q''=max(${pe2_lb42_ate_`QQ_`q''},${pe2_lb32_ate_`QQ_`q''})

				global pe2_ub41p_ate_`QQ_`q''=min(${pe2_ub41p_ate_`QQ_`q''},${pe2_ub31p_ate_`QQ_`q''})
				global pe2_lb41p_ate_`QQ_`q''=max(${pe2_lb41p_ate_`QQ_`q''},${pe2_lb31p_ate_`QQ_`q''})

				global pe2_ub42p_ate_`QQ_`q''=min(${pe2_ub42p_ate_`QQ_`q''},${pe2_ub32p_ate_`QQ_`q''})
				global pe2_lb42p_ate_`QQ_`q''=max(${pe2_lb42p_ate_`QQ_`q''},${pe2_lb32p_ate_`QQ_`q''})

				global pe2_ub43_ate_`QQ_`q''=min(${pe2_ub43_ate_`QQ_`q''},${pe2_ub51_ate_`QQ_`q''})
				global pe2_lb43_ate_`QQ_`q''=max(${pe2_lb43_ate_`QQ_`q''},${pe2_lb51_ate_`QQ_`q''})

				global pe2_ub44_ate_`QQ_`q''=min(${pe2_ub44_ate_`QQ_`q''},${pe2_ub52_ate_`QQ_`q''})
				global pe2_lb44_ate_`QQ_`q''=max(${pe2_lb44_ate_`QQ_`q''},${pe2_lb52_ate_`QQ_`q''})

				global pe2_ub43p_ate_`QQ_`q''=min(${pe2_ub43p_ate_`QQ_`q''},${pe2_ub51p_ate_`QQ_`q''})
				global pe2_lb43p_ate_`QQ_`q''=max(${pe2_lb43p_ate_`QQ_`q''},${pe2_lb51p_ate_`QQ_`q''})

				global pe2_ub44p_ate_`QQ_`q''=min(${pe2_ub44p_ate_`QQ_`q''},${pe2_ub52p_ate_`QQ_`q''})
				global pe2_lb44p_ate_`QQ_`q''=max(${pe2_lb44p_ate_`QQ_`q''},${pe2_lb52p_ate_`QQ_`q''})
			}
			
		}

		if "`bs'" != "" {
			loc slist_lb "`slist_lb' lb11_ate_`QQ_`q'' lb12_ate_`QQ_`q'' lb21_ate_`QQ_`q'' lb22_ate_`QQ_`q''"
			loc slist_lb "`slist_lb' lb31_ate_`QQ_`q'' lb32_ate_`QQ_`q'' lb51_ate_`QQ_`q'' lb52_ate_`QQ_`q''"
			loc slist_lb "`slist_lb' lb31p_ate_`QQ_`q'' lb32p_ate_`QQ_`q'' lb51p_ate_`QQ_`q'' lb52p_ate_`QQ_`q''"	
	
			loc slist_ub "`slist_ub' ub11_ate_`QQ_`q'' ub12_ate_`QQ_`q'' ub21_ate_`QQ_`q'' ub22_ate_`QQ_`q''"
			loc slist_ub "`slist_ub' ub31_ate_`QQ_`q'' ub32_ate_`QQ_`q'' ub51_ate_`QQ_`q'' ub52_ate_`QQ_`q''"
			loc slist_ub "`slist_ub' ub31p_ate_`QQ_`q'' ub32p_ate_`QQ_`q'' ub51p_ate_`QQ_`q'' ub52p_ate_`QQ_`q''"
			if "`miv'" != "" {
				loc slist_lb "`slist_lb' lb41_ate_`QQ_`q'' lb42_ate_`QQ_`q'' lb43_ate_`QQ_`q'' lb44_ate_`QQ_`q''"
				loc slist_lb "`slist_lb' lb41p_ate_`QQ_`q'' lb42p_ate_`QQ_`q'' lb43p_ate_`QQ_`q'' lb44p_ate_`QQ_`q''"
			
				loc slist_ub "`slist_ub' ub41_ate_`QQ_`q'' ub42_ate_`QQ_`q'' ub43_ate_`QQ_`q'' ub44_ate_`QQ_`q''"
				loc slist_ub "`slist_ub' ub41p_ate_`QQ_`q'' ub42p_ate_`QQ_`q'' ub43p_ate_`QQ_`q'' ub44p_ate_`QQ_`q''"
				
				** Adjustments to ensure MIV bounds are tighter than MTS/MTR bounds				
				global ub_ub41_ate_`QQ_`q''=min(${ub_ub41_ate_`QQ_`q''},${ub_ub31_ate_`QQ_`q''})
				global lb_lb41_ate_`QQ_`q''=max(${lb_lb41_ate_`QQ_`q''},${lb_lb31_ate_`QQ_`q''})

				global ub_ub42_ate_`QQ_`q''=min(${ub_ub42_ate_`QQ_`q''},${ub_ub32_ate_`QQ_`q''})
				global lb_lb42_ate_`QQ_`q''=max(${lb_lb42_ate_`QQ_`q''},${lb_lb32_ate_`QQ_`q''})

				global ub_ub41p_ate_`QQ_`q''=min(${ub_ub41p_ate_`QQ_`q''},${ub_ub31p_ate_`QQ_`q''})
				global lb_lb41p_ate_`QQ_`q''=max(${lb_lb41p_ate_`QQ_`q''},${lb_lb31p_ate_`QQ_`q''})

				global ub_ub42p_ate_`QQ_`q''=min(${ub_ub42p_ate_`QQ_`q''},${ub_ub32p_ate_`QQ_`q''})
				global lb_lb42p_ate_`QQ_`q''=max(${lb_lb42p_ate_`QQ_`q''},${lb_lb32p_ate_`QQ_`q''})

				global ub_ub43_ate_`QQ_`q''=min(${ub_ub43_ate_`QQ_`q''},${ub_ub51_ate_`QQ_`q''})
				global lb_lb43_ate_`QQ_`q''=max(${lb_lb43_ate_`QQ_`q''},${lb_lb51_ate_`QQ_`q''})

				global ub_ub44_ate_`QQ_`q''=min(${ub_ub44_ate_`QQ_`q''},${ub_ub52_ate_`QQ_`q''})
				global lb_lb44_ate_`QQ_`q''=max(${lb_lb44_ate_`QQ_`q''},${lb_lb52_ate_`QQ_`q''})

				global ub_ub43p_ate_`QQ_`q''=min(${ub_ub43p_ate_`QQ_`q''},${ub_ub51p_ate_`QQ_`q''})
				global lb_lb43p_ate_`QQ_`q''=max(${lb_lb43p_ate_`QQ_`q''},${lb_lb51p_ate_`QQ_`q''})

				global ub_ub44p_ate_`QQ_`q''=min(${ub_ub44p_ate_`QQ_`q''},${ub_ub52p_ate_`QQ_`q''})
				global lb_lb44p_ate_`QQ_`q''=max(${lb_lb44p_ate_`QQ_`q''},${lb_lb52p_ate_`QQ_`q''})

			}
		}
	}
    
	if "`bs'" == "" {
		foreach stat of loc slist_pe {
			ereturn scalar `stat'=${pe1_`stat'}			
		}
	}
	if "`bs'" != "" {
		foreach stat of loc slist_pe {
			ereturn scalar `stat'=${pe2_`stat'}
		}	
		foreach stat of loc slist_lb {
			ereturn scalar `stat'_l=${lb_`stat'}
		}
		foreach stat of loc slist_ub {
			ereturn scalar `stat'_u=${ub_`stat'}
		}		
	}	

*! DISPLAY RESULTS
		
	if "`nodisplay'" == "" {
		di in text "{hline 76}"
		di in text "Outcome:  `y'"
		di in text "Treatment: `treat'"
		if "`miv'" != "" {
				di in text "Number of pseudo-samples used in MIV bias correction: " `k'
				di in text "Number of observations per MIV cell: "
				forval i=1/`ncells' {
					di in text "   Cell `i': " ${nmiv`i'}
				}
		}
		if "`bs'" != "" {
			if "`im'" == "" {
				di in text "Number of bootstrap reps for `level'% CIs: " `reps'
			}
			else {
				di in text "Number of bootstrap reps for `level'% I-M CIs: " `reps'
			}
		}
		di in text "{hline 76}"
		di " Error Rate " _column(17) "| Arbitrary Errors"  _column(50) "| No False Positives" 
		di in text "{hline 76}"  
		di "Exogenous Selection Model"
		forval q = 1/`nq' {
		
			di	_column(3) "`Q_`q''" _column(17) "[" %7.3f e(lb11_ate_`QQ_`q'') "," %7.3f e(ub11_ate_`QQ_`q'') "] p.e." ///
				_column(50) "[" %7.3f e(lb12_ate_`QQ_`q'') "," %7.3f e(ub12_ate_`QQ_`q'') %7.3f "] p.e."		
		
			if "`bs'"!="" {
				di 	_column(17) "[" %7.3f e(lb11_ate_`QQ_`q''_l) "," %7.3f e(ub11_ate_`QQ_`q''_u) "] CI" ///
					_column(50) "[" %7.3f e(lb12_ate_`QQ_`q''_l) "," %7.3f e(ub12_ate_`QQ_`q''_u) "] CI" 
			}
		}

		di in text "{hline 76}"
		di "No Monotonicity Assumptions (Worst Case Selection)"
		forval q = 1/`nq' {
		
			di	_column(3) "`Q_`q''" _column(17) "[" %7.3f e(lb21_ate_`QQ_`q'') "," %7.3f e(ub21_ate_`QQ_`q'') "] p.e." ///
				_column(50) "[" %7.3f e(lb22_ate_`QQ_`q'') "," %7.3f e(ub22_ate_`QQ_`q'') %7.3f "] p.e."			

			if "`bs'"!="" {
				di	_column(17) "[" %7.3f e(lb21_ate_`QQ_`q''_l) "," %7.3f e(ub21_ate_`QQ_`q''_u) "] CI" ///
					_column(50) "[" %7.3f e(lb22_ate_`QQ_`q''_l) "," %7.3f e(ub22_ate_`QQ_`q''_u) "] CI" 
			}
		}

		di in text "{hline 76}"
		di "MTS Assumption: Negative Selection"
		forval q = 1/`nq' {

			di	_column(3) "`Q_`q''" _column(17) "[" %7.3f e(lb31_ate_`QQ_`q'') "," %7.3f e(ub31_ate_`QQ_`q'') "] p.e."  ///
				_column(50) "[" %7.3f e(lb32_ate_`QQ_`q'') "," %7.3f e(ub32_ate_`QQ_`q'') %7.3f "] p.e."
		
			if "`bs'"!="" {
				di	_column(17) "[" %7.3f e(lb31_ate_`QQ_`q''_l) "," %7.3f e(ub31_ate_`QQ_`q''_u) "] CI" ///
					_column(50) "[" %7.3f e(lb32_ate_`QQ_`q''_l) "," %7.3f e(ub32_ate_`QQ_`q''_u) "] CI"	
			}
		}

		di in text "{hline 76}"
		di "MTS Assumption: Positive Selection"
		forval q = 1/`nq' {

			di	_column(3) "`Q_`q''" _column(17) "[" %7.3f e(lb31p_ate_`QQ_`q'') "," %7.3f e(ub31p_ate_`QQ_`q'') "] p.e."  ///
				_column(50) "[" %7.3f e(lb32p_ate_`QQ_`q'') "," %7.3f e(ub32p_ate_`QQ_`q'') %7.3f "] p.e."
		
			if "`bs'"!="" {
				di	_column(17) "[" %7.3f e(lb31p_ate_`QQ_`q''_l) "," %7.3f e(ub31p_ate_`QQ_`q''_u) "] CI" ///
					_column(50) "[" %7.3f e(lb32p_ate_`QQ_`q''_l) "," %7.3f e(ub32p_ate_`QQ_`q''_u) "] CI"	
			}		
		}

		di in text "{hline 76}"
		di "MTS and MTR Assumptions: Negative Selection"
		forval q = 1/`nq' {

			di	_column(3) "`Q_`q''" _column(17) "[" %7.3f e(lb51_ate_`QQ_`q'') "," %7.3f e(ub51_ate_`QQ_`q'') "] p.e." ///
				_column(50) "[" %7.3f e(lb52_ate_`QQ_`q'') "," %7.3f e(ub52_ate_`QQ_`q'') %7.3f "] p.e."
		
			if "`bs'"!="" {
				di	_column(17) "[" %7.3f e(lb51_ate_`QQ_`q''_l) "," %7.3f e(ub51_ate_`QQ_`q''_u) "] CI" ///
					_column(50) "[" %7.3f e(lb52_ate_`QQ_`q''_l) "," %7.3f e(ub52_ate_`QQ_`q''_u) "] CI"	
			}
		}
		
		di in text "{hline 76}"
		di "MTS and MTR Assumptions: Positive Selection"
		forval q = 1/`nq' {
		
			di	_column(3) "`Q_`q''" _column(17) "[" %7.3f e(lb51p_ate_`QQ_`q'') "," %7.3f e(ub51p_ate_`QQ_`q'') "] p.e." ///
				_column(50) "[" %7.3f e(lb52p_ate_`QQ_`q'') "," %7.3f e(ub52p_ate_`QQ_`q'') %7.3f "] p.e."	
				
			if "`bs'"!="" {
				di	_column(17) "[" %7.3f e(lb51p_ate_`QQ_`q''_l) "," %7.3f e(ub51p_ate_`QQ_`q''_u) "] CI" ///
					_column(50) "[" %7.3f e(lb52p_ate_`QQ_`q''_l) "," %7.3f e(ub52p_ate_`QQ_`q''_u) "] CI"	
			}
		}
		
		if "`miv'" != "" {
			di in text "{hline 76}"  
			di "MIV and MTS Assumptions: Negative Selection"
			forval q = 1/`nq' {
				di	_column(3) "`Q_`q''" _column(17) "[" %7.3f e(lb41_ate_`QQ_`q'') "," %7.3f e(ub41_ate_`QQ_`q'') "] p.e."  ///
					_column(50) "[" %7.3f e(lb42_ate_`QQ_`q'') "," %7.3f e(ub42_ate_`QQ_`q'')  %7.3f "] p.e."
				if "`bs'"!="" {
					di	_column(17) "[" %7.3f e(lb41_ate_`QQ_`q''_l) "," %7.3f e(ub41_ate_`QQ_`q''_u) "] CI" ///
						_column(50) "[" %7.3f e(lb42_ate_`QQ_`q''_l) "," %7.3f e(ub42_ate_`QQ_`q''_u) "] CI"	
				}
				if `k'>0 {
					di	_column(17) " " %7.3f ${bias_lb41_ate_`QQ_`q''} " " %7.3f ${bias_ub41_ate_`QQ_`q''} "  Bias" ///
						_column(50) " " %7.3f ${bias_lb42_ate_`QQ_`q''} " " %7.3f ${bias_ub42_ate_`QQ_`q''} "  Bias"
				}
			}

			di in text "{hline 76}"
			di "MIV and MTS Assumptions: Positive Selection"
			forval q = 1/`nq' {
				di	_column(3) "`Q_`q''" _column(17) "[" %7.3f e(lb41p_ate_`QQ_`q'') "," %7.3f e(ub41p_ate_`QQ_`q'') "] p.e."  ///
					_column(50) "[" %7.3f e(lb42p_ate_`QQ_`q'') "," %7.3f e(ub42p_ate_`QQ_`q'')  %7.3f "] p.e."
				if "`bs'"!="" {
					di	_column(17) "[" %7.3f e(lb41p_ate_`QQ_`q''_l) "," %7.3f e(ub41p_ate_`QQ_`q''_u) "] CI" ///
						_column(50) "[" %7.3f e(lb42p_ate_`QQ_`q''_l) "," %7.3f e(ub42p_ate_`QQ_`q''_u) "] CI"	
				}
				if `k'>0 {
					di	_column(17) " " %7.3f ${bias_lb41p_ate_`QQ_`q''} " " %7.3f ${bias_ub41p_ate_`QQ_`q''} "  Bias" ///
						_column(50) " " %7.3f ${bias_lb42p_ate_`QQ_`q''} " " %7.3f ${bias_ub42p_ate_`QQ_`q''} "  Bias"
				}
			}
		
			di in text "{hline 76}"  
			di "MIV, MTS, MTR Assumptions: Negative Selection"
			forval q = 1/`nq' {
				di	_column(3) "`Q_`q''" _column(17) "[" %7.3f e(lb43_ate_`QQ_`q'') "," %7.3f e(ub43_ate_`QQ_`q'') "] p.e."  ///
					_column(50) "[" %7.3f e(lb44_ate_`QQ_`q'') "," %7.3f e(ub44_ate_`QQ_`q'')  %7.3f "] p.e."
				if "`bs'"!="" {
					di	_column(17) "[" %7.3f e(lb43_ate_`QQ_`q''_l) "," %7.3f e(ub43_ate_`QQ_`q''_u) "] CI" ///
						_column(50) "[" %7.3f e(lb44_ate_`QQ_`q''_l) "," %7.3f e(ub44_ate_`QQ_`q''_u) "] CI"	
				}
				if `k'>0 {
					di	_column(17) " " %7.3f ${bias_lb43_ate_`QQ_`q''} " " %7.3f ${bias_ub43_ate_`QQ_`q''} "  Bias" ///
						_column(50) " " %7.3f ${bias_lb44_ate_`QQ_`q''} " " %7.3f ${bias_ub44_ate_`QQ_`q''} "  Bias"
				}
			}
		
			di in text "{hline 76}"
			di "MIV, MTS, MTR Assumptions: Positive Selection"
			forval q = 1/`nq' {
				di	_column(3) "`Q_`q''" _column(17) "[" %7.3f e(lb43p_ate_`QQ_`q'') "," %7.3f e(ub43p_ate_`QQ_`q'') "] p.e."  ///
					_column(50) "[" %7.3f e(lb44p_ate_`QQ_`q'') "," %7.3f e(ub44p_ate_`QQ_`q'')  %7.3f "] p.e."
				if "`bs'"!="" {
					di	_column(17) "[" %7.3f e(lb43p_ate_`QQ_`q''_l) "," %7.3f e(ub43p_ate_`QQ_`q''_u) "] CI" ///
					_column(50) "[" %7.3f e(lb44p_ate_`QQ_`q''_l) "," %7.3f e(ub44p_ate_`QQ_`q''_u) "] CI"	
				}
				if `k'>0 {
					di	_column(17) " " %7.3f ${bias_lb43p_ate_`QQ_`q''} " " %7.3f ${bias_ub43p_ate_`QQ_`q''} "  Bias" ///
						_column(50) " " %7.3f ${bias_lb44p_ate_`QQ_`q''} " " %7.3f ${bias_ub44p_ate_`QQ_`q''} "  Bias"
				}
			}
		
			di in text "{hline 76}"		
		}
	}

*! DISPLAY GRAPHS

	if "`graph'" != "" {
		preserve
		clear
		qui set obs `nq'
		tempvar er lb1 ub1 lb2 ub2 LB1 UB1 LB2 UB2 Lb1 Lb2 Ub1 Ub2 lB1 lB2 uB1 uB2
		loc vars "`er' `lb1' `ub1' `lb2' `ub2' `LB1' `UB1' `LB2' `UB2' `Lb1' `Lb2' `Ub1' `Ub2' `lB1' `lB2' `uB1' `uB2'"


** EXOGENOUS & WORST-CASE

		foreach v in `vars' {
			qui g `v'=.
		}
		forval q=1/`nq' {
			qui replace `er'=`QQ_`q''/100 if _n==`q'
			qui replace `lb1'=e(lb11_ate_`QQ_`q'') if _n==`q'
			qui replace `ub1'=e(ub11_ate_`QQ_`q'') if _n==`q'
			qui replace `lb2'=e(lb12_ate_`QQ_`q'') if _n==`q'
			qui replace `ub2'=e(ub12_ate_`QQ_`q'') if _n==`q'
			qui replace `LB1'=e(lb21_ate_`QQ_`q'') if _n==`q'
			qui replace `UB1'=e(ub21_ate_`QQ_`q'') if _n==`q'
			qui replace `LB2'=e(lb22_ate_`QQ_`q'') if _n==`q'
			qui replace `UB2'=e(ub22_ate_`QQ_`q'') if _n==`q'
		}
		qui su `er'
		loc maxq = r(max)
		lab var `lb1' "Exogenous: Arbitrary Errors"
		lab var `lb2' "Exogenous: No False Positives"
		lab var `LB1' "No Selection: Arbitrary Errors"
		lab var `LB2' "No Selection: No False Positives"
		format `lb1' `ub1' `lb2' `ub2' `LB1' `UB1' `LB2' `UB2' %4.3f
		format `er' %3.2f

		tw (connected `lb1' `ub1' `lb2' `ub2' `er', clpattern(solid solid dash dash) lcolor(red red blue blue) ms(i i i i) ///
			mlabp(6 6 6 6) mlabel(`lb1' `ub1' `lb2' `ub2') mlabs(tiny tiny tiny tiny) mlabc(red red blue blue))  ///
		(connected `LB1' `UB1' `LB2' `UB2' `er', clpattern(longdash longdash shortdash_dot shortdash_dot) lcolor(black black olive olive) ms(i i i i) ///
			mlabp(6 6 6 6) mlabel(`LB1' `UB1' `LB2' `UB2') mlabs(tiny tiny tiny tiny) mlabc(black black olive olive)),  ///
		title("Exogenous and No Selection Assumptions") leg(size(small) order(1 3 5 7)) ylab(-0.5(.5)1, format(%3.2f)) ///
		xtitle("Maximum Allowed Degree of Misclassification") ytitle("ATE") yline(0) saving(`saving'_EXO_WRST, `replace') xlab(`erates', grid) /// 
		graphregion(fcolor(white)) plotregion(fcolor(white)) graphregion(ifcolor(white)) plotregion(ifcolor(white)) graphregion(ilcolor(white)) plotregion(ilcolor(white))


** MONOTONE TREATMENT SELECTION - Negative

		foreach v in `vars' {
			qui replace `v'=.
		}
		forval q=1/`nq' {
			qui replace `er'=`QQ_`q''/100 if _n==`q'
			qui replace `lb1'=e(lb31_ate_`QQ_`q'') if _n==`q'
			qui replace `ub1'=e(ub31_ate_`QQ_`q'') if _n==`q'
			qui replace `lb2'=e(lb32_ate_`QQ_`q'') if _n==`q'
			qui replace `ub2'=e(ub32_ate_`QQ_`q'') if _n==`q'
			qui replace `LB1'=e(lb41_ate_`QQ_`q'') if _n==`q'
			qui replace `UB1'=e(ub41_ate_`QQ_`q'') if _n==`q'
			qui replace `LB2'=e(lb42_ate_`QQ_`q'') if _n==`q'
			qui replace `UB2'=e(ub42_ate_`QQ_`q'') if _n==`q'
			qui replace `Lb1'=e(lb51_ate_`QQ_`q'') if _n==`q'
			qui replace `Ub1'=e(ub51_ate_`QQ_`q'') if _n==`q'
			qui replace `Lb2'=e(lb52_ate_`QQ_`q'') if _n==`q'
			qui replace `Ub2'=e(ub52_ate_`QQ_`q'') if _n==`q'
			qui replace `lB1'=e(lb43_ate_`QQ_`q'') if _n==`q'
			qui replace `uB1'=e(ub43_ate_`QQ_`q'') if _n==`q'
			qui replace `lB2'=e(lb44_ate_`QQ_`q'') if _n==`q'
			qui replace `uB2'=e(ub44_ate_`QQ_`q'') if _n==`q'			

		}
		qui su `er'
		loc maxq = r(max)
		lab var `lb1' "MTS Alone"
		lab var `lb2' "MTS Alone"
		lab var `LB1' "Joint MTS & MIV"
		lab var `LB2' "Joint MTS & MIV"
		lab var `Lb1' "Joint MTS & MTR"
		lab var `Lb2' "Joint MTS & MTR"
		lab var `lB1' "Joint MTS & MTR & MIV"
		lab var `lB2' "Joint MTS & MTR & MIV"		
		format `lb1' `ub1' `LB1' `UB1' `Lb1' `Ub1' `lB1' `uB1' %4.3f
		format `lb2' `ub2' `LB2' `UB2' `Lb2' `Ub2' `lB2' `uB2' %4.3f
		format `er' %3.2f

*** MTSn alone or MTSn & MIV Combined (Arbitrary Errors Only)
		tw (connected `lb1' `ub1' `er', clpattern(solid solid) lcolor(red red) ms(i i) mlabp(6 6) mlabel(`lb1' `ub1') mlabs(tiny tiny) mlabc(red red)) ///
		(connected `LB1' `UB1' `er', clpattern(longdash longdash) lcolor(blue blue) ms(i i) mlabp(6 6) mlabel(`LB1' `UB1') mlabs(tiny tiny) mlabc(blue blue)), ///
		title("MTSn & MTSn-IV Assumptions") subtitle("Arbitrary Errors") xtitle("Maximum Allowed Degree of Misclassification") ///
		ytitle("ATE") yline(0) saving(`saving'_MTSn_MTSnMIV_AE, `replace') xlab(`erates', grid) leg(size(small) order(1 3) r(2)) ylab(-0.5(.5)1, format(%3.2f)) /// 
		graphregion(fcolor(white)) plotregion(fcolor(white)) graphregion(ifcolor(white)) plotregion(ifcolor(white)) graphregion(ilcolor(white)) plotregion(ilcolor(white))

*** MTSn & MTR Combined, MTSn & MTR & MIV Combined (Arbitrary Errors Only)
		tw (connected `Lb1' `Ub1' `er', clpattern(solid solid) lcolor(red red) ms(i i) mlabp(6 6) mlabel(`Lb1' `Ub1') mlabs(tiny tiny) mlabc(red red)) ///
		(connected `lB1' `uB1' `er', clpattern(longdash longdash) lcolor(blue blue) ms(i i) mlabp(6 6) mlabel(`lB1' `uB1') mlabs(tiny tiny) mlabc(blue blue)), ///
		title("MTSn-MTR & MTSn-MTR-MIV Assumptions") subtitle("Arbitrary Errors") xtitle("Maximum Allowed Degree of Misclassification") ///
		ytitle("ATE") yline(0) saving(`saving'_MTSnMTR_MTSnMTRMIV_AE, `replace') xlab(`erates', grid) leg(size(small) order(1 3) r(2)) ylab(-0.5(.5)1, format(%3.2f)) /// 
		graphregion(fcolor(white)) plotregion(fcolor(white)) graphregion(ifcolor(white)) plotregion(ifcolor(white)) graphregion(ilcolor(white)) plotregion(ilcolor(white))
		
*** MTSn alone or MTSn & MIV Combined (No False Positive Errors Only)
		tw (connected `lb2' `ub2' `er', clpattern(solid solid) lcolor(red red) ms(i i) mlabp(6 6 6 6) mlabel(`lb2' `ub2') mlabs(tiny tiny tiny tiny) mlabc(red red)) ///
		(connected `LB2' `UB2' `er', clpattern(longdash longdash) lcolor(blue blue) ms(i i) mlabp(6 6 6 6) mlabel(`LB2' `UB2') mlabs(tiny tiny tiny tiny) mlabc(blue blue)), ///
		title("MTSn & MTSn-MIV Assumptions") subtitle("No False Positive Errors") xtitle("Maximum Allowed Degree of Misclassification") ///
		ytitle("ATE") yline(0) saving(`saving'_MTSn_MTSnMIV_FP, `replace') xlab(`erates', grid) leg(size(small) order(1 3) r(2)) ylab(-0.5(.5)1, format(%3.2f)) /// 
		graphregion(fcolor(white)) plotregion(fcolor(white)) graphregion(ifcolor(white)) plotregion(ifcolor(white)) graphregion(ilcolor(white)) plotregion(ilcolor(white))

*** MTSn & MTR Combined, MTSn & MTR & MIV Combined (No False Positive Errors Only)
		tw (connected `Lb2' `Ub2' `er', clpattern(solid solid) lcolor(red red) ms(i i) mlabp(6 6 6 6) mlabel(`Lb2' `Ub2') mlabs(tiny tiny tiny tiny) mlabc(red red)) ///
		(connected `lB2' `uB2' `er', clpattern(longdash longdash) lcolor(blue blue) ms(i i) mlabp(6 6 6 6) mlabel(`lB2' `uB2') mlabs(tiny tiny tiny tiny) mlabc(blue blue)), ///
		title("MTSn-MTR & MTSn-MTR-MIV Assumptions") subtitle("No False Positive Errors") xtitle("Maximum Allowed Degree of Misclassification") ///
		ytitle("ATE") yline(0) saving(`saving'_MTSnMTR_MTSnMTRMIV_FP, `replace') xlab(`erates', grid) leg(size(small) order(1 3) r(2)) ylab(-0.5(.5)1, format(%3.2f)) /// 
		graphregion(fcolor(white)) plotregion(fcolor(white)) graphregion(ifcolor(white)) plotregion(ifcolor(white)) graphregion(ilcolor(white)) plotregion(ilcolor(white))
		
		
** MONOTONE TREATMENT SELECTION - Positive

		foreach v in `vars' {
			qui replace `v'=.
		}
		forval q=1/`nq' {
			qui replace `er'=`QQ_`q''/100 if _n==`q'
			qui replace `lb1'=e(lb31p_ate_`QQ_`q'') if _n==`q'
			qui replace `ub1'=e(ub31p_ate_`QQ_`q'') if _n==`q'
			qui replace `lb2'=e(lb32p_ate_`QQ_`q'') if _n==`q'
			qui replace `ub2'=e(ub32p_ate_`QQ_`q'') if _n==`q'
			qui replace `LB1'=e(lb41p_ate_`QQ_`q'') if _n==`q'
			qui replace `UB1'=e(ub41p_ate_`QQ_`q'') if _n==`q'
			qui replace `LB2'=e(lb42p_ate_`QQ_`q'') if _n==`q'
			qui replace `UB2'=e(ub42p_ate_`QQ_`q'') if _n==`q'
			qui replace `Lb1'=e(lb51p_ate_`QQ_`q'') if _n==`q'
			qui replace `Ub1'=e(ub51p_ate_`QQ_`q'') if _n==`q'
			qui replace `Lb2'=e(lb52p_ate_`QQ_`q'') if _n==`q'
			qui replace `Ub2'=e(ub52p_ate_`QQ_`q'') if _n==`q'
			qui replace `lB1'=e(lb43p_ate_`QQ_`q'') if _n==`q'
			qui replace `uB1'=e(ub43p_ate_`QQ_`q'') if _n==`q'
			qui replace `lB2'=e(lb44p_ate_`QQ_`q'') if _n==`q'
			qui replace `uB2'=e(ub44p_ate_`QQ_`q'') if _n==`q'			

		}
		qui su `er'
		loc maxq = r(max)
		lab var `lb1' "MTS Alone"
		lab var `lb2' "MTS Alone"
		lab var `LB1' "Joint MTS & MIV"
		lab var `LB2' "Joint MTS & MIV"
		lab var `Lb1' "Joint MTS & MTR"
		lab var `Lb2' "Joint MTS & MTR"
		lab var `lB1' "Joint MTS & MTR & MIV"
		lab var `lB2' "Joint MTS & MTR & MIV"				
		format `lb1' `ub1' `LB1' `UB1' `Lb1' `Ub1' `lB1' `uB1' %4.3f
		format `lb2' `ub2' `LB2' `UB2' `Lb2' `Ub2' `lB2' `uB2' %4.3f
		format `er' %3.2f

*** MTSp alone or MTSp & MIV Combined (Arbitrary Errors Only)
		tw (connected `lb1' `ub1' `er', clpattern(solid solid) lcolor(red red) ms(i i) mlabp(6 6) mlabel(`lb1' `ub1') mlabs(tiny tiny) mlabc(red red)) ///
		(connected `LB1' `UB1' `er', clpattern(longdash longdash) lcolor(blue blue) ms(i i) mlabp(6 6) mlabel(`LB1' `UB1') mlabs(tiny tiny) mlabc(blue blue)), ///
		title("MTSp & MTSp-IV Assumptions") subtitle("Arbitrary Errors") xtitle("Maximum Allowed Degree of Misclassification") ///
		ytitle("ATE") yline(0) saving(`saving'_MTSp_MTSpMIV_AE, `replace') xlab(`erates', grid) leg(size(small) order(1 3) r(2)) ylab(-0.5(.5)1, format(%3.2f)) /// 
		graphregion(fcolor(white)) plotregion(fcolor(white)) graphregion(ifcolor(white)) plotregion(ifcolor(white)) graphregion(ilcolor(white)) plotregion(ilcolor(white))

*** MTSp & MTR Combined, MTSp & MTR & MIV Combined (Arbitrary Errors Only)
		tw (connected `Lb1' `Ub1' `er', clpattern(solid solid) lcolor(red red) ms(i i) mlabp(6 6) mlabel(`Lb1' `Ub1') mlabs(tiny tiny) mlabc(red red)) ///
		(connected `lB1' `uB1' `er', clpattern(longdash longdash) lcolor(blue blue) ms(i i) mlabp(6 6) mlabel(`lB1' `uB1') mlabs(tiny tiny) mlabc(blue blue)), ///
		title("MTSp-MTR & MTSp-MTR-MIV Assumptions") subtitle("Arbitrary Errors") xtitle("Maximum Allowed Degree of Misclassification") ///
		ytitle("ATE") yline(0) saving(`saving'_MTSpMTR_MTSpMTRMIV_AE, `replace') xlab(`erates', grid) leg(size(small) order(1 3) r(2)) ylab(-0.5(.5)1, format(%3.2f)) /// 
		graphregion(fcolor(white)) plotregion(fcolor(white)) graphregion(ifcolor(white)) plotregion(ifcolor(white)) graphregion(ilcolor(white)) plotregion(ilcolor(white))
		
*** MTSp alone or MTSp & MIV Combined (No False Positive Errors Only)
		tw (connected `lb2' `ub2' `er', clpattern(solid solid) lcolor(red red) ms(i i) mlabp(6 6 6 6) mlabel(`lb2' `ub2') mlabs(tiny tiny tiny tiny) mlabc(red red)) ///
		(connected `LB2' `UB2' `er', clpattern(longdash longdash) lcolor(blue blue) ms(i i) mlabp(6 6 6 6) mlabel(`LB2' `UB2') mlabs(tiny tiny tiny tiny) mlabc(blue blue)), ///
		title("MTSp & MTSp-MIV Assumptions") subtitle("No False Positive Errors") xtitle("Maximum Allowed Degree of Misclassification") ///
		ytitle("ATE") yline(0) saving(`saving'_MTSp_MTSpMIV_FP, `replace') xlab(`erates', grid) leg(size(small) order(1 3) r(2)) ylab(-0.5(.5)1, format(%3.2f)) /// 
		graphregion(fcolor(white)) plotregion(fcolor(white)) graphregion(ifcolor(white)) plotregion(ifcolor(white)) graphregion(ilcolor(white)) plotregion(ilcolor(white))

*** MTSp & MTR Combined, MTSp & MTR & MIV Combined (No False Positive Errors Only)
		tw (connected `Lb2' `Ub2' `er', clpattern(solid solid) lcolor(red red) ms(i i) mlabp(6 6 6 6) mlabel(`Lb2' `Ub2') mlabs(tiny tiny tiny tiny) mlabc(red red)) ///
		(connected `lB2' `uB2' `er', clpattern(longdash longdash) lcolor(blue blue) ms(i i) mlabp(6 6 6 6) mlabel(`lB2' `uB2') mlabs(tiny tiny tiny tiny) mlabc(blue blue)), ///
		title("MTSp-MTR & MTSp-MTR-MIV Assumptions") subtitle("No False Positive Errors") xtitle("Maximum Allowed Degree of Misclassification") ///
		ytitle("ATE") yline(0) saving(`saving'_MTSpMTR_MTSpMTRMIV_FP, `replace') xlab(`erates', grid) leg(size(small) order(1 3) r(2)) ylab(-0.5(.5)1, format(%3.2f)) /// 
		graphregion(fcolor(white)) plotregion(fcolor(white)) graphregion(ifcolor(white)) plotregion(ifcolor(white)) graphregion(ilcolor(white)) plotregion(ilcolor(white))

	}

end



program define SetQ /* <nothing> | # [,] # ... */ , rclass
	if "`*'"=="" {
		ret loc quants "0.5"
		exit
	}
	loc orig "`*'"
	tokenize "`*'", parse(" ,")

	while "`1'" != "" {
		FixNumb "`orig'" `1'
		ret loc quants "`return(quants)' `r(q)'"
		mac shift 
		if "`1'"=="," {
			mac shift
		}
	}
end

program define FixNumb /* # */ , rclass
	loc orig "`1'"
	mac shift
	capture confirm number `1'
	if _rc {
		Invalid "`orig'" "`1' not a number"
	}
	if `1' >= 1 {
		ret loc q = `1'/100
	}
	else 	ret loc q `1'
	if `return(q)'<0 | `return(q)'>1 {
		Invalid "`orig'" "`return(q)' out of range"
	}
end
	
program define Invalid /* "<orig>" "<extra>" */
	di in red "quantiles(`1') invalid"
	if "`2'" != "" {
		di in red "`2'"
	}
	exit 198
end	
