// I Highly suggest reading this in visual studio code 
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
parameter landingsite is latlng(spot:lat,spot:lng).
lock errorScaling to 1.
function getImpact {
    if addons:tr:hasimpact { return addons:tr:impactpos. }
    return ship:geoposition.
}
function errorVector {
    return getImpact():position - landingsite:position.
}
function defAOA {
    local vspeed is ship:verticalspeed. // vertical speed
    local gspeed is ship:groundspeed. // ground speed
    local h is alt:radar/apoapsis. // altitude ratio you might change apoapsis to the max alt that your ship had reach.
    local t is (1-alt:radar/140000). // I forgot
    local vm is vspeed/1500. // same
    lock aoa to (arctan(abs(vspeed/gspeed))*t*abs(vm)*h). // main aoa calculus.
    return aoa.
}
function getSteering { // main steering function
    local errorVector is errorVector().
    local velVector is -ship:velocity:surface.
    local correctionVector to errorVector() * errorScaling.
    local result is velVector + correctionVector.
    local aoa is defAOA(). 

    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }
    return lookdirup(result, facing:topvector).
}

function vs { // the goal here is to kill vertical velocity by thrusting smoothly
    local m is ship:mass. // mass
    local g is constant:g. // gravity
    local p is m * g. // weight   
    set VELOCITY_TOLERANCE to 0.1. // Tolérance de vitesse verticale.
    until ABS(SHIP:VERTICALSPEED) < VELOCITY_TOLERANCE {

        local svp is -SHIP:VERTICALSPEED.
        local cv is alt:radar/1000. //correction vector depending on the altitude (alt lowering => thrust lowering => smooth landing)
        local corthr is (svp * cv). // corrected thrust
        local totalThrust to p + corthr. // total thrust

        if totalThrust > SHIP:MAXTHRUST {
            set totalThrust to SHIP:MAXTHRUST. // Infinity thrust protection
        } else if totalThrust < 0 { // Normally you should have landed (normally)
            set totalThrust to 0.
        }
        if ship:verticalspeed >=-80 {
            hv(). // Catching procedure
            toggle ag1.// switching to three engines
            toggle ag10.// vent
            toggle ag2.// undo gridfins
            LOCK THROTTLE TO totalThrust / SHIP:MAXTHRUST. // Throttle
        } else { LOCK THROTTLE TO totalThrust / SHIP:MAXTHRUST. } // 13 engines throttle
    }
}

function hv {
    local horizontalVelocity is ship:groundspeed. //The goal here is to kill horizontal velocity by tilting the booster
    local scaleFactor is min(1, alt:radar / 1000). //scale factor modify to fit your needs.
    local tiltAngle is arctan(horizontalVelocity / max(1, abs(ship:verticalspeed))) * scaleFactor. // Tilt angle of the booster to kill horizontal velocity
    lock steering to heading(landingsite:heading, up:forevector:mag-tiltAngle). // main heading steering 
}
ld().
toggle ag10. //purge stop
wait until ship:apoapsis.
lock steering to getSteering(). // steering to the landing site
toggle ag3.// toggle gridfins 30°
toggle ag5. // previous engine mode
wait until alt:radar <=1500. // begin landing procedure
vs().
wait until ship:liquidfuel <=0.// catched booster continue thrusting until fuel is empty.
