//----------------------------------------------------------------------------------LANDING SCRIPT-------------------------------------------------------------------------------\\

//--Variables--\
set threengines to false.
set chosetarget to false.
set cluster to ship:partsnamed("SEP.25.BOOSTER.CLUSTER")[0]:getmodule("ModuleSEPEngineSwitch").

//--Lists---\\

set alts to list(80000,25000,10000,2500,0). // The stages of your flight. Feel free to change
set maoa to list(2,6,7,2,2). // each value represent the max angle from retrograde you want during each stage of the flight in alts, they have the same index number. Feel free to change

//--Constants--\\
set radius to 10. // Precision of the landing
set boosteroffset to 70. // Booster height
set shipbox to ship:bounds.
lock h to shipbox:bottomaltradar+boosteroffset. // The top altitude of the booster

//--------Functions--------\\

//--Clamp--\\
function clamp {
    parameter val.
    parameter minn.
    parameter maxx.
    return min(max(val,minn),maxx).
}

//--Targets--\\

function targetland {
    until chosetarget = true{
        Print("Waiting for user to chose a landingsite.").
        
        set keyPress to terminal:input:getchar().
        
        if keyPress = "t" { 
            set landpos to latlng(target:geoposition:lat, target:geoposition:lng).
            set chosetarget to true.
        }
        if keyPress = "a" {
            set landpos to latlng(25.9962485183524,-97.154732239204). // OLT-A
            clearScreen.
            print("Go for Catch at OLT-A").
            set chosetarget to true.
        }   
        if keyPress = "b" {
            set landpos to latlng(25.9967515622019,-97.1579564069524). // OLT-B
            clearScreen.
            print("Go for Catch at OLT-B").
            set chosetarget to true.
        }
        if keyPress = "c" {
            set landpos to latlng(28.6081826102928,-80.601304446744). // OLT-C
            clearScreen.
            print("Go for Catch at OLT-C").
            set chosetarget to true.
        }
        if keyPress = "w" {
            set landpos to latlng(25.9962480647979,-96). // Water Test
            clearScreen.
            print("Catch aborted, landing in water").
            set chosetarget to true.
        }
        if keyPress = "o" {
            set landpos to latlng(25.8669450105354,-95.5781057662035). // Offshore platform
            clearScreen.
            print("Go for Catch at OFFSHORE PLATFORM").
            set chosetarget to true.
        }
    wait 0.5.
    }
    return landpos.
}

set landingsite to targetland().
set armsheight to 134+max(landingsite:terrainheight,0). // Real value is 135 but for a smooth landing 134 is better

//--AoA--\\

function i {
    
    if alt:radar > alts[0] {
        maoa[0].
    }
    if alt:radar <= alts[alts:length - 1] {
        return 0.
    } 
    for idx in range(0, alts:length - 1) {
        if alt:radar <= alts[idx] and alt:radar > alts[idx+1] {
            return idx + 1. // Gives the index number that fits your alt, Example : vessel is at 30km, it will give 1 (alts[1]=25000)
        }
    }
}

function aoax { 
    local f is list(-1,1).
    local H1 is round(errorVector():mag).
    local H2 is (getimpact():lng-landingsite:lng)/abs(getimpact():lng-landingsite:lng). // -1/1 if you are past or ahead (in lng) of landingsite
    local tiltangle is vang(errorvector()-ship:velocity:surface,-ship:velocity:surface). // Tilting angle towards tower
    local retrangle is vang(-ship:velocity:surface,ship:up:vector). // angle you want to be like ship:up
    local fac is clamp(h/armsheight,1,5).
    if throttle > 0 {
        if threengines {
            set maoa[4] to clamp(tiltangle,retrangle,retrangle*fac). // The more you are close to the tower the more you want to be vertical
            set fx to H2.
        } else {
            set fx to f[1].
            set maoa[4] to retrangle.
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

function rcorrs { // RCS Correction depending of the roll of the ship and errorvector
    if alts[1] >= h and h >= armsheight+20{
        local ro is ship:facing:roll.
        local lngoff is getimpact():lng - landingsite:lng.
        local latoff is getimpact():lat - landingsite:lat.
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
    } else if h >= armsheight+20 {
    set ship:control:starboard to (ship:up:pitch - ship:facing:pitch)/abs((ship:up:pitch - ship:facing:pitch)).
    set ship:control:top to (ship:up:yaw - ship:facing:yaw)/abs((ship:up:yaw - ship:facing:yaw)).
    set ship:control:fore to 1.
}
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
    // ROLL : COMING SOON

    local val to lookdirup(result, facing:topvector).
    
    local a to 0.1.
    if threengines = true {
        set steer to R((a * val:pitch) + ((1 - a) * ship:up:pitch),val:yaw,270).
    } else {
        set steer to R(val:pitch,val:yaw,270). 
    }
    if h <=10+armsheight {
        set steer to R(ship:up:pitch, ship:up:yaw, 270). 
    }
    print((ship:sensors:acc:mag)).
    print(errorVector():mag + ":___Meters precise").

    return steer.
}

//--Throttle--\\

function landingburn {
wait until h <= alts[3].
wait until h <= max(abs(ship:verticalspeed*3),800).
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
    lock throttle to clamp(((ship:verticalspeed^2)/(2*ship:sensors:grav:mag*(h-armsheight))),mn,1). // Throttle to be 0m/s at armsheight 
    wait 0.15.
    
}
    RCS off.
    stage. // Engine smoke
    set ship:control:top to 0.
    set ship:control:starboard to 0.
    LOCK THROTTLE TO 0.1.
    wait 30.
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
