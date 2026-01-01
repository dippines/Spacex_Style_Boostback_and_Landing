//----------------------------------------------------------------------------------LANDING SCRIPT-------------------------------------------------------------------------------\\
clearscreen.
//--Variables--\

//--Lib calls--\\

runOncePath("lib").
set landingsite to targetland().

//--Booster--\\
set threengines to false.
set cluster to ship:partsnamed("SEP.25.BOOSTER.CLUSTER")[0]:getmodule("ModuleSEPEngineSwitch").
set boosteroffset to 70. // booster height
set shipbox to ship:bounds.
lock h to shipbox:bottomaltradar+boosteroffset. // The top altitude of the booster
set armsheight to 130+max(landingsite:terrainheight,0).


set stages to list(80000,25000,10000,2500,0). // The stagess of your flight. Feel free to change
set angle to list(2,6,7,4,2). // each value represent the max angle from retrograde you want during each stages of the flight in stages, they have the same index number. Feel free to change

//--------Functions--------\\

//--Steering--\\



function index {
    local idx is 0.
    until idx >= stages:length {
        if alt:radar > stages[idx] return idx.
        set idx to idx + 1.
    }
    return 0.
}

function aoa { 

    if throttle > 0 {
        local upangle is vang(-ship:velocity:surface, ship:up:vector).

        if threengines {
            local tiltangle is vang(errorvector(landingsite)-ship:velocity:surface,-ship:velocity:surface).
            local fac is clamp(h/(armsheight + 100), 1, 3).
            set angle[4] to clamp(tiltangle, upangle, upangle * fac).
            set fx to sign(getimpact():lng - landingsite:lng).
        } else {
            set angle[4] to upangle.
            set fx to 1.
        }
    } else {
        if errorVector(landingsite):mag <= 5 { // 10 meter precision
            set fx to 1.
        } else {
            set fx to -1.
        }
    }

    return angle[index()] * fx.
}

function getSteering {

    local velVector is -ship:velocity:surface.
    local correctionVector is errorvector(landingsite).
    local result is velVector + correctionVector.
    local aoa is aoa().

    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }

    rcscorrections(stages[1], landingsite).
    debug(landingsite).

    local val is lookdirup(result, facing:topvector).
    local p is val:pitch.
    local y is val:yaw.

    if threengines {
        local startFunnel is armsheight + 1000.
        local endFunnel is armsheight.
        local verticalFactor is clamp((startFunnel - ship:bounds:bottomaltradar) / (startFunnel - endFunnel), 0, 1).
        set p to (1 - verticalFactor) * p + verticalFactor * ship:up:pitch.
        set y to (1 - verticalFactor) * y + verticalFactor * ship:up:yaw.
    }

return R(p, y, 270).

}




//--Throttle--\\

function landingburn {
    wait until h <= max(1000,(ship:velocity:surface:mag^2)/(2*(((ship:maxThrust*4.33)/ship:mass)-ship:sensors:grav:mag))).
    lock throttle to 1.
    wait 0.1.
    cluster:doevent("previous engine mode").

    local mn is 1.
    lock throttle to clamp((ship:velocity:surface:mag^2) / (2 * ship:sensors:grav:mag * (h - armsheight)), mn, 1).

    until ship:verticalSpeed >= 0 {
        if not threengines and ship:verticalspeed >= -100 {
            cluster:doevent("next engine mode").
            set threengines to true.
        }

        if ship:verticalspeed <= -300 {
            set mn to 0.7.
        } else if ship:verticalspeed <= -100 {
            set mn to 0.
        }
        wait 0.
    }

    RCS off.
    stage.
    set ship:control:top to 0.
    set ship:control:starboard to 0.
    lock throttle to 0.1.
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
