// Work in progress, it's 80% sure that this will not work, the only function working is angle and is still in wip because it's quite buggy and as this is my first code i still have to learn basics.
catch(). // Catch function wait for the message from the booster.
function catch {
  until false {
    WHEN NOT SHIP:MESSAGES:EMPTY then {
      SET RECEIVED TO SHIP:MESSAGES:POP.
      PRINT "Sent by " + RECEIVED:SENDER:NAME + " at " + RECEIVED:SENTAT.
      PRINT RECEIVED:CONTENT.
      oa(). // Arms open angle, i dont use it in my own code but may be important in future
      angle(). // Main mechazilla steering function
      h(). // dont use that it's supposed to be mechazilla extension but it's not even a thing in spacex flight or just a little.
    }
  }
}

function angle {  // Mechazilla Target angle

  set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0]. // Call the part
        set MZANG to Mechazilla:getmodule("ModuleSLEController"). // Getmodule is like right click basically but as the tower is remotely controlled and not the active vessel you need this
        lock r1 to ship:geoposition:position-vessel("Heavy Booster"):geoposition:position.// vector pointing toward booster 
        lock tarang to r1:direction:pitch. // The pitch value of the r1 direction is the value of the target angle, for now because i'm not even sure
        lock v1 to vessel("Heavy Booster"):position:y. // Still need to work on this, with SLE, mechazilla arms is set between -56.8 and 56.8 so it's harder because you need to tell where is the booster between these 2 values in space, wip.
      if tarang >=113.6 { // Arms full open angle
        lock tar to tarang/10.
      } else {// This part is because of i think is a bug where the pitch value when a certain alt (below tower top maybe?) is reached make like a *10 this cause the arms to go on a direction and kick the booster.
        lock tar to tarang.
      }

      if v1 >= 0 {
        lock s to -1.
        print "sign value : -".
      } else {    // The sign of the angle i have no idea how i found that and might even be wrong but it seems to work update : it don't work
        lock s to 1.  
        print "sign value : +".
      }
      
      print "target angle : " + (tar-8). // 8 is angle offset see SLE Github for more info
    MZANG:setfield("target angle",(s*tar)-8). // Main angle steering
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
