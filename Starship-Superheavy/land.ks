
//--Variables--\
set done_ag1 to false.
// lock g to constant:g* body:mass / body:radius^2. // gravity
//--Lists---\\

set alts to list(80000,25000,10000,2500,0). // The stages of your flight. Feel free to change
set f to list(-1,1). // Factor for the angle of attack (aoa)
set maoa to list(4,7,7,4,4). // The AoAs, each value represent the value of the aoa for the stage of the flight in alts, they have the same index number. Feel free to change

//--Constants--\\
set radius to 10.
set boosteroffset to 39.94. 
set toweroffset to 0.0001.
set armsheight to 120.
set nextengheight to 425. 

//--Target--\\
lock OLTA to latlng(25.9959253213676,-97.1530954784706-toweroffset).

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
        return 4.
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
                    if H2>0 {
                        set fx to f[0].
                    }
                    else {
                    set fx to f[1].
                    }
                
                // print("0,0,0").
                }
            } else {
                set fx to f[1].
                // print("0,0").
            }
        } else {
            if throttle > 0 {
                if ship:verticalspeed >=-100 {
                    if H2>0 and H1>=10*radius{
                        set atmfac to alt:radar/nextengheight.
                        set maoa[4] to max(min(atmfac*(95-vang(errorvector()+ship:up:vector,ship:up:vector)),10),1).
                        set fx to f[1].
                        // print("1,0,0,0").
                    } 
                    if H2 <0 and H1 >= 2*radius{
                        set fx to f[0].
                        set maoa[4] to 1.
                        // print("1,0,0,1").
                    }
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
    if (270-ship:facing:roll) <= 45 and alt:radar <=alts[0] {

    set lp1 to getimpact():lng-landingsite:lng.
    set lp2 to getimpact():lat-landingsite:lat. 
    if lp1 > 0 {
        set SHIP:CONTROL:TOP to 1.
    } else {
        set SHIP:CONTROL:TOP to -1.
    }
    if lp2 >0 {
        set SHIP:CONTROL:STARBOARD to 1.
    } else {
        set SHIP:CONTROL:STARBOARD to -1.
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

    if ship:verticalspeed >=-100 {
        set str to R(ship:up:pitch,val:yaw,270).
    } else {
        set str to R(val:pitch,val:yaw,270). 
    }
    return str.
}

//--Throttle--\\

function throt {
wait until alt:radar <= alts[3].
wait until alt:radar <=abs(ship:verticalspeed*3) or alt:radar <=1000.
    until ship:verticalspeed >=0 {
    if ship:verticalspeed <=-100 {
        if abs(ship:verticalspeed) > 300 {
            set mn to 1.
        } else {
            set mn to 0.5.
        }
        lock throttle to min(max(nextengheight/(alt:radar-boosteroffset),mn),1).
    } else {
        
        if done_ag1 = false {
            toggle ag1.
            set radius to 5.
            set done_ag1 to true.
        } 
        if alt:radar <=200 {
            LOCAL velVec IS ship:velocity:surface.
            LOCAL upVec IS ship:up:vector:normalized.
            LOCAL horizontalVelVec IS VXCL(upVec,velVec):normalized.
            LOCAL finvec is -horizontalVelVec+10*upVec.
            lock steering to finvec.
            toggle ag2.
        }
        lock throttle to min(max(((ship:verticalspeed^2)/(2*9.81*(alt:radar-armsheight))),0),1).
    }
    wait 0.5.
}
lock throttle to 0.
}

//--Main--\\

lock steering to heading(landingsite:heading(),225).

wait until ship:verticalspeed <0.

lock steering to getsteering().
throt().

wait until ag10. // To end just press ag10.
