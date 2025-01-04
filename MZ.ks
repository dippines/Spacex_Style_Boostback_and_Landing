// Mechazilla code
wait until ag2.
booster().
function booster {
  until false {
     WHEN NOT SHIP:MESSAGES:EMPTY then {
       SET RECEIVED TO SHIP:MESSAGES:POP.
       PRINT "Sent by " + RECEIVED:SENDER:NAME + " at " + RECEIVED:SENTAT.
       PRINT RECEIVED:CONTENT.
       ag1 on.
       ag3 on.
       set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
       set MZMOD to Mechazilla:getmodule("ModuleSLEController").
       set valueChamp to MZMOD:getfield("target angle").
       lock v1 to vessel("Heavy Booster"):geoposition:position.
       lock v2 to ship:geoposition:position.
       lock armsangle to vectorangle(v1,v2).
       print armsangle.
       MZMOD:setfield("target angle", 90-armsangle).
     }
  }
}

