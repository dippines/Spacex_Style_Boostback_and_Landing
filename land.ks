// Script will change.

lock steering to srfRetrograde. 
// Variables 
parameter landingsite is latlng(spot:lat,spot:lng).
set radarOffset to 10.
lock trueRadar to alt:radar - radarOffset.
lock g to constant:g * body:mass / body:radius^2.
lock maxDecel to (ship:availablethrust / ship:mass) - g.
lock stopDist to (ship:verticalspeed^2 / (2 * maxDecel)) * 2.
lock idealThrottle to stopDist / trueRadar.
lock errorScaling to 10.
lock gravityForce to ship:mass * g.
set targetSpeed to -15.
lock speedError to targetSpeed - ship:verticalspeed.
lock throttleAdjustment to (speedError * ship:mass) / (ship:availablethrust + gravityForce).
lock ApproachThrottle to throttleAdjustment.

// Functions
function getImpact {
    if addons:tr:hasimpact { return addons:tr:impactpos. }
    return ship:geoposition.
}

function lngError {
    return getImpact():lng - landingsite:lng.
}

function latError {
    return getImpact():lat - landingsite:lat.
}

function errorVector {
    return getImpact():position - landingsite:position.
}

function getDynamicAOA {

    local errorVector is getimpact():position - landingsite:position.
    local horizontalError is errorVector:mag.

    if horizontalError < 400 { 
        if throttle > 0 {
            set factor to 1.
            print"F".
        } else {
            set factor to -1.
            print"P".
        }
    } else {
        set factor to 1.
        print"F".
    }   
    
        if alt:radar > 100000 {
        set maxAOA to 90*factor.
    } else if alt:radar > 50000 {
        set maxAOA to 70*factor.
    } else if alt:radar > 20000 {
        set maxAOA to 50*factor.
    } else if alt:radar > 15000 {
        set maxAOA to 20*factor.
    } else if alt:radar > 5000 {
        set maxAOA to 20.
    } else if alt:radar > 1000 {
        set maxAOA to -15.
    } else {
        set maxAOA to -5.
    }

    local dynamicAOA is min(horizontalError, maxAOA).

    return dynamicAOA.
}

function getSteering {
    local errorVector is errorVector().
    local velVector is -ship:velocity:surface.
    local correctionVector to errorVector() * errorScaling.
    local result is velVector + correctionVector.
    local aoa is getDynamicAOA(). 

    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }

    return lookdirup(result, facing:topvector).
}


// Activation des systèmes de guidage
lock throttle to 0.
toggle rcs.
wait until alt:radar <= 80000.
lock steering to getSteering().
rcs on.
wait until alt:radar <= stopDist or alt:radar <=5000.
lock steering to getSteering().
lock throttle to idealThrottle.
wait until ship:verticalspeed >= -150.
toggle ag1.
wait until alt:radar <= 700.
lock throttle to ApproachThrottle.
lock steering to getSteering().

wait until ship:verticalspeed >= 0.
lock throttle to 0.
rcs off.
lights off.
brakes off.
 
shutdown.
