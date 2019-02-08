*!version 1.6
*!date: 21apr2014 v1.6
*!v1.5 --> includes svy bootstrap and MIV+MTR+MTS bounds
*!v1.6 --> includes grid search for relevant MIV estimators

*!to do: can speed it altering grid search in exo bounds to fix increment rather than np

*! y: binary outcomes (1 = "good thing" ... MTS- coded assuming negative selection; treated have worse outcomes conditional on treatment status)
*! y: binary outcomes (1 = "good thing" ... MTS+ coded assuming positive selection; treated have better outcomes conditional on treatment status)
*! D: binary treatment (1 = "good thing" ... MTR coded assuming LB ATE is zero)
*! Z: MIV (IV increases Pr(y=1|D))

program tebounds_miv, eclass properties(svyb)
	version 10.0
	#delimit ;
	syntax varlist (min=1 max=1) [if] [in] [pw iw], Treat(varname) MIV(varname)
		[Control(int 0) TReatment(int 1) NCells(int 5) ERATES(string) K(int 100) NP(int 500)
		IM BS REPS(int 100) NPSU(int -1) SAving(string) REPLACE LEVEL(int 95) Survey];
	marksample touse;
	#delimit cr

	gettoken y: varlist
	
******************************************************************
** 				   Notes					    ** 
******************************************************************
* Model 41  = Monotone IV (MIV) and MTS- Model and i=1
* Model 41p = Monotone IV (MIV) and MTS+ Model and i=1
* Model 42  = Monotone IV (MIV) and MTS- Model and i=2
* Model 42p = Monotone IV (MIV) and MTS+ Model and i=2
* Model 43  = Monotone IV (MIV) and MTS- and MTR and i=1
* Model 43p = Monotone IV (MIV) and MTS+ and MTR and i=1
* Model 44  = Monotone IV (MIV) and MTS- and MTR and i=2
* Model 44p = Monotone IV (MIV) and MTS+ and MTR and i=2

