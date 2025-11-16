//------------------------Variables------------------------\\

//------------Lists------------\\
set alts to list(100000,25000,10000,5000,0). // The stages of your flight. Feel free to change
set f to list(-1,1). // Factor for the angle of attack (aoa)
set maoa to list(3,4,5,3,2). // The AoAs, each value represent the value of the aoa for the stage of the flight in alts, they have the same index number. Feel free to change

//--Constants--\\
set radius to 5.
set done_ag1 to false.
//------------Target------------\\
set LZ1 to latlng(28.4857625502468,-80.5429426267221).
//set LZ2 to latlng(28.4877484442497,-80.5449202044373).
//set LZ3 to latlng(                ,                  ).
// set OCISLY to latlng(28.6081189350935,-79.3012441872939)

if hastarget { 
    set landingsite to latlng(target:geoposition:lat, target:geoposition:lng).
    set LZOFF to target:altitude.
} else {
    set landingsite to LZ1. // Your landingsite position
    set LZOFF to 0.
}


//------------------------Functions------------------------\\

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
    if alt:radar > alts[0] {
        return maoa[0].
    }
    if alt:radar <= alts[alts:length - 1] {
        return 4.
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
    if alts[rx] <= alt:radar {
        if H1 <= radius {
            if throttle > 0 {
            set maoa[4] to vang(-ship:velocity:surface,ship:up:vector).
                if ship:verticalspeed >=-100 {
                        set fx to f[0].
                        // print("0,0,0,0").
                } else {
                  set fx to f[1].
                //   print("0,0,1").
                }
            } else {
                set fx to f[1].
                // print("0,1").
            }
        } else {
            if throttle > 0 {
                if ship:verticalspeed >=-100 {
                    set fx to f[1].
                    set maoa[4] to max(min((95-vang(errorvector()+ship:up:vector,ship:up:vector)),10),0).
                    // print("1010101").
                } else { 
                    set fx to f[1].
                    set maoa[4] to vang(-ship:velocity:surface,ship:up:vector).
                    // print("1,0,1").
                }
            }
            else {
               set fx to f[0].
                // print("1,1").
            }
        
        }
        set maxaoa to maoa[rx]*fx.
        //print(errorVector():mag).
        return maxaoa.
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
    return lookdirup(result, facing:topvector).
}

//--Throttle--\\

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

function reentryburn {
    if alt:radar <= 75000 and ship:verticalspeed <=-800 or ship:liquidfuel >=800 {
        lock throttle to 1.
    }
wait until ship:verticalspeed >= -800 or ship:liquidfuel <=800.
lock throttle to 0.
}

function landingburn {

wait until alt:radar <= alts[3].
    until ship:verticalspeed >=0 {

        if done_ag1 = false and ship:verticalspeed >=-100 {
            toggle ag1.
            set radius to 0.
            set done_ag1 to true.
        }
        if ship:bounds:bottomaltradar <= lzoff+150 {
            gear on.
        }
        if ship:bounds:bottomaltradar <= 10 {
            lock steering to ship:up.
        }
    lock throttle to min(max(((ship:verticalspeed^2)/(2*9.81*(ship:bounds:bottomaltradar-lzoff))),0.1),1).
    wait 0.2.
}
    lock steering to ship:up.
    lock throttle to 0.1.
    set ship:control:top to 0.
    set ship:control:starboard to 0.
    toggle ag10.
}

//----------------------------------------------------MAIN----------------------------------------------------\\
brakes.
lock steering to srfRetrograde.
wait until alt:radar <=80000.
lock steering to getsteering().
reentryburn().
landingburn().
wait until ag10.
