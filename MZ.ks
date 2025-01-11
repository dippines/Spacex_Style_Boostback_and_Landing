clearscreen.
print "Waiting for Booster Signal acquisition".
Signal().
function Signal {
  until false {
    WHEN NOT SHIP:MESSAGES:EMPTY then {
      arms().
    }  
  }
}

function arms {
 until vessel("Heavy Booster"):altitude <=200 {
   angle().
 }
 ag1 on.
 stlz().
}

function angle {  // Target angle
  set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
  set MZANG to Mechazilla:getmodule("ModuleSLEController").
  lock v0 to -ship:prograde:starvector.
  lock v1 to vessel("Heavy Booster"):geoposition:position-ship:geoposition:position.
  lock ang to vang(v1,v0)-90.
  print "target angle : " + ang.
  MZANG:setfield("target angle",ang).
}

function stlz {
  set MZANG to Mechazilla:getmodule("ModuleSLEController").
  MZANG:setfield("target angle",ang).
  ag3 on.
  ag1 on.
}
