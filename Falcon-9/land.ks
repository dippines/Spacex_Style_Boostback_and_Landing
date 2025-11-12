
//------------------------Variables------------------------\\

//------------Lists------------\\
set alts to list(100000,25000,10000,5000,0). // The stages of your flight. Feel free to change
set f to list(-1,1). // Factor for the angle of attack (aoa)
set maoa to list(3,4,5,3,2). // The AoAs, each value represent the value of the aoa for the stage of the flight in alts, they have the same index number. Feel free to change
//--Constants--\\
set boosteroffset to 31.
set radius to 5.
set done_ag1 to false.
//------------Target------------\\
set LZ1 to latlng(28.4857625502468,-80.5429426267221).
//set LZ2 to latlng(28.4877484442497,-80.5449202044373).
//set LZ3 to latlng().
//set OCISLY to latlng(28.6356819213369,-79.4865254914434)

if hastarget { 
    set landingsite to latlng(target:geoposition:lat, target:geoposition:lng).
} else {
    set landingsite to LZ1. // Your landingsite position
}


//------------------------Functions------------------------\\


//------------Error vector------------\\
function errorVector {   
    return landingsite:position - getImpact():position.
}

//------------GetImpact------------\\
function getImpact {
    if addons:tr:hasimpact { 
    return addons:tr:impactpos. 
    }
return ship:geoposition.
}

//------------AoA------------\\

function i {
    if alt:radar > alts[0] {
        return 0.
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
    global H2 is getimpact():lng-landingsite:lng.
    if alts[rx] <= alt:radar {
        if H1 <= radius {
            if throttle > 0 {
            set maoa[4] to vang(-ship:velocity:surface,ship:up:vector).
                if ship:verticalspeed >=-100 {
                    if H2>0 {
                        set fx to f[0].
                        // print("0,0,0,0").
                    }
                    else {
                    set fx to f[1].
                    // print("0,0,0,1").
                    }
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
                    set maoa[4] to max(min((95-vang(errorvector()+ship:up:vector,ship:up:vector)),5),1).
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
        // print("H1___:"+ H1).
        return maxaoa.
    }
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

function throt {

wait until alt:radar <= alts[3].
    until ship:verticalspeed >=0 {

        if done_ag1 = false and ship:verticalspeed >=-100 {
            toggle ag1.
            set radius to 1.
            set done_ag1 to true.
        }

        if alt:radar <= 100 {
            gear on.
        }
        if alt:radar <=50 {
            LOCAL velVec IS ship:velocity:surface.
            LOCAL upVec IS ship:up:vector:normalized.
            LOCAL horizontalVelVec IS VXCL(upVec,velVec):normalized.
            LOCAL finvec is -horizontalVelVec+10*upVec.
            lock steering to finvec.
            rcorrs().
        }
        
    lock throttle to min(max(((ship:verticalspeed^2)/(2*9.81*(alt:radar-boosteroffset))),0),1).
    print((landingsite:position-ship:geoposition:position):mag + ":...Meters precise").
    wait 0.2.
}
    lock steering to ship:up.
    lock throttle to 0.
    toggle ag10.
}
//------------Steering------------\\

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

//------------------------LANDING------------------------\\




wait until ship:verticalspeed <0. // When you start the descent
lock steering to srfRetrograde. // You lock steering to retrograde
Brakes on. // And open gridfins
SAS OFF.
RCS ON.
wait until alt:radar <=80000. // Until you enter atmosphere
lock steering to getsteering(). // And you start correcting your trajectory
wait until alt:radar <= 20000.
throt().
wait until ag10. // To end just press ag10.
