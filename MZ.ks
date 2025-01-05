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
        lock r1 to ship:geoposition:position-vessel("Heavy Booster"):geoposition:position.// vector pointing toward booster
        lock tarang to r1:direction:pitch. // The pitch value of the v1 direction is the value of the target angle
        lock v1 to vessel("Heavy Booster"):position:y.
      if tarang >=113.6 { // Arms full open angle
        lock tar to tarang/10.
      } else {// This part is because of i think is a bug where the pitch value when a certain alt is reached make like a *10 this cause the arms to go on a direction and kick the booster.
        lock tar to tarang.
      }

      if v1 >= 0 {
        lock s to -1.
        print "sign value : -".
      } else {    // The sign of the angle i have no idea how i found that and might even be wrong but it seems to work
        lock s to 1.  
        print "sign value : +".
      }
      
      print "target angle : " + (tar-8). // 8 is angle offset see SLE Github for more info
    MZANG:setfield("target angle",(s*tar)-8).
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
