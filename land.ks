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

function thrust {
    lock m to ship:mass. // mass
    local g is constant:g. // gravity
    lock vi to max(-sqrt(1.5 * g * alt:radar), -5). // desired speed
    local d is 928. // distance to stop
    lock fm to ship:availablethrust. // thrust
    lock f to m*g. // force
    lock a to (vi^2)/(2*d). // acceleration
    lock fe to m*a. // force to stop
    lock ft to f-fe. // force to thrust
    lock thr to ft/fm. // throttle
    catch(). // Catching procedure
    wait until alt:radar <1000. // Booster start landing at 1km
        lock throttle to thr.
    wait until ship:verticalspeed >-80. // Three engines mode 
        toggle ag1.// switching to three engines
        toggle ag10.// vent
        lock throttle to thr.
        toggle ag2.// undo gridfins
    wait until ship:liquidfuel <=0. // booster continue thrusting until fuel is empty.
}

function catch {
    local horizontalVelocity is ship:groundspeed. //The goal here is to kill horizontal velocity
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
thrust().
wait until ship:liquidfuel <=0.// catched booster continue thrusting until fuel is empty.
