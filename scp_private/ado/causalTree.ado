capture program drop causalTree



program define causalTree , rclass

    syntax varlist
{
    local causalTreeFile "~/temp/treeFile.dta"
    
    clear
    u guzman.jmp2017.ml.dta
    drop f_* fx_*
    duplicates drop datastate dataid, force
    merge 1:m datastate dataid using ~/migration/mldata.dta
    keep if _merge == 3
    tab datastate, gen(sta_)
    tab incyear , gen(yra_)
    keep lperf move2 statequality f_* sta_* yra_* dataid datastate quality
    order lperf move2 statequality f_*  sta_* yra_* dataid datastate quality
        
    saveold `causalTreeFile' , replace version(12)

    
    Rscript ~/ado/causalForest/causalForest.stataWrapper.R `causalTreeFile' `varlist'
    
}
end
