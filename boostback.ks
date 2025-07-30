
Clearscreen.
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
    set landingsite to latlng(28.478863,-80.528986).
}

//--Error vector---------------------------------------|
function errorVector {   
    return  landingsite:position - getImpact():position.
}

//----------------------------------------------------------------------------------BOOSTBACK-------------------------------------------------------------------------------//

//--Variables-----------------------------------------------------------|
set meco to 40000. // Boostback start altitude.

set maxalt to 100000. //max alt you want the apoapsis of the boostback to go to : W.I.P.

set launchpos to latlng(28.618373, -80.598730). // launchsite position

wait until alt:radar >= meco.
set t1 to landingsite:position - getImpact():position. 

// longitude and latitude offset in meters----------------------|
lock lngoff to (landingsite:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472.
lock latoff to (landingsite:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472.
until abs(lngoff) < 5 and abs(latoff) < 5 or ABORT {
    
    lock corr to VXCL(ship:sensors:grav,landingsite:position-ship:position). // straight vec from you to landingpos, on the same plan as errorvec.
    lock ang to VANG(corr, errorVector()).// Angle between the latest vec and errorvec, you want this to be = 0
    
    //--Tilt-------------|
    if apoapsis > maxalt {
    lock tilt to -5.
    } else {                // W.I.P.
        lock tilt to 5.
    }

    //--Steering -------------------------------------------|
    
    if launchpos:lat - landingsite:lat >0 {
        lock steering to heading (landingsite:heading+ang, tilt).
    } else {
        lock steering to heading (landingsite:heading-ang, tilt).
    }
        
    //--Throttle------------------------------|
    lock bbt to errorVector():mag/t1:mag. // Ratio between the distance you are from the landingpad, divided by that same distance when the boostback code started. Don't worry if it seems you don't push near the end.  
    lock throttle to abs(min(max(bbt,0.05),1)).
    
wait 0.1.

}
unlock throttle.
lock throttle to 0.
