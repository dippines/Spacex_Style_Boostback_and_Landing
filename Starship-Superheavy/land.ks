//--------------------------------------------- LANDING SCRIPT ---------------------------------------------\\
//--Variables--\
set done_ag1 to false. // Three engines
set done_ag2 to false. // Two engines
set threengines to ship:verticalspeed >=-100. // Final corrections

//--Lists---\\

set alts to list(80000,25000,10000,2500,0). // The stages of your flight. Feel free to change, I try to make them correspond to atmosphere levels
set f to list(-1,1). // Factor for the angle of attack (aoa)
set maoa to list(4,7,7,2,4). // The AoAs, each value represent the value of the aoa for the stage of the flight in alts, they have the same index number. Feel free to change

//--Constants--\\

set radius to 10. // 10m radius circle 
set boosteroffset to 39.94.  // Booster height
// set toweroffset to 0.0001. // If you use mechazilla as a target you'll need to sub the lng value with this because it's a bit offset
set armsheight to 110. // catch altitude

//--Target--\\
lock OLTA to latlng(25.9959253213676,-97.1530954784706).
// OLT-B : (                ,                 )
// lock OLTC to latlng(28.6358613988201,-80.6014467035084).

if hastarget { 
    set landingsite to latlng(target:geoposition:lat, target:geoposition:lng).
} else {
    set landingsite to OLTA. // Your landingsite position
}

//--------Functions--------\\


//--AoA--\\

function i {
    if alt:radar > alts[0] {
        return maoa[0].
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
    global H1 is round(errorVector():mag). // Error vector
    set rx to i().
    global H2 is getimpact():lng-landingsite:lng. // Just to know if you're "past" or "before" target, because you don't want to land on the tower
    if alts[rx] <= alt:radar {
        if H1 <= radius {
            if throttle > 0 {
            set maoa[4] to vang(-ship:velocity:surface,ship:up:vector). // Retrograde
                if threengines {
                        set radius to 20. // You block yourself in to not overshoot W.I.P.
                        set fx to f[0].
                } else {
                  set fx to f[1].
                }
            } else {
                set fx to f[1].
            }
        } else {
            if throttle > 0 {
                if threengines {
                    if H2>0 {
                        set maoa[4] to min(max((90-vang(errorvector()+ship:up:vector,ship:up:vector)),1),5). // You tilt toward landingsite ex: IFT-5
                        set fx to f[1].
                    } else {
                        set fx to f[0].
                        set maoa[4] to 2. // W.I.P.
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
        set top_cmd to (-latoff * COS(ro)) - (lngoff * SIN(ro)). // top_cmd and starboard_cmd will use RCS to help the steering
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
    local velVector is -ship:velocity:surface. // -SrfRetrograde
    local correctionVector to errorVector(). 
    local result is velVector + correctionVector. 
    local aoa is fdynaoax(). 
    
    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }
    rcorrs().
    lock val to lookdirup(result, facing:topvector).
    set k to 0.3.
    if threengines {
        set str to R((k * val:pitch) + ((1 - k) * ship:up:pitch),val:yaw,270). // You don't want to pitch too hard because you might fall over so 30% val and 70% up in this case
    } else {
        set str to R(val:pitch,val:yaw,270).  // 270° ==> QD facing tower
    }
    if alt:radar <=200 {
        set str to R(ship:up:pitch, ship:up:yaw, 270).
    }
    return str.
}

//--Throttle--\\

function landingburn {
wait until alt:radar <= alts[3].
lock burn to max(abs(ship:verticalspeed*3),1000).  // W.I.P. but works well
wait until alt:radar <= burn.
    until alt:radar <= armsheight{

        if ship:verticalspeed <= -300 {
            set mn to 1.
        } else if ship:verticalspeed <=-100 {
            set mn to 0.7.
        } else {
            set mn to 0.
        }

        if done_ag1 = false and threengines {
            toggle ag1.
            set radius to 0.
            set done_ag1 to true.
        }

        if alt:radar <=200 {
            if done_ag2 = false {
                toggle ag2.
                set done_ag2 to true.
            }
        }
        lock throttle to min(max(((ship:verticalspeed^2)/(2*9.81*(ship:bounds:bottomaltradar-armsheight+boosteroffset))),mn),1). // This throttle is like a cheat code: it will get you at 0m/s at armsheight alt
    wait 0.2.
}
    set ship:control:top to 0. 
    set ship:control:starboard to 0.
    lock throttle to 0.2.
    wait until ship:liquidfuel <=10.
    toggle ag10.
}

//--Main--\\

lock steering to srfRetrograde.
wait until ship:verticalspeed <0.
lock steering to getsteering().
landingburn().
wait until ag10. // To end just press ag10.
