wait until ag2.
catch().
function catch {
  until false {
    WHEN NOT SHIP:MESSAGES:EMPTY then {
      SET RECEIVED TO SHIP:MESSAGES:POP.
      PRINT "Sent by " + RECEIVED:SENDER:NAME + " at " + RECEIVED:SENTAT.
      PRINT RECEIVED:CONTENT.
      oa().
      angle().
      h().
    }
  }
}

function angle {  // Target angle
set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
        set MZANG to Mechazilla:getmodule("ModuleSLEController").
        lock v2 to vessel("Heavy Booster"):geoposition:position-ship:geoposition:position. // vector pointing toward booster
        print "target direction : " + v2:direction. // print the direction of the vector
        print "target angle : "+v2:direction:pitch. // The pitch value of that direction is the value of the target angle
  MZANG:setfield("target angle",v2:direction:pitch).
}

function h {  // Target height
set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
        set MZANG to Mechazilla:getmodule("ModuleSLEAnimate").
        lock z to vessel("Heavy Booster"):altitude.
  print "extension alt :" + (104-z).
  MZANG:setfield("target extension", 104-z).
}

function OA { //Open angle
set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
     set MZOA to Mechazilla:getmodule("ModuleSLEController").
     lock d to vessel("Heavy Booster"):altitude.
     print "vessel alt :" + d.
     lock ang to d-200.
     print ang.
     if ang <= 5 {
      print "closing arms".
      ag1 on.
     } else {
       print"arms open angle :" + ang.
     }
MZOA:setfield("arms open angle", ang).
}
