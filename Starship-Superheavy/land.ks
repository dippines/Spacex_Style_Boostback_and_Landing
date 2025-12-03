//----------------------------------------------------------------------------------LANDING SCRIPT-------------------------------------------------------------------------------\\

//--Variables--\
set threengines to false.
set chosetarget to false.
set cluster to ship:partsnamed("SEP.25.BOOSTER.CLUSTER")[0]:getmodule("ModuleSEPEngineSwitch").

//--Lists---\\

set alts to list(80000,25000,10000,2500,0). // The stages of your flight. Feel free to change
set f to list(-1,1). // Factor for the angle of attack (aoa)
set maoa to list(4,8,7,5,2). // The AoAs, each value represent the value of the aoa for the stage of the flight in alts, they have the same index number. Feel free to change

//--Constants--\\
set radius to 10.
set boosteroffset to 56.
set heightoffset to ship:bounds.



//--------Functions--------\\

//--Targets--\\

function targetland {
    parameter targetoffset to 0.000125. // Short arms / long arms
    until chosetarget = true{
        Print("Waiting for user to chose a landingsite.").
        
        set keyPress to terminal:input:getchar().
        
        if keyPress = "t" { 
            set landpos to latlng(target:geoposition:lat, target:geoposition:lng).
            set chosetarget to true.
        }
        if keyPress = "a" {
            set landpos to latlng(25.9962480647979,-97.1547020248853-targetoffset). // OLT-A
            print("Go for Catch at OLT-A").
            set chosetarget to true.
        }   
        if keyPress = "b" {
            set landpos to latlng(25.9967515622019+targetoffset,-97.1579564069524-targetoffset). // OLT-B
            print("Go for Catch at OLT-B").
            set chosetarget to true.
        }
        if keyPress = "c" {
            set landpos to latlng(28.6081649600038,-80.6012491850909-targetoffset). // OLT-C
            print("Go for Catch at OLT-C").
            set chosetarget to true.
        }
        if keyPress = "w" {
            set landpos to latlng(25.9959261063009,-96). // Water Test
            print("Catch aborted, landing in water").
            set chosetarget to true.
        }
        if keyPress = "o" {
            set landpos to latlng(25.8669450105354,-95.5781057662035). // Offshore platform
            print("Go for Catch at OFFSHORE PLATFORM").
            set chosetarget to true.
        }
    wait 0.5.
    }
    return landpos.
}

set landingsite to targetland().

set LZOFF to max(landingsite:terrainheight,0).
set armsheight to 120+lzoff.

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

function fdynaoax { 
    local H1 is round(errorVector():mag).
    set rx to i().
    local H2 is getimpact():lng-landingsite:lng.
    if H1 < radius {
        if throttle > 0 {
            if threengines = true {
                set maoa[4] to 0.
            } else {
              set maoa[4] to vang(-ship:velocity:surface,ship:up:vector).
              set fx to f[1].
            }
        } else {
            set fx to f[1].
        }
    } else if H1 > radius {
        if throttle > 0 {
            if threengines = true {
                if H2>0 {
                    set maoa[4] to min(max(vang(errorvector():normalized-ship:velocity:surface,ship:up:vector),2),10).
                    set fx to f[1].
                } else {
                    set fx to f[0].
                    set maoa[4] to 2.
                } 
            } else {
                set fx to f[1].
                set maoa[4] to vang(-ship:velocity:surface,ship:up:vector).
            }
        }
        else {
           set fx to f[0].
        }
    } else if H1=radius and threengines = true or alt:radar <= armsheight+20{
        set maoa[4] to 0.
        set radius to 30.
    }

        local maxaoa is maoa[rx]*fx.
        // print(errorVector():mag + ": Meters precise").
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

}

function getSteering {
    local velVector is -ship:velocity:surface.
    local correctionVector to errorVector().
    local result is velVector + correctionVector.
    local aoa is fdynaoax(). 
    
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
    
    local k to 0.2.
    if threengines = true {
        set str to R((k * val:pitch) + ((1 - k) * ship:up:pitch),val:yaw,270).
    } else {
        set str to R(val:pitch,val:yaw,270). 
    }
    // if alt:radar <=20+armsheight {
        // set str to R(ship:up:pitch, ship:up:yaw, roll).
    // }
    rcorrs().
    return str.
}

//--Throttle--\\

function landingburn {
wait until alt:radar <= alts[3].
wait until alt:radar <= max(abs(ship:verticalspeed*3),800).
    until heightoffset:bottomaltradar+boosteroffset <= armsheight+1 {

        if ship:verticalspeed <= -300 {
            set mn to 1.
        } else if ship:verticalspeed <=-100 {
            set mn to 0.5.
        } else {
            set mn to 0.
        }

        if threengines = false and ship:verticalspeed >=-100 {
            cluster:doevent("next engine mode").
            set radius to 0.
            set threengines to true.
        }
    lock throttle to min(max(((ship:verticalspeed^2)/(2*9.81*(heightoffset:bottomaltradar-armsheight+boosteroffset))),mn),1).
    wait 0.2.
}
    toggle ag2.
    set ship:control:top to 0.
    set ship:control:starboard to 0.
    set ship:control:fore to 1.
    LOCK THROTTLE TO 0.1.
    lock steering to up.
    wait until ship:liquidfuel <=10 or AG10.
    toggle ag10.
}

//----------------------------------------------------------------------------------MAIN-------------------------------------------------------------------------------\\
RCS ON.
lock steering to srfRetrograde.
wait until ship:verticalSpeed <0.
lock steering to getsteering().
landingburn().
wait until ag10. // To end just press ag10.
