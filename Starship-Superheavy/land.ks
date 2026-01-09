//----------------------------------------------------------------------------------LANDING SCRIPT-------------------------------------------------------------------------------\\
clearscreen.
//--Variables--\
set upvec to ship:up:vector.

//--Lib calls--\\

runOncePath("lib").
set landingsite to targetland().

//--Booster--\\
set threengines to false.
set cluster to ship:partsnamed("SEP.25.BOOSTER.CLUSTER")[0]:getmodule("ModuleSEPEngineSwitch").
cluster:doevent("previous engine mode"). // 13 engines
set boosteroffset to 70. // booster height
set shipbox to ship:bounds.
lock h to shipbox:bottomaltradar+boosteroffset. // The top altitude of the booster
set armsheight to 130+max(landingsite:terrainheight,0).


//--------Functions--------\\

//--Steering--\\

function aoa { 

    if throttle > 0 {
        // local upangle is vang(-ship:velocity:surface, upvec).

        if threengines {
            // local tiltangle is vang(errorvector(landingsite)-ship:velocity:surface,-ship:velocity:surface).
            set angle to 5.
        } else {
            set angle to 0.
        }
    } else {
        set angle to -clamp(round(vang(-ship:velocity:surface,-ship:velocity:surface+2*errorvector(landingsite))),0,10).
    } 

    return angle.
}

function getSteering {
    rcscorrections(50000, landingsite).
    debug(landingsite).


    if threengines = false {

        local velVector is -ship:velocity:surface.
        local correctionVector is errorvector(landingsite).
        set result to velVector + correctionVector.
        local aoa is aoa().
        global burnalt is (ship:velocity:surface:mag^2)/(2*((ship:maxThrust/ship:mass)-ship:sensors:grav:mag)).
        
        if vang(result, velVector) > aoa {
            set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
        }
        
    } else {
        
        local currentTilt is clamp(h-armsheight / burnalt, 0, 1) * aoa().
        local aTot is ship:availablethrust / ship:mass.
        local maxD is sqrt(aTot^2 - ship:sensors:grav:mag^2).
        local dist is vxcl(upvec, landingsite:position):mag.

        if dist > (ship:groundspeed^2) / (2 * maxD) and dist > 10 {
            set result to vxcl(upvec, landingsite:position):normalized + upvec / tan(max(0.1, currentTilt)).
        } else {
            local aH is clamp(ship:groundspeed - sqrt(2 * maxD * dist), 0, aTot * sin(currentTilt)).
            set result to -vxcl(upvec, ship:velocity:surface):normalized * aH + upvec * sqrt(max(0, aTot^2 - aH^2)).
        }
    }

    local val is lookdirup(result, facing:topvector).
    local p is val:pitch.
    local y is val:yaw.

return R(p, y, 270).

}

//--Throttle--\\

function landingburn {
    wait until h <= 2000.
    wait until h <= max(800,burnalt).
    local mn is 0.
    lock throttle to clamp((ship:velocity:surface:mag^2) / (2 * ship:sensors:grav:mag * (h - armsheight)), mn, 1).

    until ship:verticalSpeed >= 0 {
        if not threengines and ship:verticalspeed >= -100 {
            cluster:doevent("next engine mode").
            set threengines to true.
        }

        if ship:verticalspeed <= -300 {
            set mn to 0.5.
        } else if ship:verticalspeed <= -100 {
            set mn to 0.
        }
        wait 0.
    }

    RCS off.
    stage.

    heavycatched().
    wait 15.
    toggle ag2.
    wait until ship:liquidfuel <= 10 or AG10.
    toggle ag10.
}
//----------------------------------------------------------------------------------MAIN-------------------------------------------------------------------------------\\
RCS ON.
wait until ship:verticalSpeed <0.
lock steering to getsteering().
landingburn().
wait until ag10. // To end just press ag10.
