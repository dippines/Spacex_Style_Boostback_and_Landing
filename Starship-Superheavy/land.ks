
//--Variables--\
set done_ag1 to false.
//--Lists---\\

set alts to list(80000,25000,10000,2500,0). // The stages of your flight. Feel free to change
set f to list(-1,1). // Factor for the angle of attack (aoa)
set maoa to list(4,8,7,3,2). // The AoAs, each value represent the value of the aoa for the stage of the flight in alts, they have the same index number. Feel free to change

//--Constants--\\
set radius to 10.
set boosteroffset to 39.94. 
// set toweroffset to 0.0001.
set armsheight to 110.

//--Target--\\
lock OLTA to latlng(25.9959261063009,-97.153023799664).
// OLT-B : (                ,                 )
// Water test : (25.9956786506544,-96.953023799664)
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
    global H1 is round(errorVector():mag).
    set rx to i().
    global H2 is getimpact():lng-landingsite:lng.
    if alts[rx] <= alt:radar {
        if H1 <= radius {
            if throttle > 0 {
            set maoa[4] to vang(-ship:velocity:surface,ship:up:vector).
                if ship:verticalspeed >=-100 {
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
                if ship:verticalspeed >=-100 {
                    if H2>0 {
                        set maoa[4] to min(max((90-vang(errorvector()+ship:up:vector,ship:up:vector)),1),5).
                        set fx to f[1].
                        print(90-vang(errorvector()+ship:up:vector,ship:up:vector)/2).
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
    rcorrs().
    lock val to lookdirup(result, facing:topvector).
    set k to 0.2.
    if ship:verticalspeed >=-100 {
        set str to R((k * val:pitch) + ((1 - k) * ship:up:pitch),val:yaw,270).
    } else {
        set str to R(val:pitch,val:yaw,270). 
    }
    if alt:radar <=160 {
        set str to R(ship:up:pitch, ship:up:yaw, 270).
    }
    return str.
}

//--Throttle--\\

function landingburn {
wait until alt:radar <= alts[3].
wait until alt:radar <= max(abs(ship:verticalspeed*3),1000).
    until alt:radar <= armsheight{

        if ship:verticalspeed <= -300 {
            set mn to 1.
        } else if ship:verticalspeed <=-100 {
            set mn to 0.7.
        } else {
            set mn to 0.
        }

        if done_ag1 = false and ship:verticalspeed >=-100 {
            toggle ag1.
            set radius to 0.
            set done_ag1 to true.
        }

    lock throttle to min(max(((ship:verticalspeed^2)/(2*9.81*(ship:bounds:bottomaltradar-armsheight+boosteroffset))),mn),1).
    wait 0.3.
}
    set ship:control:top to 0.
    set ship:control:starboard to 0.
    lock throttle to 0.2.
    toggle ag7.
    wait until ship:liquidfuel <=10.
    toggle ag10.
}

//--Main--\\

lock steering to ship:facing.
wait until ship:verticalSpeed <0.
set ship:control:top to 1.
lock steering to srfRetrograde.
wait until vang(srfRetrograde:vector,ship:facing:forevector) <= 10.
lock steering to getsteering().
landingburn().
wait until ag10. // To end just press ag10.
