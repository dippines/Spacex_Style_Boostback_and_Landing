//----------------------------------------------------------------------------------LANDING SCRIPT-------------------------------------------------------------------------------\\

//--Variables--\
set threengines to false.
set chosetarget to false.
set cluster to ship:partsnamed("SEP.25.BOOSTER.CLUSTER")[0]:getmodule("ModuleSEPEngineSwitch").

//--Lists---\\

set alts to list(80000,25000,10000,2500,0). // The stages of your flight. Feel free to change
set f to list(-1,1). // Factor for the angle of attack (aoa)
set maoa to list(4,6,4,3,2). // The AoAs, each value represent the value of the aoa for the stage of the flight in alts, they have the same index number. Feel free to change

//--Constants--\\
set radius to 10.
set boosteroffset to 56.
set heightoffset to ship:bounds.



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
    parameter armsoffset to 0.0001. // Short arms / long arms
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
            set landpos to latlng(25.9967515622019+armsoffset,-97.1579564069524-armsoffset). // OLT-B
            clearScreen.
            print("Go for Catch at OLT-B").
            set chosetarget to true.
        }
        if keyPress = "c" {
            set landpos to latlng(28.6081826102928,-80.601304446744-armsoffset). // OLT-C
            clearScreen.
            print("Go for Catch at OLT-C").
            set chosetarget to true.
        }
        if keyPress = "w" {
            set landpos to latlng(25.9959261063009,-95). // Water Test
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

set armsheight to 120+max(landingsite:terrainheight,0).

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
    local H1 is round(errorVector():mag).
    local H2 is (getimpact():lng-landingsite:lng)/abs(getimpact():lng-landingsite:lng).
    local tiltangle is vang(errorvector()-ship:velocity:surface,-ship:velocity:surface).
    local retrangle is vang(-ship:velocity:surface,ship:up:vector).
    if throttle > 0 {
        if threengines {
            set maoa[4] to clamp(tiltangle,0,retrangle*1.2).
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
        set maxaoa to maoa[i()]*fx.
        // print(errorVector():mag + ":___Meters precise").
        return maxaoa.
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

function rcorrs {
    if alt:radar >= armsheight+20 {
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
} else {
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
    // Roll 
    // local compvec is R(0,0,180):vector.
    // local compvec2 is landingsite:position - ship:geoposition:position.

    // if Vdot(compvec,compvec2:normalized) <0 {
        // set roll to 270-vang(R(0,0,270):vector,compvec2).
    // } else if Vdot(compvec,compvec2:normalized) >0 {
        // set roll to 270+vang(R(0,0,270):vector,compvec2).
    // } else {
        // set roll to 270.
    // }

    local val to lookdirup(result, facing:topvector).
    
    local k to 0.25.
    if threengines = true {
        set str to R((k * val:pitch) + ((1 - k) * ship:up:pitch),val:yaw,270).
    } else {
        set str to R(val:pitch,val:yaw,270). 
    }
    if alt:radar <=20+armsheight {
        set str to R(ship:up:pitch, ship:up:yaw, 270).
    }
    rcorrs().
    return str.
}

//--Throttle--\\

function landingburn {
wait until alt:radar <= alts[3].
wait until alt:radar <= max(abs(ship:verticalspeed*3),800).
    until heightoffset:bottomaltradar+boosteroffset <= armsheight+5 {
        set topalt to heightoffset:bottomaltradar+boosteroffset.
        if ship:verticalspeed <= -300 {
            set mn to 1.
        } else if ship:verticalspeed <=-100 {
            set mn to 0.5.
        } else if threengines {
            set mn to 0.
        }

        if threengines = false and ship:verticalspeed >=-100 {
            cluster:doevent("next engine mode").
            set threengines to true.
        }
    lock throttle to clamp(((ship:verticalspeed^2)/(2*9.81*(topalt-armsheight))),mn,1).
    wait 0.15.
}
    wait until ship:verticalSpeed >=0.
    RCS off.
    toggle ag2.
    set ship:control:top to 0.
    set ship:control:starboard to 0.
    LOCK THROTTLE TO 0.1.
    lock steering to up.
    wait until ship:liquidfuel <=10 or AG10.
    toggle ag10.
}

//----------------------------------------------------------------------------------MAIN-------------------------------------------------------------------------------\\
RCS ON.
wait until ship:verticalSpeed <0.
lock steering to getsteering().
landingburn().
wait until ag10. // To end just press ag10.
