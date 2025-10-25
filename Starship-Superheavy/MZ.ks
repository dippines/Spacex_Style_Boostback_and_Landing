clearscreen.

//--Ships--\\

set sh to "Heavy Booster".
// set s to "Starship".

//--Arms angle--\\

function angle {  // Target angle
  set v1 to vxcl(up:vector, vessel(sh):position).
  set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
  set MZANG to Mechazilla:getmodule("ModuleSLEController").
  set v0 to -ship:prograde:starvector.
  set ang to vang(v1,v0)-90.
  MZANG:setfield("target angle",ang).
}

//--Main--\\
print "Waiting for Booster Signal acquisition".

until false {
  WHEN NOT SHIP:MESSAGES:EMPTY then {
      lock v1 to vxcl(up:vector, vessel(sh):position).
      lock mDist to (v1 - vxcl(up:vector, SHIP:geoposition:position)):mag.
      until mDist <=20 {
          angle().
      }
    ag1 on. // Close arms
  }  
}

