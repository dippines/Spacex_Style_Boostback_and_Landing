clearscreen.
//------------------------Variables------------------------\\

runOncePath("lib").

set oneengine to false.
set landingsite to targetland().
set LZOFF to max(landingsite:terrainheight,0).

//------------------------Functions------------------------\\

function aoa { 

    local vectopad to landingsite:position-ship:position.
    local retrangle is vang(-ship:velocity:surface,ship:up:vector). // angle you want to be like ship:up
    local ang is clamp(round(vang(vectopad,ship:velocity:surface)),retrangle,5).
    local tiltangle is vang(errorvector(landingsite)-ship:velocity:surface,-ship:velocity:surface). // Tilting angle towards landingsite
    local fac is clamp(ship:bounds:bottomaltradar/100, 1,1.5).
    if throttle > 0 {
        if oneengine {
            set maoa to clamp(tiltangle,retrangle,retrangle*fac).
        } else { 
            set maoa to ang.
        }
    } else {
        set maoa to -ang.
    }
    return maoa.
}

function getSteering {

    local velVector is -ship:velocity:surface.
    local correctionVector is errorvector(landingsite).
    local result is velVector + correctionVector.
    local aoa is aoa().
    global calc is (ship:velocity:surface:mag^2)/(2*((ship:maxThrust/ship:mass)-ship:sensors:grav:mag)).

    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }

    rcscorrections(1000000, landingsite).
    debug(landingsite).

    local val is lookdirup(result, facing:topvector).
    local p is val:pitch.
    local y is val:yaw.
    if oneengine {
        local startFunnel is LZOFF + 1000.
        local endFunnel is LZOFF + 50.
        local verticalFactor is clamp((startFunnel - ship:bounds:bottomaltradar) / (startFunnel - endFunnel), 0, 1).
        set p to (1 - verticalFactor) * p + verticalFactor * ship:up:pitch.
        set y to (1 - verticalFactor) * y + verticalFactor * ship:up:yaw.

    }

return R(p, y, val:roll).

}
//--Throttle--\\

function reentryburn {
    lock throttle to 0.5.
    wait until (ship:verticalspeed >=-800 and ship:liquidfuel <=800) or alt:radar <=60000.
    lock throttle to 0.
}

function landingburn {

wait until alt:radar <= calc.
    until ship:verticalspeed >=0 {

        if oneengine = false and ship:verticalspeed >=-150 and (SHIP:SENSORS:ACC:MAG / CONSTANT:g0) <3{
            toggle ag1.
            set oneengine to true.
            gear on.
        }
        
    lock throttle to min(max(((ship:velocity:surface:mag^2)/(2*ship:sensors:grav:mag*(ship:bounds:bottomaltradar-lzoff))),0),1).
}
    toggle ag10.
}

//----------------------------------------------------MAIN----------------------------------------------------\\

brakes on.
lock steering to srfRetrograde.
wait until alt:radar <=80000.
lock steering to getsteering().
reentryburn().
landingburn().
wait until ag10.