* i = 1 for Assumption A1 only (Arbitrary Errors Model)
* i = 2 for both Assumptions A1 and A2 (No False Positives Model)

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
	if _rc & "`survey'" != "" {
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
	
*creating MIV ... 
*  if takes on <= `ncells' values, leave; 
*  otherwise, discretize into `ncells' groups based on deciles

	qui g double `z'=`miv'
	qui cap tab `z', matrow(`A')	
	if _rc {
		if "`survey'" != "" {
			xtile `zz' = `z' if `touse' [${wtype} ${wexp}], nq(`ncells')
		}
		else {
			xtile `zz' = `z' if `touse', nq(`ncells')
		}
		drop `z'
		qui g double `z'=`zz'
		loc ng = `ncells'	
		forval i=1/`ng' {
			loc z_`i'=`i'
		}
	}
	else {
		loc ng = rowsof(`A')
		if `ng' <= `ncells' {
			forval i=1/`ng' {
				loc z_`i' = `A'[`i',1]
			}
		}
		else {
			if "`survey'" != "" {
				xtile `zz' = `z' if `touse' [${wtype} ${wexp}], nq(`ncells')
			}
			else {
				xtile `zz' = `z' if `touse', nq(`ncells')
			}
			drop `z'
			qui gen `z'=`zz'
			loc ng = `ncells'	
			forval i=1/`ng' {
				loc z_`i'=`i'
			}
		}
	}
	
	
	tempvar pp
	tempname mat_z
	qui g double `pp' = 0
	forval i=1/`ng' {
		qui replace `pp'=(`z'==`z_`i'')
		qui count if `pp'==1 & `touse'
		global nmiv`i' = r(N)
		if "`survey'" != "" {
			qui svy, subpop(`touse'): mean `pp'
			mat `mat_z'=e(b)
			loc p_`i'=`mat_z'[1,1]
		}
		else {
			qui su `pp' if `touse', meanonly
			loc p_`i'=r(mean)			
		}
	}

	tempvar d1 d2 d3 d4
	qui g `d1'=(`yy' == 1 & `D'== 1)
	qui g `d2'=(`yy' == 0 & `D'== 0)
	qui g `d3'=(`yy' == 1 & `D'== 0)
	qui g `d4'=(`yy' == 0 & `D'== 1)		
	
* Assumption A1: arbitrary classification errors
*	only the upper bounds here
*	lower bounds are always zero 

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
	}

	
*! MIV and MTSn/MTSp Model (j=4)
	*calculate UB^i, LB^i
	forval i=1/`ng' {
		preserve
		qui keep if `z'==`z_`i''

		if "`survey'" != "" {
		
			qui svy, subpop(`touse'): mean `D'
			mat `mat_z'=e(b)
			loc mDiv=`mat_z'[1,1]
		
			qui svy, subpop(`touse'): mean `d1'
			mat `mat_z'=e(b)
			loc p11iv=`mat_z'[1,1]
		
			qui svy, subpop(`touse'): mean `d2'
			mat `mat_z'=e(b)
			local p00iv=`mat_z'[1,1]
		
			qui svy, subpop(`touse'): mean `d3'
			mat `mat_z'=e(b)
			local p10iv=`mat_z'[1,1]
		
			qui svy, subpop(`touse'): mean `d4'
			mat `mat_z'=e(b)
			local p01iv=`mat_z'[1,1]
		}
		else {
		
			qui su `D' if `touse', meanonly
			loc mDiv=r(mean)
		
			qui su `d1' if `touse', meanonly
			loc p11iv=r(mean)
		
			qui su `d2' if `touse', meanonly
			loc p00iv=r(mean)
		
			qui su `d3' if `touse', meanonly
			loc p10iv=r(mean)
		
			qui su `d4' if `touse', meanonly
			loc p01iv=r(mean)
		}
		
		if `p01iv'==0 | `p00iv'==0 | `p11iv'==0 | `p10iv'==0 {
			noi di in red "Warning: Some MIV cells do not contain all combinations of {Y,D}. Consider setting fewer cells using the {cmd:ncells} option.  If this happens with the original data, the program will terminate. If this happens during a particular bootstrap pseudosample, the program will continue but the number of repetitions will be fewer than the number specified."
		} 

		forval q = 1/`nq' {
			loc t1pos = min(`Q_`q'',`p11iv')
       		loc t1neg = min(`Q_`q'',`p10iv')
        		loc t0pos = min(`Q_`q'',`p01iv')
      	  		loc t0neg = min(`Q_`q'',`p00iv')

			*! Exogenous Selection Model (j=1)
		      	*! Arbitrary Errors Model: Invoking only A1 (j=1 & i=1)
			if `Q_`q''==0 {				
				loc ub11_1_`q'_`i' = `p11iv'/`mDiv'
				loc lb11_1_`q'_`i' = `ub11_1_`q'_`i'' 
				loc ub11_0_`q'_`i' = `p10iv'/(1-`mDiv')
				loc lb11_0_`q'_`i' = `ub11_0_`q'_`i'' 
			}

			** Grid Search **
			else {
				loc ub11_ate_temp = -10
				loc lb11_ate_temp =  10 
				loc inc_b=`t1pos'/(`np'-1)
				loc inc_a=`t1neg'/(`np'-1)
				loc inc_b_temp=`t0neg'/(`np'-1)			
				loc inc_a_temp=`t0pos'/(`np'-1)
				forval b=0(`inc_b')`t1pos' {
					loc Q_temp_b_max=min(`Q_`q'' - `b',`t0neg')
					forval Q_temp_b=0(`inc_b_temp')`Q_temp_b_max' {
						loc ratio_1_b=(`p11iv'-`b')/(`mDiv'-`b'+`Q_temp_b')
						loc ratio_2_b=(`p10iv'+`b')/(1-`mDiv'+`b'-`Q_temp_b')
						if `ratio_1_b'<=1 & `ratio_2_b'<=1 & (`ratio_1_b'-`ratio_2_b')>=-1 & (`ratio_1_b'-`ratio_2_b')<=`lb11_ate_temp' {
							loc lb11_ate_temp = `ratio_1_b'-`ratio_2_b'
							loc lb11_1_`q'_`i' = `ratio_1_b'
							loc ub11_0_`q'_`i' = `ratio_2_b'
						}
					}
				}								
				forval a=0(`inc_a')`t1neg' {
					loc Q_temp_a_max=min(`Q_`q'' - `a',`t0pos')
					forval Q_temp_a=0(`inc_a_temp')`Q_temp_a_max' {
						loc ratio_1_a=(`p11iv'+`a')/(`mDiv'+`a'-`Q_temp_a')
						loc ratio_2_a=(`p10iv'-`a')/(1-`mDiv'-`a'+`Q_temp_a')
						if `ratio_1_a'<=1 & `ratio_2_a'<=1 & (`ratio_1_a'-`ratio_2_a')<=1 & (`ratio_1_a'-`ratio_2_a')>=`ub11_ate_temp' {
							loc ub11_ate_temp = `ratio_1_a'-`ratio_2_a'
							loc ub11_1_`q'_`i' = `ratio_1_a'
							loc lb11_0_`q'_`i' = `ratio_2_a'
						}
					}
				}
			}

       		*! No False Positives Model: Invoking both A1 and A2 (j=1 & i=2)
			if `Q_`q''==0 {				
				loc ub12_1_`q'_`i' = `ub11_1_`q'_`i''
				loc lb12_1_`q'_`i' = `lb11_1_`q'_`i''
				loc ub12_0_`q'_`i' = `ub11_0_`q'_`i''
				loc lb12_0_`q'_`i' = `lb11_0_`q'_`i''
			}
			
		
			** Grid Search **
			else {
				loc ub12_ate_temp = -10
				loc lb12_ate_temp =  10 
				loc inc_h=`t0neg'/(`np'-1)
				loc inc_a=`t1neg'/(`np'-1)
				forval h=0(`inc_h')`t0neg' {
					loc ratio_1_h=(`p11iv')/(`mDiv'+`h')
					loc ratio_2_h=(`p10iv')/(1-`mDiv'-`h')
					if `ratio_1_h'<=1 & `ratio_2_h'<=1 & (`ratio_1_h'-`ratio_2_h')>=-1 & (`ratio_1_h'-`ratio_2_h')<=`lb12_ate_temp' {
						loc lb12_ate_temp = `ratio_1_h'-`ratio_2_h'
						loc lb12_1_`q'_`i' = `ratio_1_h'
						loc ub12_0_`q'_`i' = `ratio_2_h'
					}
				}											
				forval a=0(`inc_a')`t1neg' {
					loc ratio_1_a=(`p11iv'+`a')/(`mDiv'+`a')
					loc ratio_2_a=(`p10iv'-`a')/(1-`mDiv'-`a')
					if `ratio_1_a'<=1 & `ratio_2_a'<=1 & (`ratio_1_a'-`ratio_2_a')<=1 & (`ratio_1_a'-`ratio_2_a')>=`ub12_ate_temp' {
						loc ub12_ate_temp = `ratio_1_a'-`ratio_2_a'
						loc ub12_1_`q'_`i' = `ratio_1_a'
						loc lb12_0_`q'_`i' = `ratio_2_a'
					}
				}
			}

			*! Worst Case Selection Model (j=2)
		      *! Arbitrary Errors Model: Invoking only A1 (j=2 & i=1)
			if `Q_`q''==0 {				
				loc ub21_1_`q'_`i' = `p11iv' + (1 - `mDiv')
				loc lb21_1_`q'_`i' = `p11iv'
				loc ub21_0_`q'_`i' = `p10iv' + `mDiv'
				loc lb21_0_`q'_`i' = `p10iv'
			}
			else {									
				loc ub21_1_`q'_`i' = `p11iv' + (1 - `mDiv') + `t0pos'
				loc lb21_1_`q'_`i' = `p11iv' - `t1pos'
				loc ub21_0_`q'_`i' = `p10iv' + `mDiv' + `t0neg'
				loc lb21_0_`q'_`i' = `p10iv' - `t1neg' 
			}
                   
	  		*! No False Positives Model: Invoking both A1 and A2 (j=2 & i=2)
			if `Q_`q''==0 {				
				loc ub22_1_`q'_`i' = `ub21_1_`q'_`i''
				loc lb22_1_`q'_`i' = `lb21_1_`q'_`i''
				loc ub22_0_`q'_`i' = `ub21_0_`q'_`i''
				loc lb22_0_`q'_`i' = `lb21_0_`q'_`i''
			}
			else {
				loc ub22_1_`q'_`i' = `p11iv' + (1 - `mDiv')
				loc lb22_1_`q'_`i' = `p11iv'
				loc ub22_0_`q'_`i' = `p10iv' + `mDiv' + `t0neg'
				loc lb22_0_`q'_`i' = `p10iv' - `t1neg' 
			}
			
			*! Monotone Treatment Selection (MTSn) Model (j=3)
			loc ub31_1_`q'_`i' = max(min(`ub21_1_`q'_`i'',1),0)
			loc lb31_1_`q'_`i' = min(max(`lb11_1_`q'_`i'',0),1)
			loc ub31_0_`q'_`i' = max(min(`ub11_0_`q'_`i'',1),0)
			loc lb31_0_`q'_`i' = min(max(`lb21_0_`q'_`i'',0),1)

			loc ub32_1_`q'_`i' = max(min(`ub22_1_`q'_`i'',1),0)
			loc lb32_1_`q'_`i' = min(max(`lb12_1_`q'_`i'',0),1)
			loc ub32_0_`q'_`i' = max(min(`ub12_0_`q'_`i'',1),0)
			loc lb32_0_`q'_`i' = min(max(`lb22_0_`q'_`i'',0),1)

			*! Monotone Treatment Selection (MTSp) Model (j=3p)	
			loc ub31p_1_`q'_`i' = max(min(`ub11_1_`q'_`i'',1),0)
			loc lb31p_1_`q'_`i' = min(max(`lb21_1_`q'_`i'',0),1)
			loc ub31p_0_`q'_`i' = max(min(`ub21_0_`q'_`i'',1),0)
			loc lb31p_0_`q'_`i' = min(max(`lb11_0_`q'_`i'',0),1)

			loc ub32p_1_`q'_`i' = max(min(`ub12_1_`q'_`i'',1),0)
			loc lb32p_1_`q'_`i' = min(max(`lb22_1_`q'_`i'',0),1)
			loc ub32p_0_`q'_`i' = max(min(`ub22_0_`q'_`i'',1),0)
			loc lb32p_0_`q'_`i' = min(max(`lb12_0_`q'_`i'',0),1)
						
			*! MTSn and MTR Model (j=4): MTR: H(1)>=H(0) implies MTR-MTS together leads to MTS only UB for ATE and LB for ATE is 0 at worst
			loc ub41_1_`q'_`i' = max(min(`ub21_1_`q'_`i'',1),0)
			loc lb41_1_`q'_`i' = min(max(`lb11_1_`q'_`i'',0),1)
			loc ub41_0_`q'_`i' = max(min(`ub11_0_`q'_`i'',1),0)
			loc lb41_0_`q'_`i' = min(max(`lb21_0_`q'_`i'',0),1)
			
			loc ub42_1_`q'_`i' = max(min(`ub22_1_`q'_`i'',1),0)
			loc lb42_1_`q'_`i' = min(max(`lb12_1_`q'_`i'', 0),1)
			loc ub42_0_`q'_`i' = max(min(`ub12_0_`q'_`i'',1),0)
			loc lb42_0_`q'_`i' = min(max(`lb22_0_`q'_`i'',0),1)

			*! MTSp and MTR Model (j=4p): MTR: H(1)>=H(0) implies MTR-MTS together leads to MTS only UB for ATE and LB for ATE is 0 at worst
			loc ub41p_1_`q'_`i' = max(min(`ub11_1_`q'_`i'',1),0)
			loc lb41p_1_`q'_`i' = min(max(`lb21_1_`q'_`i'', 0),1)
			loc ub41p_0_`q'_`i' = max(min(`ub21_0_`q'_`i'',1),0)
			loc lb41p_0_`q'_`i' = min(max(`lb11_0_`q'_`i'',0),1)
			
			loc ub42p_1_`q'_`i' = max(min(`ub12_1_`q'_`i'',1),0)
			loc lb42p_1_`q'_`i' = min(max(`lb22_1_`q'_`i'', 0),1)
			loc ub42p_0_`q'_`i' = max(min(`ub22_0_`q'_`i'',1),0)
			loc lb42p_0_`q'_`i' = min(max(`lb12_0_`q'_`i'',0),1)
		}
		restore
	}				 
	
	
	*calculate T_n (MTSn)
	forval q = 1/`nq' {
		loc m11=-99999999
		loc m10=-99999999
		loc m21=-99999999
		loc m20=-99999999
		loc m31=-99999999
		loc m30=-99999999
		loc m41=-99999999
		loc m40=-99999999
		loc T11_`q'=0
		loc T10_`q'=0
		loc T21_`q'=0
		loc T20_`q'=0
		loc T31_`q'=0
		loc T30_`q'=0
		loc T41_`q'=0
		loc T40_`q'=0
		forval i=1/`ng' {
			loc m11=max(`m11',`lb31_1_`q'_`i'')
			loc T11_`q'=`T11_`q'' + `p_`i''*`m11'
			loc m21=max(`m21',`lb32_1_`q'_`i'')
			loc T21_`q'=`T21_`q'' + `p_`i''*`m21'
			loc m31=max(`m31',`lb41_1_`q'_`i'')
			loc T31_`q'=`T31_`q'' + `p_`i''*`m31'
			loc m41=max(`m41',`lb42_1_`q'_`i'')
			loc T41_`q'=`T41_`q'' + `p_`i''*`m41'
			
			loc m10=max(`m10',`lb31_0_`q'_`i'')
			loc T10_`q'=`T10_`q'' + `p_`i''*`m10'
			loc m20=max(`m20',`lb32_0_`q'_`i'')
			loc T20_`q'=`T20_`q'' + `p_`i''*`m20'
			loc m30=max(`m30',`lb41_0_`q'_`i'')
			loc T30_`q'=`T30_`q'' + `p_`i''*`m30'
			loc m40=max(`m40',`lb42_0_`q'_`i'')
			loc T40_`q'=`T40_`q'' + `p_`i''*`m40'
		}
	}
	
	
	
	*calculate U_n (MTSn)
	forval q = 1/`nq' {
		loc m11=99999999
		loc m10=99999999
		loc m21=99999999
		loc m20=99999999
		loc m31=99999999
		loc m30=99999999
		loc m41=99999999
		loc m40=99999999
		loc U11_`q'=0
		loc U10_`q'=0
		loc U21_`q'=0
		loc U20_`q'=0
		loc U31_`q'=0
		loc U30_`q'=0
		loc U41_`q'=0
		loc U40_`q'=0
		forval i=`ng'(-1)1 {
			loc m11=min(`m11',`ub31_1_`q'_`i'')
			loc U11_`q'=`U11_`q'' + `p_`i''*`m11'
			loc m21=min(`m21',`ub32_1_`q'_`i'')
			loc U21_`q'=`U21_`q'' + `p_`i''*`m21'
			loc m31=min(`m31',`ub41_1_`q'_`i'')
			loc U31_`q'=`U31_`q'' + `p_`i''*`m31'
			loc m41=min(`m41',`ub42_1_`q'_`i'')
			loc U41_`q'=`U41_`q'' + `p_`i''*`m41'
			
			loc m10=min(`m10',`ub31_0_`q'_`i'')
			loc U10_`q'=`U10_`q'' + `p_`i''*`m10'
			loc m20=min(`m20',`ub32_0_`q'_`i'')
			loc U20_`q'=`U20_`q'' + `p_`i''*`m20'
			loc m30=min(`m30',`ub41_0_`q'_`i'')
			loc U30_`q'=`U30_`q'' + `p_`i''*`m30'
			loc m40=min(`m40',`ub42_0_`q'_`i'')
			loc U40_`q'=`U40_`q'' + `p_`i''*`m40'
		}
	}	

	*calculate Tp_n (MTSp)
	forval q = 1/`nq' {
		loc m11=-99999999
		loc m10=-99999999
		loc m21=-99999999
		loc m20=-99999999
		loc m31=-99999999
		loc m30=-99999999
		loc m41=-99999999
		loc m40=-99999999		
		loc T11p_`q'=0
		loc T10p_`q'=0
		loc T21p_`q'=0
		loc T20p_`q'=0
		loc T31p_`q'=0
		loc T30p_`q'=0
		loc T41p_`q'=0
		loc T40p_`q'=0
		forval i=1/`ng' {
			loc m11=max(`m11',`lb31p_1_`q'_`i'')
			loc T11p_`q'=`T11p_`q'' + `p_`i''*`m11'
			loc m21=max(`m21',`lb32p_1_`q'_`i'')
			loc T21p_`q'=`T21p_`q'' + `p_`i''*`m21'
			loc m31=max(`m31',`lb41p_1_`q'_`i'')
			loc T31p_`q'=`T31p_`q'' + `p_`i''*`m31'
			loc m41=max(`m41',`lb42p_1_`q'_`i'')
			loc T41p_`q'=`T41p_`q'' + `p_`i''*`m41'
			
			loc m10=max(`m10',`lb31p_0_`q'_`i'')
			loc T10p_`q'=`T10p_`q'' + `p_`i''*`m10'
			loc m20=max(`m20',`lb32p_0_`q'_`i'')
			loc T20p_`q'=`T20p_`q'' + `p_`i''*`m20'
			loc m30=max(`m30',`lb41p_0_`q'_`i'')
			loc T30p_`q'=`T30p_`q'' + `p_`i''*`m30'
			loc m40=max(`m40',`lb42p_0_`q'_`i'')
			loc T40p_`q'=`T40p_`q'' + `p_`i''*`m40'						
		}
	}
	
	*calculate Up_n (MTSp)
	forval q = 1/`nq' {
		loc m11=99999999
		loc m10=99999999
		loc m21=99999999
		loc m20=99999999
		loc m31=99999999
		loc m30=99999999
		loc m41=99999999
		loc m40=99999999		
		loc U11p_`q'=0
		loc U10p_`q'=0
		loc U21p_`q'=0
		loc U20p_`q'=0
		loc U31p_`q'=0
		loc U30p_`q'=0
		loc U41p_`q'=0
		loc U40p_`q'=0
		
		forval i=`ng'(-1)1 {
			loc m11=min(`m11',`ub31p_1_`q'_`i'')
			loc U11p_`q'=`U11p_`q'' + `p_`i''*`m11'
			loc m21=min(`m21',`ub32p_1_`q'_`i'')
			loc U21p_`q'=`U21p_`q'' + `p_`i''*`m21'
			loc m31=min(`m31',`ub41p_1_`q'_`i'')
			loc U31p_`q'=`U31p_`q'' + `p_`i''*`m31'
			loc m41=min(`m41',`ub42p_1_`q'_`i'')
			loc U41p_`q'=`U41p_`q'' + `p_`i''*`m41'
			
			loc m10=min(`m10',`ub31p_0_`q'_`i'')
			loc U10p_`q'=`U10p_`q'' + `p_`i''*`m10'
			loc m20=min(`m20',`ub32p_0_`q'_`i'')
			loc U20p_`q'=`U20p_`q'' + `p_`i''*`m20'
			loc m30=min(`m30',`ub41p_0_`q'_`i'')
			loc U30p_`q'=`U30p_`q'' + `p_`i''*`m30'
			loc m40=min(`m40',`ub42p_0_`q'_`i'')
			loc U40p_`q'=`U40p_`q'' + `p_`i''*`m40'			
		}
	}
	
	*! First-stage, non-bias-corrected results
	forval q=1/`nq' {
		ereturn scalar T11_`QQ_`q''  = `T11_`q''
		ereturn scalar T21_`QQ_`q''  = `T21_`q''
		ereturn scalar T31_`QQ_`q''  = `T31_`q''
		ereturn scalar T41_`QQ_`q''  = `T41_`q''
		
		ereturn scalar T10_`QQ_`q''  = `T10_`q''
		ereturn scalar T20_`QQ_`q''  = `T20_`q''
		ereturn scalar T30_`QQ_`q''  = `T30_`q''
		ereturn scalar T40_`QQ_`q''  = `T40_`q''
		
		ereturn scalar U11_`QQ_`q''  = `U11_`q''
		ereturn scalar U21_`QQ_`q''  = `U21_`q''
		ereturn scalar U31_`QQ_`q''  = `U31_`q''
		ereturn scalar U41_`QQ_`q''  = `U41_`q''
		
		ereturn scalar U10_`QQ_`q''  = `U10_`q''		
		ereturn scalar U20_`QQ_`q''  = `U20_`q''
		ereturn scalar U30_`QQ_`q''  = `U30_`q''
		ereturn scalar U40_`QQ_`q''  = `U40_`q''
		
		ereturn scalar T11p_`QQ_`q'' = `T11p_`q''
		ereturn scalar T21p_`QQ_`q'' = `T21p_`q''
		ereturn scalar T31p_`QQ_`q'' = `T31p_`q''
		ereturn scalar T41p_`QQ_`q'' = `T41p_`q''
		
		ereturn scalar T10p_`QQ_`q'' = `T10p_`q''		
		ereturn scalar T20p_`QQ_`q'' = `T20p_`q''
		ereturn scalar T30p_`QQ_`q'' = `T30p_`q''
		ereturn scalar T40p_`QQ_`q'' = `T40p_`q''
		
		ereturn scalar U11p_`QQ_`q'' = `U11p_`q''
		ereturn scalar U21p_`QQ_`q'' = `U21p_`q''
		ereturn scalar U31p_`QQ_`q'' = `U31p_`q''
		ereturn scalar U41p_`QQ_`q'' = `U41p_`q''
		
		ereturn scalar U10p_`QQ_`q'' = `U10p_`q''
		ereturn scalar U20p_`QQ_`q'' = `U20p_`q''
		ereturn scalar U30p_`QQ_`q'' = `U30p_`q''
		ereturn scalar U40p_`QQ_`q'' = `U40p_`q''
	}
	
	loc slist " "
	forval q=1/`nq' {
		loc slist "`slist' T11_`QQ_`q'' T21_`QQ_`q'' T31_`QQ_`q'' T41_`QQ_`q''"
		loc slist "`slist' T10_`QQ_`q'' T20_`QQ_`q'' T30_`QQ_`q'' T40_`QQ_`q''"
		loc slist "`slist' U11_`QQ_`q'' U21_`QQ_`q'' U31_`QQ_`q'' U41_`QQ_`q''"
		loc slist "`slist' U10_`QQ_`q'' U20_`QQ_`q'' U30_`QQ_`q'' U40_`QQ_`q''"
		loc slist "`slist' T11p_`QQ_`q'' T21p_`QQ_`q'' T31p_`QQ_`q'' T41p_`QQ_`q''"
		loc slist "`slist' T10p_`QQ_`q'' T20p_`QQ_`q'' T30p_`QQ_`q'' T40p_`QQ_`q''"
		loc slist "`slist' U11p_`QQ_`q'' U21p_`QQ_`q'' U31p_`QQ_`q'' U41p_`QQ_`q''"
		loc slist "`slist' U10p_`QQ_`q'' U20p_`QQ_`q'' U30p_`QQ_`q'' U40p_`QQ_`q''"
	}
	
	loc rlist " "
	forval q=1/`nq' {
		loc rlist `rlist' (e(T11_`QQ_`q'')) (e(T21_`QQ_`q'')) (e(T31_`QQ_`q'')) (e(T41_`QQ_`q'')) 
		loc rlist `rlist' (e(T10_`QQ_`q'')) (e(T20_`QQ_`q'')) (e(T30_`QQ_`q'')) (e(T40_`QQ_`q''))
		loc rlist `rlist' (e(U11_`QQ_`q'')) (e(U21_`QQ_`q'')) (e(U31_`QQ_`q'')) (e(U41_`QQ_`q'')) 
		loc rlist `rlist' (e(U10_`QQ_`q'')) (e(U20_`QQ_`q'')) (e(U30_`QQ_`q'')) (e(U40_`QQ_`q''))
		loc rlist `rlist' (e(T11p_`QQ_`q'')) (e(T21p_`QQ_`q'')) (e(T31p_`QQ_`q'')) (e(T41p_`QQ_`q'')) 
		loc rlist `rlist' (e(T10p_`QQ_`q'')) (e(T20p_`QQ_`q'')) (e(T30p_`QQ_`q'')) (e(T40p_`QQ_`q''))
		loc rlist `rlist' (e(U11p_`QQ_`q'')) (e(U21p_`QQ_`q'')) (e(U31p_`QQ_`q'')) (e(U41p_`QQ_`q'')) 
		loc rlist `rlist' (e(U10p_`QQ_`q'')) (e(U20p_`QQ_`q'')) (e(U30p_`QQ_`q'')) (e(U40p_`QQ_`q''))
	}

	
	*bias correction
	local KK = `k'
	if `KK' > 0 {
		foreach stat of loc slist {
			local bias_`stat'=e(`stat')
		}
		tempfile bs_correct			
		if "`survey'" != "" {
			qui svydes
			local str_count=r(N_strata)

			if `str_count'>1 {
				qui bsweights bsw_bc, reps(`KK') n(`npsu') replace
			}
			else {
				qui bsweights bsw_bc, reps(`KK') n(`npsu') replace nosvy
			}
			qui svyset ${r_set} bsrweight(bsw_bc*)
			qui svy bootstrap `rlist', subpop(`touse') nodots saving(`bs_correct', replace): ///
				tebounds_miv `y' if `touse', t(`treat') c(`control') tr(`treatment') miv(`miv') ncells(`ncells') ///
				erates(`erates') k(0) np(`np') npsu(`npsu') survey
				
			drop bsw_bc*
			qui svyset ${r_set}
		}
		else {
			qui bootstrap `rlist', reps(`KK') nodots saving(`bs_correct', replace): ///
				tebounds_miv `y' if `touse', t(`treat') c(`control') tr(`treatment') miv(`miv') ncells(`ncells') ///
				erates(`erates') k(0) np(`np') npsu(`npsu')
		}
		preserve
		use `bs_correct', clear
        
		local z=0
		foreach stat of loc slist {
			local z=`z'+1
			rename _bs_`z' `stat'
		}
		
		loc prefix "T11 T21 T31 T41 T10 T20 T30 T40 U11 U21 U31 U41 U10 U20 U30 U40 T11p T21p T31p T41p T10p T20p T30p T40p U11p U21p U31p U41p U10p U20p U30p U40p"
		foreach r of local prefix {
			forval q=1/`nq' {			
				qui sum `r'_`QQ_`q'', meanonly
				loc bc_`r'_`QQ_`q''=r(mean)
			}
		}
		
		restore 
		forval q=1/`nq' {
			loc lb41_1_`q'=2*`bias_T11_`QQ_`q'''-`bc_T11_`QQ_`q'''
			loc lb42_1_`q'=2*`bias_T21_`QQ_`q'''-`bc_T21_`QQ_`q'''
			loc lb43_1_`q'=2*`bias_T31_`QQ_`q'''-`bc_T31_`QQ_`q'''
			loc lb44_1_`q'=2*`bias_T41_`QQ_`q'''-`bc_T41_`QQ_`q'''
			
			loc lb41_0_`q'=2*`bias_T10_`QQ_`q'''-`bc_T10_`QQ_`q'''
			loc lb42_0_`q'=2*`bias_T20_`QQ_`q'''-`bc_T20_`QQ_`q'''
			loc lb43_0_`q'=2*`bias_T30_`QQ_`q'''-`bc_T30_`QQ_`q'''
			loc lb44_0_`q'=2*`bias_T40_`QQ_`q'''-`bc_T40_`QQ_`q'''
			
			loc ub41_1_`q'=2*`bias_U11_`QQ_`q'''-`bc_U11_`QQ_`q'''
			loc ub42_1_`q'=2*`bias_U21_`QQ_`q'''-`bc_U21_`QQ_`q'''
			loc ub43_1_`q'=2*`bias_U31_`QQ_`q'''-`bc_U31_`QQ_`q'''
			loc ub44_1_`q'=2*`bias_U41_`QQ_`q'''-`bc_U41_`QQ_`q'''
			
			loc ub41_0_`q'=2*`bias_U10_`QQ_`q'''-`bc_U10_`QQ_`q'''
			loc ub42_0_`q'=2*`bias_U20_`QQ_`q'''-`bc_U20_`QQ_`q'''
			loc ub43_0_`q'=2*`bias_U30_`QQ_`q'''-`bc_U30_`QQ_`q'''
			loc ub44_0_`q'=2*`bias_U40_`QQ_`q'''-`bc_U40_`QQ_`q'''

			loc lb41p_1_`q'=2*`bias_T11p_`QQ_`q'''-`bc_T11p_`QQ_`q'''
			loc lb42p_1_`q'=2*`bias_T21p_`QQ_`q'''-`bc_T21p_`QQ_`q'''
			loc lb43p_1_`q'=2*`bias_T31p_`QQ_`q'''-`bc_T31p_`QQ_`q'''
			loc lb44p_1_`q'=2*`bias_T41p_`QQ_`q'''-`bc_T41p_`QQ_`q'''
			
			loc lb41p_0_`q'=2*`bias_T10p_`QQ_`q'''-`bc_T10p_`QQ_`q'''
			loc lb42p_0_`q'=2*`bias_T20p_`QQ_`q'''-`bc_T20p_`QQ_`q'''
			loc lb43p_0_`q'=2*`bias_T30p_`QQ_`q'''-`bc_T30p_`QQ_`q'''
			loc lb44p_0_`q'=2*`bias_T40p_`QQ_`q'''-`bc_T40p_`QQ_`q'''
			
			loc ub41p_1_`q'=2*`bias_U11p_`QQ_`q'''-`bc_U11p_`QQ_`q'''
			loc ub42p_1_`q'=2*`bias_U21p_`QQ_`q'''-`bc_U21p_`QQ_`q'''
			loc ub43p_1_`q'=2*`bias_U31p_`QQ_`q'''-`bc_U31p_`QQ_`q'''
			loc ub44p_1_`q'=2*`bias_U41p_`QQ_`q'''-`bc_U41p_`QQ_`q'''
			
			loc ub41p_0_`q'=2*`bias_U10p_`QQ_`q'''-`bc_U10p_`QQ_`q'''
			loc ub42p_0_`q'=2*`bias_U20p_`QQ_`q'''-`bc_U20p_`QQ_`q'''
			loc ub43p_0_`q'=2*`bias_U30p_`QQ_`q'''-`bc_U30p_`QQ_`q'''
			loc ub44p_0_`q'=2*`bias_U40p_`QQ_`q'''-`bc_U40p_`QQ_`q'''

			loc bbias_T11_`q' = -(`bias_T11_`QQ_`q'''-`bc_T11_`QQ_`q''')
			loc bbias_T21_`q' = -(`bias_T21_`QQ_`q'''-`bc_T21_`QQ_`q''')
			loc bbias_T31_`q' = -(`bias_T31_`QQ_`q'''-`bc_T31_`QQ_`q''')
			loc bbias_T41_`q' = -(`bias_T41_`QQ_`q'''-`bc_T41_`QQ_`q''')
		
			loc bbias_T10_`q' = -(`bias_T10_`QQ_`q'''-`bc_T10_`QQ_`q''')
			loc bbias_T20_`q' = -(`bias_T20_`QQ_`q'''-`bc_T20_`QQ_`q''')
			loc bbias_T30_`q' = -(`bias_T30_`QQ_`q'''-`bc_T30_`QQ_`q''')
			loc bbias_T40_`q' = -(`bias_T40_`QQ_`q'''-`bc_T40_`QQ_`q''')
		
			loc bbias_U11_`q' = -(`bias_U11_`QQ_`q'''-`bc_U11_`QQ_`q''')
			loc bbias_U21_`q' = -(`bias_U21_`QQ_`q'''-`bc_U21_`QQ_`q''')
			loc bbias_U31_`q' = -(`bias_U31_`QQ_`q'''-`bc_U31_`QQ_`q''')
			loc bbias_U41_`q' = -(`bias_U41_`QQ_`q'''-`bc_U41_`QQ_`q''')
		
			loc bbias_U10_`q' = -(`bias_U10_`QQ_`q'''-`bc_U10_`QQ_`q''')		
			loc bbias_U20_`q' = -(`bias_U20_`QQ_`q'''-`bc_U20_`QQ_`q''')
			loc bbias_U30_`q' = -(`bias_U30_`QQ_`q'''-`bc_U30_`QQ_`q''')
			loc bbias_U40_`q' = -(`bias_U40_`QQ_`q'''-`bc_U40_`QQ_`q''')
		
			loc bbias_T11p_`q' = -(`bias_T11p_`QQ_`q'''-`bc_T11p_`QQ_`q''')
			loc bbias_T21p_`q' = -(`bias_T21p_`QQ_`q'''-`bc_T21p_`QQ_`q''')
			loc bbias_T31p_`q' = -(`bias_T31p_`QQ_`q'''-`bc_T31p_`QQ_`q''')
			loc bbias_T41p_`q' = -(`bias_T41p_`QQ_`q'''-`bc_T41p_`QQ_`q''')
		
			loc bbias_T10p_`q' = -(`bias_T10p_`QQ_`q'''-`bc_T10p_`QQ_`q''')		
			loc bbias_T20p_`q' = -(`bias_T20p_`QQ_`q'''-`bc_T20p_`QQ_`q''')
			loc bbias_T30p_`q' = -(`bias_T30p_`QQ_`q'''-`bc_T30p_`QQ_`q''')
			loc bbias_T40p_`q' = -(`bias_T40p_`QQ_`q'''-`bc_T40p_`QQ_`q''')
		
			loc bbias_U11p_`q' = -(`bias_U11p_`QQ_`q'''-`bc_U11p_`QQ_`q''')
			loc bbias_U21p_`q' = -(`bias_U21p_`QQ_`q'''-`bc_U21p_`QQ_`q''')
			loc bbias_U31p_`q' = -(`bias_U31p_`QQ_`q'''-`bc_U31p_`QQ_`q''')
			loc bbias_U41p_`q' = -(`bias_U41p_`QQ_`q'''-`bc_U41p_`QQ_`q''')
		
			loc bbias_U10p_`q' = -(`bias_U10p_`QQ_`q'''-`bc_U10p_`QQ_`q''')
			loc bbias_U20p_`q' = -(`bias_U20p_`QQ_`q'''-`bc_U20p_`QQ_`q''')
			loc bbias_U30p_`q' = -(`bias_U30p_`QQ_`q'''-`bc_U30p_`QQ_`q''')
			loc bbias_U40p_`q' = -(`bias_U40p_`QQ_`q'''-`bc_U40p_`QQ_`q''')
		}
	}
	else {	
		forval q=1/`nq' {	
			loc lb41_1_`q'=`T11_`q''
			loc lb42_1_`q'=`T21_`q''
			loc lb43_1_`q'=`T31_`q''
			loc lb44_1_`q'=`T41_`q''
			
			loc lb41_0_`q'=`T10_`q''
			loc lb42_0_`q'=`T20_`q''
			loc lb43_0_`q'=`T30_`q''
			loc lb44_0_`q'=`T40_`q''
			
			loc ub41_1_`q'=`U11_`q''
			loc ub42_1_`q'=`U21_`q''
			loc ub43_1_`q'=`U31_`q''
			loc ub44_1_`q'=`U41_`q''
			
			loc ub41_0_`q'=`U10_`q''
			loc ub42_0_`q'=`U20_`q''
			loc ub43_0_`q'=`U30_`q''
			loc ub44_0_`q'=`U40_`q''
			
			loc lb41p_1_`q'=`T11p_`q''
			loc lb42p_1_`q'=`T21p_`q''
			loc lb43p_1_`q'=`T31p_`q''
			loc lb44p_1_`q'=`T41p_`q''
			
			loc lb41p_0_`q'=`T10p_`q''
			loc lb42p_0_`q'=`T20p_`q''
			loc lb43p_0_`q'=`T30p_`q''
			loc lb44p_0_`q'=`T40p_`q''
			
			loc ub41p_1_`q'=`U11p_`q''
			loc ub42p_1_`q'=`U21p_`q''
			loc ub43p_1_`q'=`U31p_`q''
			loc ub44p_1_`q'=`U41p_`q''
			
			loc ub41p_0_`q'=`U10p_`q''
			loc ub42p_0_`q'=`U20p_`q''
			loc ub43p_0_`q'=`U30p_`q''
			loc ub44p_0_`q'=`U40p_`q''
		}
	}	
	
	forval q=1/`nq' {
		** Calculating UB_ATE (MTSn)
		*Arbitrary Errors Model
		loc ub41_ate_`q' = min(`ub41_1_`q'' - `lb41_0_`q'', 1)
		ereturn scalar ub41_ate_`QQ_`q''=`ub41_ate_`q'' 
		if `KK'>0 {
			global bias_ub41_ate_`QQ_`q''=`bbias_U11_`q'' - `bbias_T10_`q'' 
		}
		*No False Positives Model 
		loc ub42_ate_`q' = min(`ub42_1_`q'' - `lb42_0_`q'', 1)
		ereturn scalar ub42_ate_`QQ_`q''=`ub42_ate_`q'' 
		if `KK'>0 {
			global bias_ub42_ate_`QQ_`q''=`bbias_U21_`q'' - `bbias_T20_`q''
		}

		** Calculating UB_ATE (MTSn+MTR)
		*Arbitrary Errors Model
		loc ub43_ate_`q' = min(`ub43_1_`q'' - `lb43_0_`q'', 1)
		ereturn scalar ub43_ate_`QQ_`q''=`ub43_ate_`q'' 
		if `KK'>0 {
			global bias_ub43_ate_`QQ_`q''=`bbias_U31_`q'' - `bbias_T30_`q'' 
		}
		*No False Positives Model 
		loc ub44_ate_`q' = min(`ub44_1_`q'' - `lb44_0_`q'', 1)
		ereturn scalar ub44_ate_`QQ_`q''=`ub44_ate_`q'' 
		if `KK'>0 {
			global bias_ub44_ate_`QQ_`q''=`bbias_U41_`q'' - `bbias_T40_`q''
		}
		
		** Calculating LB_ATE (MTSn)
		*Arbitrary Errors Model
		loc lb41_ate_`q' = max(`lb41_1_`q'' - `ub41_0_`q'', -1) 
		ereturn scalar lb41_ate_`QQ_`q''=`lb41_ate_`q''	
		if `KK'>0 {
			global bias_lb41_ate_`QQ_`q''=`bbias_T11_`q'' - `bbias_U10_`q''					   
		}
		*No False Positives Model 
		loc lb42_ate_`q' = max(`lb42_1_`q'' - `ub42_0_`q'', -1)
		ereturn scalar lb42_ate_`QQ_`q''=`lb42_ate_`q''
		if `KK'>0 {
			global bias_lb42_ate_`QQ_`q''=`bbias_T21_`q'' - `bbias_U20_`q''
		}

		** Calculating LB_ATE (MTSn+MTR)
		*Arbitrary Errors Model
		loc lb43_ate_`q' = max(`lb43_1_`q'' - `ub43_0_`q'', 0) 
		ereturn scalar lb43_ate_`QQ_`q''=`lb43_ate_`q''	
		if `KK'>0 {
			global bias_lb43_ate_`QQ_`q''=`bbias_T31_`q'' - `bbias_U30_`q''					   
		}
		*No False Positives Model 
		loc lb44_ate_`q' = max(`lb44_1_`q'' - `ub44_0_`q'', 0)
		ereturn scalar lb44_ate_`QQ_`q''=`lb44_ate_`q''
		if `KK'>0 {
			global bias_lb44_ate_`QQ_`q''=`bbias_T41_`q'' - `bbias_U40_`q''
		}
		
		** Calculating UB_ATE (MTSp)
		*Arbitrary Errors Model
		loc ub41p_ate_`q' = min(`ub41p_1_`q'' - `lb41p_0_`q'', 1)
		ereturn scalar ub41p_ate_`QQ_`q''=`ub41p_ate_`q'' 
		if `KK'>0 {
			global bias_ub41p_ate_`QQ_`q''=`bbias_U11p_`q'' - `bbias_T10p_`q''
		}
		*No False Positives Model 
		loc ub42p_ate_`q' = min(`ub42p_1_`q'' - `lb42p_0_`q'', 1)
		ereturn scalar ub42p_ate_`QQ_`q''=`ub42p_ate_`q'' 
		if `KK'>0 {
			global bias_ub42p_ate_`QQ_`q''=`bbias_U21p_`q'' - `bbias_T20p_`q''
		}

		** Calculating UB_ATE (MTSp+MTR)
		*Arbitrary Errors Model
		loc ub43p_ate_`q' = min(`ub43p_1_`q'' - `lb43p_0_`q'', 1)
		ereturn scalar ub43p_ate_`QQ_`q''=`ub43p_ate_`q'' 
		if `KK'>0 {
			global bias_ub43p_ate_`QQ_`q''=`bbias_U31p_`q'' - `bbias_T30p_`q''
		}
		*No False Positives Model 
		loc ub44p_ate_`q' = min(`ub44p_1_`q'' - `lb44p_0_`q'', 1)
		ereturn scalar ub44p_ate_`QQ_`q''=`ub44p_ate_`q'' 
		if `KK'>0 {
			global bias_ub44p_ate_`QQ_`q''=`bbias_U41p_`q'' - `bbias_T40p_`q''
		}
		
		** Calculating LB_ATE (MTSp)
		*Arbitrary Errors Model
		loc lb41p_ate_`q' = max(`lb41p_1_`q'' - `ub41p_0_`q'', -1) 
		ereturn scalar lb41p_ate_`QQ_`q''=`lb41p_ate_`q''
		if `KK'>0 {	
			global bias_lb41p_ate_`QQ_`q''=`bbias_T11p_`q'' - `bbias_U10p_`q''					   
		}
		*No False Positives Model 
		loc lb42p_ate_`q' = max(`lb42p_1_`q'' - `ub42p_0_`q'', -1)
		ereturn scalar lb42p_ate_`QQ_`q''=`lb42p_ate_`q''
		if `KK'>0 {
			global bias_lb42p_ate_`QQ_`q''=`bbias_T21p_`q'' - `bbias_U20p_`q''
		}

		** Calculating LB_ATE (MTSp+MTR)
		*Arbitrary Errors Model
		loc lb43p_ate_`q' = max(`lb43p_1_`q'' - `ub43p_0_`q'', 0) 
		ereturn scalar lb43p_ate_`QQ_`q''=`lb43p_ate_`q''
		if `KK'>0 {	
			global bias_lb43p_ate_`QQ_`q''=`bbias_T31p_`q'' - `bbias_U30p_`q''					   
		}
		*No False Positives Model 
		loc lb44p_ate_`q' = max(`lb44p_1_`q'' - `ub44p_0_`q'', 0)
		ereturn scalar lb44p_ate_`QQ_`q''=`lb44p_ate_`q''
		if `KK'>0 {
			global bias_lb44p_ate_`QQ_`q''=`bbias_T41p_`q'' - `bbias_U40p_`q''
		}
		
	}
	
