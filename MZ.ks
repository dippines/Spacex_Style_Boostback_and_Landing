Signal().
function Signal {
  until false {
    WHEN NOT SHIP:MESSAGES:EMPTY then {
      arms().
    }  
  }
}

function arms {
 until vessel("Heavy Booster"):altitude <=230 {
   angle().
   print vessel("Heavy Booster"):altitude.
 }
 ag1 on.
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

