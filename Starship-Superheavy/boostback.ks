// More than a preview, less than an actual code
// I added a more soft return but there still work to do when the boostback end
// Fuel draining is kinda solve as it works but need some tweaks


//--Variables--\\
set done_ag1 to false. // Next engine mode
set done_ag5 to false. // Previous engine mode
set meco to 70000. // Boostback start altitude.
set maxalt to 100000. //max alt you want the apoapsis of the boostback to go to : W.I.P.
lock landingsite to latlng(25.9959261063009 , -97.153023799664). // latlng coordinates of your desired landingsite
set x to 0. // lngoff you want in real life this would be like -100
set y to 20. // beware because y act like a clamp, As superheavy is more uncontrollable than F9, don't put very low value unless you're certain about it (im certain about it 😎)

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

//----------------------------------------------------------------------------------BOOSTBACK-------------------------------------------------------------------------------\\

//--MECO SEQUENCE--\\

when alt:radar >=meco-5000 then {
  toggle ag1.
  lock throttle to 1.
}

when alt:radar >=meco-2500 then {
  toggle ag1.
  lock throttle to 1.
}

when alt:radar >=meco-500 then {
  lock throttle to 0.1.
  stage. // Ship should start throttling
}

//--Activator--\\

wait until alt:radar >= meco.

//--More variables--\\

set t1 to landingsite:position - getImpact():position. // Landingsite - your impact pos, needed for my throttle ratio formula
set tin to abs(errorVector():mag/ship:velocity:surface:mag/2).

//--longitude and latitude offset in meters--\\

lock lngoff to (landingsite:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472. 
lock latoff to (landingsite:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472. 
toggle ag3. // Gridfins
RCS on.
SAS OFF.

if abs(getImpact():lng) - abs(landingsite:lng) > 0 {
    set k to -1.
} else {                        // W.I.P.
    set k to 1.
}


until vang(heading(k*landingsite:heading,0):vector,ship:facing:forevector) <= 10 {
    set ship:control:top to 1.
    set ship:control:starboard to (ship:up:pitch - ship:facing:pitch)/2*abs((ship:up:pitch - ship:facing:pitch)).      
    lock throttle to 0.1.
} // You return yourself without lock steering so it's smoother and more realistic

until lngoff > x and abs(latoff) < y or AG10 {
    lock pr to t1:mag/maxalt. // W.I.P.
    lock bbt to errorVector():mag/t1:mag. // Throttle ratio
    set corr to VXCL(ship:sensors:grav,landingsite:position-ship:position). // straight vec from you to landingpos, on the same plan as errorvec.
    set tsvl to VXCL(ship:sensors:grav,(ship:direction:STARVECTOR)*latoff). // Latitude part of the errorvector()

    //--Engines--\\

    if done_ag5 = false {
        toggle ag5.
        set done_ag5 to true.
    }

    if abs(lngoff) <=500 and done_ag1 = false {
        toggle ag1.
        set done_ag1 to true.   // When you're close switch to three engines, W.I.P.
    }

    //--Steering--\\
    
    if apoapsis>=maxalt {
        lock tilt to -5.
    } else {                    // W.I.P.
        lock tilt to 5.
    }

    if abs(lngoff) <=5000 {
        set nv to corr+10*tsvl.
    } else {                              // Works, but W.I.P. 10* and 5* will be replaced
        set nv to corr+5*tsvl.
    }

    if abs(getimpact():lat) - abs(landingsite:lat) < 0 {
        set ang to 1*vang(corr, nv).
    } else {
        set ang to -1*vang(corr, nv).                        // Corection angle
    }
    set fdir to heading(k*landingsite:heading+ang, tilt).            //finaldirection

    //-- FUEL CONTROL--\\

    if vang(heading(k*landingsite:heading+ang, tilt):vector,ship:facing:forevector) <= 10 {
    
        set lp2 to getimpact():lat-landingsite:lat. // Latitude error
        set t to abs(errorVector():mag/ship:velocity:surface:mag). // Time to go from errorvector distance with your speed
        set fcalc to ((ship:liquidfuel-9000)/3886.20). // Time to drain the liquidfuel to 9000units

        if round(fcalc) <= abs(round(tin)-round(t)) { // Weird calculus to know the time to start draining, but it works 
            if ship:liquidfuel >=11000 {
                ag7 on.
            } else {
                ag8 on.
            }
        }
    }

    //--Main Control--\\

    lock steering to R(fdir:pitch,fdir:yaw,240). // Steering
    lock throttle to abs(min(max(bbt,0.01),1))*pr. // Throttle
    set SHIP:CONTROL:STARBOARD to (lp2/abs(lp2)). // RCS

wait 0.1.
}

until vang(srfRetrograde:vector,ship:facing:forevector) <= 10 {
    unlock steering.
    lock throttle to 0.
    lock steering to ship:srfRetrograde+R(0,0,270).                                            // W.I.P.
    set ship:control:top to -1.
    set ship:control:starboard to (ship:up:pitch - ship:facing:pitch)/abs((ship:up:pitch - ship:facing:pitch)).      
}

stage. // HSR
set ship:control:starboard to 0.
set ship:control:top to 0.
lock steering to srfRetrograde.
wait until alt:radar <=90000.
toggle ag5.
run land.
