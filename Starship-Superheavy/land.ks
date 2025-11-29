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
set boosteroffset to 39.94. 
set heightoffset to ship:bounds.
// set toweroffset to 0.00005.



//--------Functions--------\\

//--Targets--\\

function targetland {
    until chosetarget = true{
        Print("Waiting for user to chose a landingsite.").
    
        if hastarget = true { 
            set landpos to latlng(target:geoposition:lat, target:geoposition:lng).
            set chosetarget to true.
        }
        set keyPress to terminal:input:getchar().
        if keyPress = "a" {
            set landpos to latlng(25.9962480647979,-97.1547020248853). // OLT-A
            set chosetarget to true.
        }   
        if keyPress = "b" {
            set landpos to latlng(25.9967515622019,-97.1579564069524). // OLT-B
            set chosetarget to true.
        }
        if keyPress = "c" {
            set landpos to latlng(28.6358613988201,-80.6014467035084). // OLT-C
            set chosetarget to true.
        }
        if keyPress = "w" {
            set landpos to latlng(25.9959261063009,-96). // Water Test
            set chosetarget to true.
        }
        if keyPress = "o" {
            set landpos to latlng(25.8669450105354,-95.5781057662035). // Offshore platform
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
    if alts[rx] <= alt:radar {
        if H1 <= radius {
            if throttle > 0 {
            set maoa[4] to vang(-ship:velocity:surface,ship:up:vector).
                if threengines = true {
                        set radius to 30.
                        set fx to f[0].
                } else {
                  set fx to f[1].
                }
            } else {
                set fx to f[1].
            }
        } else {
            if throttle > 0 {
                if threengines = true {
                    if H2>0 {
                        set maoa[4] to min(max((90-vang(errorvector()+ship:up:vector,ship:up:vector)),1),7).
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
        }
        set maxaoa to maoa[rx]*fx.
        return maxaoa.
    }
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
    RCS ON.
    if alt:radar <= alts[0] { 

        set ro to ship:facing:roll.
        set lngoff to getimpact():lng - landingsite:lng.
        set latoff to getimpact():lat - landingsite:lat.
        set top_cmd to (-latoff * COS(ro)) - (lngoff * SIN(ro)).
        set starboard_cmd to (-latoff * SIN(ro)) + (lngoff * COS(ro)).

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

function getSteering {
    local velVector is -ship:velocity:surface.
    local correctionVector to errorVector().
    local result is velVector + correctionVector.
    local aoa is fdynaoax(). 
    
    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }
    // Roll 
    local compvec is R(0,0,180):vector.
    local compvec2 is landingsite:position - ship:geoposition:position.

    if Vdot(compvec,compvec2:normalized) <0 {
        set roll to 270-vang(R(0,0,270):vector,compvec2).
    } else if Vdot(compvec,compvec2:normalized) >0 {
        set roll to 270+vang(R(0,0,270):vector,compvec2).
    } else {
        set roll to 270.
    }

    local val to lookdirup(result, facing:topvector).
    
    local kpit to 0.2.
    local krol to 0.4.
    if threengines = true {
        set str to R((kpit * val:pitch) + ((1 - kpit) * ship:up:pitch),val:yaw,(krol * roll) + ((1 - krol) * 270)).
    } else {
        set str to R(val:pitch,val:yaw,270). 
    }
    if alt:radar <=160 {
        set str to R(ship:up:pitch, ship:up:yaw, roll).
    }
    rcorrs().
    return str.
}

//--Throttle--\\

function landingburn {
wait until alt:radar <= alts[3].
wait until alt:radar <= max(abs(ship:verticalspeed*3),1000).
    until alt:radar <= armsheight+10{

        if ship:verticalspeed <= -300 {
            set mn to 1.
        } else if ship:verticalspeed <=-100 {
            set mn to 0.7.
        } else {
            set mn to 0.
        }

        if threengines = false and ship:verticalspeed >=-100 {
            cluster:doevent("next engine mode").
            set radius to 0.
            set threengines to true.
            set ship:control:fore to 1.
        }
        if alt:radar <= armsheight+20 {
            lock steering to ship:up.
        }
    lock throttle to min(max(((ship:verticalspeed^2)/(2*9.81*(heightoffset:bottomaltradar-armsheight+boosteroffset))),mn),1).
    wait 0.3.
}
    toggle ag2.
    set ship:control:top to 0.
    set ship:control:starboard to 0.
    lock steering to up.
    lock throttle to 0.1.
    wait until ship:liquidfuel <=10 or AG10.
    toggle ag10.
}

//----------------------------------------------------------------------------------MAIN-------------------------------------------------------------------------------\\

Print("Go for catch at" + landingsite).
lock steering to srfRetrograde.
wait until ship:verticalSpeed <0.
lock steering to getsteering().
landingburn().
wait until ag10. // To end just press ag10.
