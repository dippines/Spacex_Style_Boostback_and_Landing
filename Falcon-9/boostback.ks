//--Variables--\\

set meco to 75000. // Boostback start altitude.
set maxalt to 100000. //max alt you want the apoapsis of the boostback to go to : W.I.P.
set launchpos to latlng(28.618373, -80.598730). // launchsite position
lock landingsite to latlng(28.478863,-80.528986). // latlng coordinates of your desired landingsite


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



//--Activator--\\
wait until alt:radar >= meco.
set t1 to landingsite:position - getImpact():position. // Landingsite - your impact pos, needed for my throttle ratio formula


//--longitude and latitude offset in meters--\\
lock lngoff to (landingsite:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472. 
lock latoff to (landingsite:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472. 


    until lngoff > 5 and abs(latoff) < 5 or ABORT { // 5 is a very precise value, that work for me what I would recommend is to start with 50-100 values and decrease ESPECIALLY for lngoff.

        lock corr to VXCL(ship:sensors:grav,landingsite:position-ship:position). // straight vec from you to landingpos, on the same plan as errorvec.
        lock ang to VANG(corr, errorVector()).// Angle between the corr and errorvec, you want this to be the nearest to 0 

        //--Tilt-------------|
        lock pr to t1:mag/maxalt.
        if apoapsis>=maxalt {
            lock tilt to -5.
        } else {
            lock tilt to 5.
        }

        //--Steering -------------------------------------------|

        if launchpos:lat - landingsite:lat >0 {
            lock steering to heading (landingsite:heading+ang, tilt).
        } else if launchpos:lat - landingsite:lat <0{
            lock steering to heading (landingsite:heading-ang, tilt).
        } else if launchpos:lat - landingsite:lat =0 {
            lock steering to heading (landingsite:heading, tilt).
        }

        //--Throttle------------------------------|

        lock bbt to errorVector():mag/t1:mag.
        lock throttle to abs(min(max(bbt,0.1),1))*pr.
    wait 0.1.}
lock throttle to 0.
unlock throttle.
run land.

