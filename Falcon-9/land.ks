clearscreen.
//------------------------Variables------------------------\\

runOncePath("lib").

set oneengine to false.
set landingsite to targetland().
set upvec to ship:up:vector.
if landingsite:lat = vessel("ASOG"):geoposition:lat {
    lock LZOFF to vessel("ASOG"):altitude.
} else {
    if hastarget {
        lock LZOFF to target:altitude.
    } else {
        lock LZOFF to max(landingsite:terrainheight,0).
    }
}
//------------------------Functions------------------------\\

function aoa { 

    local retrangle is vang(-ship:velocity:surface,upvec). // angle to be like ship:up
    local ang is clamp(round(vang(-ship:velocity:surface,-ship:velocity:surface+errorvector(landingsite))),0,10). // Kinda like the errorangle you want to cancel
    local tiltangle is round(vang(errorvector(landingsite)-ship:velocity:surface,-ship:velocity:surface)). // The angle that you need for tilting toward landingsite

    if throttle > 0 {
        if oneengine {
            set maoa to clamp(tiltangle,0,retrangle*2). // For those last corrections, you are clamped between retrograde and 5*the angle to be up
        } else {
            set maoa to 0.
        }
    } else {
        set maoa to -ang. // If it don't work try just ang
    }
    return maoa.
}

function getSteering { // Modified version of Edwin Roberts one
    rcscorrections(1000000, landingsite).
    debug(landingsite).
    // debugvisual(landingsite).

    if oneengine = false {

        local velVector is -ship:velocity:surface.
        local correctionVector is errorvector(landingsite).
        set result to velVector + correctionVector.
        local aoa is aoa().
        global burnalt is (ship:velocity:surface:mag^2 * (2 * (ship:maxThrust / ship:mass) - 3 * ship:sensors:grav:mag)) / (2 * ((ship:maxThrust / ship:mass) - ship:sensors:grav:mag) * ((ship:maxThrust / ship:mass) - 3 * ship:sensors:grav:mag)).
        // Burn altitude calculation, knowing that during the burn you will go from 3 to 1 engine (simplified version of (burnaltonengine + burnaltthreengine)/2
        
        if vang(result, velVector) > aoa {
            set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
        }
    
    } else {
        
        local currentTilt is clamp(ship:bounds:bottomaltradar / burnalt, 0, 1) * aoa().
        local aTot is ship:availablethrust / ship:mass.
        local maxD is sqrt(aTot^2 - ship:sensors:grav:mag^2).
        local dist is vxcl(upvec, landingsite:position):mag.

        if dist > (ship:groundspeed^2) / (2 * maxD) and dist > 5 {
            set result to vxcl(upvec, landingsite:position):normalized + upvec / tan(max(0.1, currentTilt)).
        } else {
            local aH is clamp(ship:groundspeed - sqrt(2 * maxD * dist), 0, aTot * sin(currentTilt)).
            set result to -vxcl(upvec, ship:velocity:surface):normalized * aH + upvec * sqrt(max(0, aTot^2 - aH^2)).
        }
    }
        return lookDirUp(result,facing:topvector).
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
    
    lock throttle to clamp(((ship:velocity:surface:mag^2)/(2*ship:sensors:grav:mag*(ship:bounds:bottomaltradar-LZOFF))),0,1).

    until ship:verticalspeed >-5 {
        
        if oneengine = false and ship:verticalspeed >=-150 and (SHIP:SENSORS:ACC:MAG / CONSTANT:g0) < 3 {
            ship:partsnamed("TE.19.F9.S1.Engine")[0]:getmodule("ModuleTundraEngineSwitch"):doevent("next engine mode").
            set oneengine to true.
            gear on.
        }

    }
    
toggle brakes.
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
// falconlanded().
