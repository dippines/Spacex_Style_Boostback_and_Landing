clearscreen.
//------------------------Variables------------------------\\

runOncePath("lib").

set oneengine to false.
set landingsite to targetland().

if landingsite:lat = vessel("ASOG"):geoposition:lat {
    lock LZOFF to vessel("ASOG"):altitude.
} else {
    lock LZOFF to max(landingsite:terrainheight,0).
}
//------------------------Functions------------------------\\

function aoa { 

    local retrangle is vang(-ship:velocity:surface,ship:up:vector). // angle to be like ship:up
    local ang is clamp(round(vang(-ship:velocity:surface,-ship:velocity:surface+errorvector(landingsite))),0,10). // Kinda like the errorangle you want to cancel
    local tiltangle is round(vang(errorvector(landingsite)-ship:velocity:surface,-ship:velocity:surface)). // The angle that you need for tilting toward landingsite

    if throttle > 0 { // May change for it to be only when having less than 5G, it works with throttle > 0
        set maoa to clamp(tiltangle,0,5*retrangle). // For those last corrections, you are clamped between retrograde and 5*the angle to be up
    } else {
        set maoa to -ang. // If it don't work try just ang
    }
    return maoa.
}

function getSteering { // Modified version of Edwin Roberts one
    local velVector is -ship:velocity:surface.
    local correctionVector is errorvector(landingsite).
    local result is velVector + correctionVector.
    local aoa is aoa().
    if throttle = 0 {
        global burnalt is (ship:velocity:surface:mag^2 * (2 * (ship:maxThrust / ship:mass) - 3 * ship:sensors:grav:mag)) / (2 * ((ship:maxThrust / ship:mass) - ship:sensors:grav:mag) * ((ship:maxThrust / ship:mass) - 3 * ship:sensors:grav:mag)).
    } // Burn altitude calculation, knowing that during the burn you will go from 3 to 1 engine (simplified version of (burnaltonengine +burnaltthreengine)/2
    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }
    rcscorrections(1000000, landingsite).
    debug(landingsite).
    // debugvisual(landingsite).
    local val is lookdirup(result, facing:topvector).
    local pv is val:pitch.
    local yv is val:yaw.
    local rv is val:roll.

    if throttle > 0 { // The more you are close to relative ground, the more you want to be up
        local burnstart is LZOFF + burnalt.
        local burnend is LZOFF + 5.
        local verticalFactor is clamp((burnstart - ship:bounds:bottomaltradar) / (burnstart - burnend), 0, 1).
        local updir is lookdirup(ship:up:vector, facing:topvector).

        set pv to (1 - verticalFactor) * pv + verticalFactor * updir:pitch.
        set yv to (1 - verticalFactor) * yv + verticalFactor * updir:yaw.
    }

return R(pv,yv,rv).

}
//--Throttle--\\

function reentryburn {
    lock steering to up.
    wait until vang(ship:facing:forevector,up:vector) <= 10.
    lock throttle to 0.5.                                                        // REENTRY BURN IS WORK IN PROGRESS, I WOULD ADVISE NOT USE IT
    wait until ship:verticalspeed >=-800 or alt:radar <=60000.
    lock throttle to 0.
}

function landingburn {
wait until alt:radar <= 1000. // Safety Measure
wait until alt:radar <= burnalt.
    until ship:bounds:bottomaltradar <= LZOFF + 5 { // +5 => safety measure + the legs are approximately 3 meters high
        
        if oneengine = false and ship:verticalspeed >=-150 and (SHIP:SENSORS:ACC:MAG / CONSTANT:g0) < 3 {
            ship:partsnamed("TE.19.F9.S1.Engine")[0]:getmodule("ModuleTundraEngineSwitch"):doevent("next engine mode").
            set oneengine to true.
            gear on.
        }
        lock throttle to clamp(((ship:velocity:surface:mag^2)/(2*ship:sensors:grav:mag*(ship:bounds:bottomaltradar-lzoff))),0,1).
    }
wait 4.
    toggle ag10.
}

//----------------------------------------------------MAIN----------------------------------------------------\\

brakes on.
lock steering to srfRetrograde.
wait until alt:radar <=80000.
lock steering to getsteering().
// reentryburn().
landingburn().
wait until ag10.
clearscreen.
falconlanded().
