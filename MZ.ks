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


function angle {  // Target angle

  set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
        set MZANG to Mechazilla:getmodule("ModuleSLEController").
        SET dir TO ANGLEAXIS(0,SHIP:facing:topvector).//Perpendicular to tower/ middle of arms
        lock vec to vessel("Heavy Booster"):geoposition:position-ship:geoposition:position.//                             Will change cause SLE Mechazilla have a negative or positive angle of arrms so i will modifiy facing:topvector that calcul vang
        lock ang to vang((dir:vector:normalized),(vec:normalized))-8.
      print "target angle : " + (ang). // 8 is angle offset see SLE Github for more info
    MZANG:setfield("target angle",ang).

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
