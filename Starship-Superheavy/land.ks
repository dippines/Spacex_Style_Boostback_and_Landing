//----------------------------------------------------------------------------------LANDING SCRIPT-------------------------------------------------------------------------------\\
clearscreen.
//--Variables--\

set alts to list(80000,25000,10000,2500,0). // The stages of your flight. Feel free to change
set maoa to list(2,6,7,4,2). // each value represent the max angle from retrograde you want during each stage of the flight in alts, they have the same index number. Feel free to change
set threengines to false.
set targetchose to false.
set cluster to ship:partsnamed("SEP.25.BOOSTER.CLUSTER")[0]:getmodule("ModuleSEPEngineSwitch").
set boosteroffset to 70. // booster height
set shipbox to ship:bounds.
lock h to shipbox:bottomaltradar+boosteroffset. // The top altitude of the booster
set landingsite to targetland().
set armsheight to 130+max(landingsite:terrainheight,0).

//--------Functions--------\\

//--Targets--\\

function targetland {
    until targetchose = true{
        Print("Waiting for user to chose a landingsite.").
        
        set keyPress to terminal:input:getchar().
        
        if keyPress = "t" { 
            set landpos to latlng(target:geoposition:lat, target:geoposition:lng).
            set targetchose to true.
        }
        if keyPress = "a" {
            set landpos to latlng(25.9962485183524,-97.154732239204). // OLT-A
            clearScreen.
            print("Go for Catch at OLT-A").
            set targetchose to true.
        }   
        if keyPress = "b" {
            set landpos to latlng(25.9967515622019,-97.1579564069524). // OLT-B
            clearScreen.
            print("Go for Catch at OLT-B").
            set targetchose to true.
        }
        if keyPress = "c" {
            set landpos to latlng(28.6081826102928,-80.601304446744). // OLT-C
            clearScreen.
            print("Go for Catch at OLT-C").
            set targetchose to true.
        }
        if keyPress = "w" {
            set landpos to latlng(25.9962480647979,-96). // Water Test
            clearScreen.
            print("Catch aborted, landing in water").
            set targetchose to true.
        }
        if keyPress = "o" {
            set landpos to latlng(25.8669450105354,-95.5781057662035). // Offshore platform
            clearScreen.
            print("Go for Catch at OFFSHORE PLATFORM").
            set targetchose to true.
        }
    wait 0.5.
    }
    return landpos.
}

//--Math--\\

function clamp {
    parameter val.
    parameter minn.
    parameter maxx.
    return min(max(val,minn),maxx).
}

function sign {
    parameter val.
    return val/abs(val).
}
//--Steering--\\

function getImpact {
    if addons:tr:hasimpact { 
    return addons:tr:impactpos. 
    }
return ship:geoposition.
}

function errorVector {   
    return landingsite:position - getImpact():position.
}

function i {
    from {local idx is 0.} until idx >= alts:length step {set idx to idx+1.} do {
        if alt:radar > alts[idx] {
            return idx. 
        }
    }
    return 0.
}

function aoax { 
    local radius is 10.
    local f is list(-1,1).
    local H1 is round(errorVector():mag).
    local H2 is sign((getimpact():lng-landingsite:lng)). // -1/1 if you are past or ahead (in lng) of landingsite
    local tiltangle is vang(errorvector()-ship:velocity:surface,-ship:velocity:surface). // Tilting angle towards tower
    local upangle is vang(-ship:velocity:surface,ship:up:vector). // angle you want to be like ship:up
    local fac is clamp(ship:bounds:bottomaltradar/armsheight,1,5).
    if throttle > 0 {
        if threengines {
            set maoa[4] to clamp(tiltangle,upangle,upangle*fac) -1. // The more you are close to the tower the more you want to be vertical
            set fx to H2.
        } else {
            set fx to f[1].
            set maoa[4] to upangle.
        }
    } else {
        if H1 <= radius {
            set fx to f[1].
        } else {
            set fx to f[0].
        }
    }
        set finalaoa to maoa[i()]*fx.
        return finalaoa.
}

function getSteering {
    local velVector is -ship:velocity:surface.
    local correctionVector to errorVector().
    local result is velVector + correctionVector.
    local aoa is aoax().
    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }
    rcorrs().

    local val to lookdirup(result, facing:topvector).
    local a to 0.1.

    if threengines = false {
        set steer to R(val:pitch,val:yaw,270). 
    } else if threengines = true and h >= armsheight+15 {
        set steer to R((a * val:pitch) + ((1 - a) * ship:up:pitch),val:yaw,270).
    } else if threengines = true and h <= armsheight+15 {
        set steer to R(ship:up:pitch, ship:up:yaw,270). 
    }
    print((landingsite:position-ship:geoposition:position):mag + "  Meters precise") AT (0,1).
    print maoa[4] AT (0,2).
    print vang(-ship:velocity:surface,ship:up:vector) AT (0,3).
    return steer.
}

//--Throttle--\\

function rcorrs { // RCS Correction depending of the roll of the ship and errorvector
    if alts[1] >= h {
        local ro is ship:facing:roll.
        local lngoff is ship:geoposition:lng - landingsite:lng.
        local latoff is ship:geoposition:lat - landingsite:lat.
        local top_cmd is (-latoff * COS(ro)) - (lngoff * SIN(ro)).
        local starboard_cmd is (-latoff * SIN(ro)) + (lngoff * COS(ro)).

        if top_cmd > 0 {
            set SHIP:CONTROL:TOP to 1.
        } else if top_cmd < 0 {
            set SHIP:CONTROL:TOP to -1.
        } else {
            set SHIP:CONTROL:TOP to 0.
        }

        if starboard_cmd > 0 {
            set SHIP:CONTROL:STARBOARD to 1.
        } else if starboard_cmd < 0 {
            set SHIP:CONTROL:STARBOARD to -1.
        } else {
            set SHIP:CONTROL:STARBOARD to 0.
        }
    }
}

function landingburn {
wait until h <= alts[3].
wait until h <= max(abs(ship:verticalspeed*3),800).
    lock throttle to 1.
    wait 0.1.
    cluster:doevent("previous engine mode").
    until ship:verticalSpeed >=0 {
        
        if threengines = false and ship:verticalspeed >=-100 {
            cluster:doevent("next engine mode").
            set threengines to true.
        }
        
        if ship:verticalspeed <= -300 {
            set mn to 1.
        } else if ship:verticalspeed <=-100 {
            set mn to 0.5.
        } else if threengines {
            set mn to 0.
        }
    lock throttle to clamp(((ship:velocity:surface:mag^2)/(2*ship:sensors:grav:mag*(h-armsheight))),mn,1). // Throttle to be 0m/s at armsheight 
    wait 0.1.
    
}
    RCS off.
    stage. // Engine smoke
    set ship:control:top to 0.
    set ship:control:starboard to 0.
    lock throttle to 0.1.
    wait 15.
    toggle ag2. // booster core rcs (drain fuel)
    wait until ship:liquidfuel <=10 or AG10.
    toggle ag10.
}

//----------------------------------------------------------------------------------MAIN-------------------------------------------------------------------------------\\
RCS ON.
wait until ship:verticalSpeed <0.
lock steering to getsteering().
landingburn().
wait until ag10. // To end just press ag10.

