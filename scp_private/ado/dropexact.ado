program define dropexact, rclass
{
    confirm variable `1', exact
    if _rc == 0 {
        drop `1'
    }
    else {
        di "`1' not found"
    }
}
end
