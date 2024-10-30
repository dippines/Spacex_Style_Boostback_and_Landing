// credit to edwin roberts on github which I took from base of this code.
// Variables
parameter landingsite is latlng(spot:lat,spot:lng).
set radarOffset to 10. // depends on your vessel height, don't be scare to change it to have a soft landing.
lock trueRadar to alt:radar - radarOffset. 
lock g to constant:g * body:mass / body:radius^2.
lock maxDecel to (ship:availablethrust / ship:mass) - g.
lock stopDist to (ship:verticalspeed^2 / (2 * maxDecel))*2. //maxdecel*4 to activate engines at a good height for soft landing/catching.
lock idealThrottle to stopDist / trueRadar.
lock impactTime to trueRadar / abs(ship:verticalspeed).
lock aoa to 10.
lock errorScaling to 1.
lock realIdealThrottle to (ship:verticalspeed^2 /  maxDecel) / trueRadar.
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
    return getImpact():position - landingSite:position.
}

function getSteering {
    local errorVector is errorVector().
    local velVector is -ship:velocity:surface.
    local result is velVector + errorVector * errorScaling.
    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * errorVector:normalized.
    }
    return lookdirup(result, facing:topvector).
}
RCS ON.
lock steering to srfRetrograde.
wait until alt:radar < 40000.
toggle brakes.
lock aoa to 6.
wait until alt:radar < 30000.
wait until alt:radar < 20000.
lock aoa to 5. 
wait until alt:radar < 15000.
toggle brakes.
lock aoa to 4. 
wait until alt:radar < 5000.
lock aoa to 3. 
toggle ag1.

wait until alt:radar <= (2*stopDist)+1000.
lock steering to getSteering().
lock throttle to idealThrottle.
print "suicide burn".

// Mechazilla catch
wait until ship:verticalspeed >= -90.
toggle ag1. //3 engines mode
lock steering to srfRetrograde.
lock throttle to realIdealThrottle.
print "mechazilla catch".

// soft catch/land
wait until ship:verticalspeed >=0.
lock throttle to 0.
rcs off.
brakes off.
lights off.
print "Super Heavy caught successfully".
shutdown.
