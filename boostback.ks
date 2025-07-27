function ld {// load distances( visible tower and ship from 500km, camera feed etc)
SET kuniverse:defaultloaddistance:flying:LOAD TO 500000.   
SET kuniverse:defaultloaddistance:flying:UNLOAD TO 500000. 
SET kuniverse:defaultloaddistance:flying:UNPACK TO 500000. 
SET kuniverse:defaultloaddistance:flying:PACK TO 500000.   
SET kuniverse:defaultloaddistance:escaping:LOAD TO 500000.   
SET kuniverse:defaultloaddistance:escaping:UNLOAD TO 500000. 
SET kuniverse:defaultloaddistance:escaping:UNPACK TO 500000. 
SET kuniverse:defaultloaddistance:escaping:PACK TO 500000.   
SET kuniverse:defaultloaddistance:SUBORBITAL:LOAD TO 500000.   
SET kuniverse:defaultloaddistance:SUBORBITAL:UNLOAD TO 500000. 
SET kuniverse:defaultloaddistance:SUBORBITAL:UNPACK TO 500000. 
SET kuniverse:defaultloaddistance:SUBORBITAL:PACK TO 500000.   
SET kuniverse:defaultloaddistance:ORBIT:LOAD TO 500000.   
SET kuniverse:defaultloaddistance:ORBIT:UNLOAD TO 500000. 
SET kuniverse:defaultloaddistance:ORBIT:UNPACK TO 500000. 
SET kuniverse:defaultloaddistance:ORBIT:PACK TO 500000.   
SET kuniverse:defaultloaddistance:prelaunch:LOAD TO 500000.   
SET kuniverse:defaultloaddistance:prelaunch:UNLOAD TO 500000. 
SET kuniverse:defaultloaddistance:prelaunch:UNPACK TO 500000. 
SET kuniverse:defaultloaddistance:prelaunch:PACK TO 500000.   
SET kuniverse:defaultloaddistance:landed:LOAD TO 500000.   
SET kuniverse:defaultloaddistance:landed:UNLOAD TO 500000. 
SET kuniverse:defaultloaddistance:landed:UNPACK TO 500000. 
SET kuniverse:defaultloaddistance:landed:PACK TO 500000.   
}
ld().
Clearscreen.
when alt:radar >=65000 then {
  toggle ag1.
  lock throttle to 1.
}
when alt:radar >=67000 then {
  toggle ag1.
  lock throttle to 1.
}
when alt:radar >=69500 then {
  lock steering to srfprograde.
  lock throttle to 0.5.
}

//--Functions----------------------------------------------------------------|

//--GetImpact--------------------------------------------|
function getImpact {
    if addons:tr:hasimpact { 
    return addons:tr:impactpos. 
    }
return ship:geoposition.
}

//--Target-------------------------------------------------------------------|
if hastarget { 
    set landingsite to latlng(target:geoposition:lat, target:geoposition:lng).
} else {
    set landingsite to latlng(28.6370253021226,-80.6014334665529).
}

//--Error vector---------------------------------------|
function errorVector {   
    return  landingsite:position - getImpact():position.
}

//--------------------------------------------------------------------------------------------------------BOOSTBACK-----------------------------------------------------------------------------------------------------//

//--Variables-----------------------------------------------------------|
set meco to 70000. // Boostback start altitude / separation.
set maxalt to 100000. //max alt you want the apoapsis of the boostback to go to
wait until alt:radar >= meco.
set t1 to landingsite:position - getImpact():position. // Throttle margin

// longitude and latitude offset in meters----------------------|
lock lngoff to (landingsite:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472.
lock latoff to (landingsite:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472.

until abs(lngoff) < 10 and abs(latoff) < 5 or ABORT {  // Finish when errorvector is the lowest possible (try your own values), or when abort

lock corr to VXCL(ship:sensors:grav,landingsite:position-ship:position). // straight vec from you to landingpos, on the same plan as errorvec.
lock ang to VANG(corr, errorVector()).// Angle between the latest vec and errorvec, you want this to be = 0

//--Tilt-------------|
if apoapsis > maxalt {
    lock tang to -7.5.
} else {
    lock tang to 7.5.
}

//--Steering -------------------------------------------|
lock steering to heading (landingsite:heading-ang, tang). // Head toward landingpad without ang, to have an angle error = 0 (going straight toward landingpad)

//--Throttle------------------------------|
lock bbt to errorVector():mag/t1:mag. // Ratio between the distance you are from the landingpad, divided by that same distance when the boostback code started. Don't worry if it seems you don't push near the end.  
lock throttle to abs(min(max(bbt,0.05),1)).
print "throttle value" + throttle.
wait 0.1.
}

lock throttle to 0.
