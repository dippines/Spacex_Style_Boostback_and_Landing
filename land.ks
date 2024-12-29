// I Highly suggest reading this in visual studio code 
//Approach Throttle.
lock m to ship:mass. // mass
lock g to constant:g* body:mass / body:radius^2. // gravity
lock p to m * g. // weight
lock vi to -5. // desired speed
lock se to vi - ship:verticalspeed. // speed error
lock fm to ship:availablethrust. // available thrust
lock thr to (se * m) / (fm + p). // throttle calculus
set k to 1. // error scaling
function getImpact {
    if addons:tr:hasimpact { return addons:tr:impactpos. }
    return ship:geoposition.
}
if hastarget {
    set landingsite to latlng(target:geoposition:lat, target:geoposition:lng).
} else {
    set landingsite to latlng(getimpact:lat, getimpact:lng).
}
function errorVector {
    return getImpact():position - landingsite:position.
}
function defAOA {
    local he is (getImpact():position - landingsite:position):mag.
    local hex is he / 1000. // Adjust the divisor to scale the effect of he on aoa
    local vspeed is ship:verticalspeed. // vertical speed
    local gspeed is ship:groundspeed. // ground speed
    local h is (alt:radar/apoapsis). // altitude ratio you might change apoapsis to the max alt that your ship had reach.
    local t is (1-alt:radar/140000). // I forgot
    local vm is vspeed/1500. // speed/maxspeed
    lock aoa to (arctan(abs(vspeed/gspeed))*t*abs(vm)*h)*hex*2. // main aoa calculus.
    return aoa.
}
function getSteering { // main steering function
    local errorVector is errorVector().
    local velVector is -ship:velocity:surface.
    local correctionVector to errorVector() * k.
    local result is velVector + correctionVector.
    local aoa is defAOA(). 
    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }
    return lookdirup(result, facing:topvector).
    
}
function vs {
wait until alt:radar <=1000.
    toggle ag10.// vent
    lock throttle to min(0.8,thr).
wait until ship:verticalspeed >=-80.
    toggle ag1.// switching to three engines
    lock throttle to min(1,thr).
    toggle ag2.
    lock steering to hv().
wait until ship:liquidfuel <=0.
} 
function hv {
    local horizontalVelocity is ship:groundspeed. //The goal here is to kill horizontal velocity
    local scaleFactor is min(1, alt:radar / 1000). //scale factor modify to fit your needs.
    local tiltAngle is (arctan(horizontalVelocity / max(1, abs(ship:verticalspeed))) * scaleFactor)*1.5. // Tilt angle of the booster to kill horizontal velocity
    print tiltAngle.
    return heading(landingsite:heading, 90-tiltAngle). // main heading steering 
}
ld().
toggle ag10. //purge stop
wait until ship:apoapsis.
set navmode to "TARGET".
wait until alt:radar<=55000.
lock steering to getSteering(). // steering to the landing site
toggle ag3.// toggle gridfins 30°
toggle ag5. // previous engine mode
wait until alt:radar <1000.
vs().
wait until ship:liquidfuel <=0.// catched booster continue thrusting until fuel is empty.
