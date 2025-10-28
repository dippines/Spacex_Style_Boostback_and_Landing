clearscreen.

//--Ships--\\

set sh to "Heavy Booster".
// set s to "Starship".

//--Main--\\
print "Waiting for Booster Signal acquisition".

until false {
  WHEN NOT SHIP:MESSAGES:EMPTY then {
      until vessel(sh):altitude <=190 {
        set v1 to vxcl(up:vector, vessel(sh):position).
        set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
        set MZANG to Mechazilla:getmodule("ModuleSLEController").
        set v0 to -ship:prograde:starvector.
        set ang to vang(v1,v0)-90.
        MZANG:setfield("target angle",ang).
        print(ang).
        wait 0.05.
      }
    ag1 on. // Close arms
  }  
  wait 0.05.
}

