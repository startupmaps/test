clear

clear
import delimited using /home/jorgeg/projects/reap_proj/raw_data/Massachusetts/04_06-2017/CorpData.txt, delim(",") varnames(1)



	gen incdate = date(dateoforganization,"MDY") 
	gen incyear = year(incdate)

	gen address = addr1 + " " + addr2

	rename (jurisdictionstate postalcode) (jurisdiction zipcode)





        opencagegeo , key("381ff451c2fe760725ffac6085b16f20") address(address) city(city) state(state)
