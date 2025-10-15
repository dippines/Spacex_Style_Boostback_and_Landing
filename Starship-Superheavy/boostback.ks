//--Variables--\\

set meco to 75000. // Boostback start altitude.
set maxalt to 100000. //max alt you want the apoapsis of the boostback to go to : W.I.P.
set launchpos to latlng(28.637138460196,-80.6050788442709). // launchsite position
lock landingsite to latlng(28.637138460196,-80). // latlng coordinates of your desired landingsite


//--Functions--\\

//--GetImpact--\\
function getImpact {
    if addons:tr:hasimpact { 
    return addons:tr:impactpos. 
    }
return ship:geoposition.
}

//--Target--\\
if hastarget { 
    lock landingsite to latlng(target:geoposition:lat, target:geoposition:lng). // latlng in case you have a target set
}

//--Error vector--\\
function errorVector {   
    return  landingsite:position - getImpact():position.
}

//----------------------------------------------------------------------------------BOOSTBACK CODE V1.2-------------------------------------------------------------------------------\\

//--MECO SEQUENCE--\\

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

//--Activator--\\

wait until alt:radar >= meco.
set t1 to landingsite:position - getImpact():position. // Landingsite - your impact pos, needed for my throttle ratio formula
set x to 0. // lngoff you want
set y to 10. // beware because y act like a clamp

//--longitude and latitude offset in meters--\\

lock lngoff to (landingsite:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472. 
lock latoff to (landingsite:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472. 
until lngoff > x and abs(latoff) < y or AG10 {

    lock corr to VXCL(ship:sensors:grav,landingsite:position-ship:position). // straight vec from you to landingpos, on the same plan as errorvec.
    lock ang to VANG(corr, errorVector()).// Angle between the latest vec and errorvec, you want this to be = 0
    //--Tilt-------------|
    lock pr to t1:mag/maxalt.
        if apoapsis>=maxalt {
            lock tilt to -15.
        } else {
            lock tilt to 5.
        }
    //--Steering -------------------------------------------|
    if launchpos:lat - landingsite:lat >0.0015 {
        lock steering to heading(landingsite:heading+ang, tilt).
    } else if launchpos:lat - landingsite:lat <0.0015{
        lock steering to heading(landingsite:heading-ang, tilt).
    } else{
        lock steering to heading(landingsite:heading, tilt).
    }
    //--Throttle------------------------------|
    lock bbt to errorVector():mag/t1:mag.
    toggle ag7.
    lock throttle to abs(min(max(bbt,0.05),1))*pr.
wait 0.1.
}
toggle ag7.
