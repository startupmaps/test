
	u NY.dta, replace
	tomname entityname
	save NY.dta, replace
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(NY.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(NY.dta)


	# delimit ;
	corp_add_trademarks NY , 
		dta(NY.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications NY NEW YORK , 
		dta(NY.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
		
	# delimit ;	
	corp_add_patent_assignments  NY NEW YORK , 
		dta(NY.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
	// corp_add_ipos	 NY ,dta(NY.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta) longstate(NEW YORK)
	corp_add_mergers NY ,dta(NY.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta)  longstate(NEW YORK)
	// corp_add_vc 	 NY ,dta(NY.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(NEW YORK)



clear
u NY.dta
safedrop shortname
gen  shortname = wordcount(entityname) <= 3
compress
 save NY.dta, replace
 
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
clear
	u VA.dta , replace
	tomname entityname
	save VA.dta, replace

	corp_add_eponymy, dtapath(VA.dta) directorpath(VA.directors.dta)


       corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(VA.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(VA.dta)
	
	
	# delimit ;
	corp_add_trademarks VA , 
		dta(VA.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications VA VIRGINIA , 
		dta(VA.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  VA VIRGINIA , 
		dta(VA.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	//corp_add_ipos	 VA  ,dta(VA.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(VIRGINIA) 
	u VA.dta, clear
	corp_add_mergers VA  ,dta(VA.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta)  longstate(VIRGINIA) 

**	
	clear
	u WA.dta
	tomname entityname
	save WA.dta, replace
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(WA.dta)

	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(WA.dta)
	
	u WA.dta, clear
	corp_add_gender, dta(WA.dta) directors(WA.directors.dta) names(~/ado/names/NATIONAL.TXT) precision(1)
	corp_add_eponymy, dtapath(WA.dta) directorpath(WA.directors.dta)
	
	# delimit ;
	corp_add_trademarks WA , 
		dta(WA.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications WA WASHINGTON , 
		dta(WA.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	corp_add_patent_assignments  WA WASHINGTON , 
		dta(WA.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
		
		

		
		
	# delimit cr	
	// corp_add_ipos	 WA  ,dta(WA.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta) longstate(WASHINGTON)
	
	corp_add_mergers WA  ,dta(WA.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta) longstate(WASHINGTON)

	// corp_add_vc 	 WA  ,dta(WA.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(WASHINGTON)

 
clear
u WA.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
 save WA.dta, replace
 
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	clear
	u KY.dta , replace
	tomname entityname
	save KY.dta ,replace
	
	corp_add_eponymy, dtapath(KY.dta) directorpath(KY.directors.dta)


       corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(KY.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(KY.dta)
	
	
	# delimit ;
	corp_add_trademarks KY , 
		dta(KY.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications KY KENTUCKY , 
		dta(KY.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments KY KENTUCKY , 
		dta(KY.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	// corp_add_ipos	 KY  ,dta(KY.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(KENTUCKY) 
	corp_add_mergers KY  ,dta(KY.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta)  longstate(KENTUCKY) 
**STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**
	u AR.dta , replace
	
	tomname entityname
	save AR.dta, replace

	corp_add_eponymy, dtapath(AR.dta) directorpath(AR.directors.dta)


       corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(AR.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(AR.dta)
	
	
	# delimit ;
	corp_add_trademarks AR , 
		dta(AR.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications AR ARKANSAS , 
		dta(AR.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  AR ARKANSAS , 
		dta(AR.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

 //     corp_add_ipos	 AR  ,dta(AR.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta)  longstate(ARKANSAS)
	corp_add_mergers AR  ,dta(AR.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta)  longstate(ARKANSAS) 

     //  corp_add_vc        AR ,dta(AR.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(ARKANSAS)
      
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	

    clear
    u AK.dta, replace
	tomname entityname
	save AK.dta, replace
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(AK.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(AK.dta)

	corp_add_eponymy, dtapath(AK.dta) directorpath(AK.directors.dta)
	
	# delimit ;
	corp_add_trademarks AK , 
		dta(AK.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications AK ALASKA , 
		dta(AK.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  AK ALASKA , 
		dta(AK.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
	// corp_add_ipos	 AK ,dta(AK.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(ALASKA)
	corp_add_mergers AK ,dta(AK.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta)  longstate(ALASKA)

        // corp_add_vc 	 AK ,dta(AK.dta) vc(~/final_datasets/VX.dta) longstate(ALASKA)



**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u WY.dta, replace
	tomname entityname
	save WY.dta, replace
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(WY.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(WY.dta)

*	corp_add_gender, dta(WY.dta) directors(WY.directors.dta) names(/NOBACKUP/scratch/share_scp/ext_data/names/WY.TXT)


	corp_add_eponymy, dtapath(WY.dta) directorpath(WY.directors.dta)
	
	# delimit ;
	corp_add_trademarks WY , 
		dta(WY.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications WY WYOMING , 
		dta(WY.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  WY WYOMING , 
		dta(WY.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
	// corp_add_ipos	 WY ,dta(WY.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta) longstate(WYOMING)
	corp_add_mergers WY ,dta(WY.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta)  longstate(WYOMING)




 
      // corp_add_vc        WY ,dta(WY.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(WYOMING)
   
 
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	

        clear
        u MO.dta
	tomname entityname
	save MO.dta, replace
corp_add_eponymy, dtapath(MO.dta) directorpath(MO.directors.dta)
corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(MO.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(MO.dta)
	
	# delimit ;
	corp_add_trademarks MO , 
		dta(MO.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications MO MISSOURI , 
		dta(MO.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

/* No Observations */	
	corp_add_patent_assignments  MO MISSOURI , 
		dta(MO.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	# delimit cr	
	
	// corp_add_ipos	 MO ,dta(MO.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta) longstate(MISSOURI)
	corp_add_mergers MO ,dta(MO.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta) longstate(MISSOURI)








// corp_add_vc MO ,dta(MO.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(MISSOURI)





clear
u MO.dta
// gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
compress
save MO.dta, replace