*! Final results for presentation
	loc slist " "
	forval q=1/`nq' {
		loc slist "`slist' ub41_ate_`QQ_`q'' lb41_ate_`QQ_`q''"
		loc slist "`slist' ub42_ate_`QQ_`q'' lb42_ate_`QQ_`q''"
		loc slist "`slist' ub43_ate_`QQ_`q'' lb43_ate_`QQ_`q''"
		loc slist "`slist' ub44_ate_`QQ_`q'' lb44_ate_`QQ_`q''"
		
		loc slist "`slist' ub41p_ate_`QQ_`q'' lb41p_ate_`QQ_`q''"
		loc slist "`slist' ub42p_ate_`QQ_`q'' lb42p_ate_`QQ_`q''"
		loc slist "`slist' ub43p_ate_`QQ_`q'' lb43p_ate_`QQ_`q''"
		loc slist "`slist' ub44p_ate_`QQ_`q'' lb44p_ate_`QQ_`q''"
	}

	loc rlist " "
	forval q=1/`nq' {
		loc rlist `rlist' (e(ub41_ate_`QQ_`q'')) (e(lb41_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub42_ate_`QQ_`q'')) (e(lb42_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub43_ate_`QQ_`q'')) (e(lb43_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub44_ate_`QQ_`q'')) (e(lb44_ate_`QQ_`q''))
		
		loc rlist `rlist' (e(ub41p_ate_`QQ_`q'')) (e(lb41p_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub42p_ate_`QQ_`q'')) (e(lb42p_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub43p_ate_`QQ_`q'')) (e(lb43p_ate_`QQ_`q''))
		loc rlist `rlist' (e(ub44p_ate_`QQ_`q'')) (e(lb44p_ate_`QQ_`q''))
	}

	** Store results from first run as point estimates (prior to bs replications) 
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
			
			if `str_count'>1 {
				qui bsweights bsw_bs, reps(`reps') n(`npsu') replace
			}
			else {
				qui bsweights bsw_bs, reps(`reps') n(`npsu') replace nosvy
			}
			qui svyset ${r_set} bsrweight(bsw_bs*)	 
			qui svy bootstrap `rlist', subpop(`touse') nodots saving(`bsfile', replace): ///
				tebounds_miv `y' if `touse', t(`treat') c(`control') tr(`treatment') miv(`miv') ncells(`ncells') ///
				erates(`erates') k(`KK') np(`np') npsu(`npsu') survey
			drop bsw_bs*
			qui svyset ${r_set}
		}
		else {
			qui bootstrap `rlist', reps(`reps') nodots saving(`bsfile', replace): ///
				tebounds_miv `y' if `touse', t(`treat') c(`control') tr(`treatment') miv(`miv') ncells(`ncells') ///
				erates(`erates') k(`KK') np(`np') npsu(`npsu')
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
		
		loc ij_1 "41 42 41p 42p"
		foreach r of loc ij_1 {
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
					loc lb`r'_ate_`QQ_`q''_l = max(${pe2_lb`r'_ate_`QQ_`q''} - `c'*`lb`r'_ate_`QQ_`q''_sd', -1)
					loc ub`r'_ate_`QQ_`q''_u = min(${pe2_ub`r'_ate_`QQ_`q''} + `c'*`ub`r'_ate_`QQ_`q''_sd', 1)
				}
			}
		}
		
		loc ij_2 "43 44 43p 44p"
		foreach r of loc ij_2 {
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
					loc lb`r'_ate_`QQ_`q''_l = max(${pe2_lb`r'_ate_`QQ_`q''} - `c'*`lb`r'_ate_`QQ_`q''_sd', 0)
					loc ub`r'_ate_`QQ_`q''_u = min(${pe2_ub`r'_ate_`QQ_`q''} + `c'*`ub`r'_ate_`QQ_`q''_sd', 1)
				}
			}
		}

		
		restore
		loc slist " "
		forval q=1/`nq' {
			loc slist "`slist' ub41_ate_`QQ_`q'' ub42_ate_`QQ_`q'' ub43_ate_`QQ_`q'' ub44_ate_`QQ_`q'' "
			loc slist "`slist' ub41p_ate_`QQ_`q'' ub42p_ate_`QQ_`q'' ub43p_ate_`QQ_`q'' ub44p_ate_`QQ_`q''"
		}
		foreach stat of loc slist {
			global ub_`stat'=max(``stat'_u',${pe2_`stat'})
		}
		loc slist " "
		forval q=1/`nq' {
			loc slist "`slist' lb41_ate_`QQ_`q'' lb42_ate_`QQ_`q'' lb43_ate_`QQ_`q'' lb44_ate_`QQ_`q''"
			loc slist "`slist' lb41p_ate_`QQ_`q'' lb42p_ate_`QQ_`q'' lb43p_ate_`QQ_`q'' lb44p_ate_`QQ_`q''"
		}
		foreach stat of loc slist {
			global lb_`stat'=min(``stat'_l',${pe2_`stat'})
		}
		ereturn scalar bsreps = `nn'
    }

	if "`survey'" != "" {
		qui svyset, clear
		qui svyset ${r_set}
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
