
//--------Variables--------\\

//--Lists---\\

set alts to list(100000,25000,10000,2000,0). // The stages of your flight. Feel free to change
set f to list(-1,1). // Factor for the angle of attack (aoa)
set maoa to list(4,7,8,3,4). // The AoAs, each value represent the value of the aoa for the stage of the flight in alts, they have the same index number. Feel free to change

//--Constants--\\

set radius to 10.
set altoffset to 39.94. 

//--Target--\\

// OLT-A : (                ,                 )
// OLT-B : (                ,                 )
lock OLTC to latlng(28.6358613988201,-80.6014467035084).
if hastarget { 
    set landingsite to latlng(target:geoposition:lat, target:geoposition:lng).
} else {
    set landingsite to OLTC. // Your landingsite position
}

//--------Functions--------\\


//--AoA--\\

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
    if alts[rx] <= alt:radar {
        if H1 <= radius {
            if throttle > 0 {
                if ship:verticalspeed >=-100 {
                set maoa[4] to vang(-ship:velocity:surface,ship:up:vector).
                set fx to f[0].
                //    print("0,0").
            } else {
                set fx to f[1].
            }
            }
            else {
                set fx to f[1].
            //    print("0,1").
            }
        } else {
            if throttle > 0 {
                if ship:verticalspeed >=-100 {
                    if getimpact():lng-landingsite:lng >0 {
                        set maoa[4] to min(95-vang(errorvector()+ship:up:vector,ship:up:vector),12).
                        set fx to f[1].
                    //    print("1,0,0,0").
                    } 
                    if getimpact():lng-landingsite:lng <0 and H1 >= radius {
                        set fx to f[0].
                        set maoa[4] to vang(-ship:velocity:surface,ship:up:vector).
                    //    print("1,0,0,1").
                    }
                } else {
                    set fx to f[0].
                //    print("1,0,1").
                }
            }
            else {
               set fx to f[0].
            //    print("1,1").
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
if (270-ship:facing:roll) <= 75 {
    set lp1 to getimpact():lng-landingsite:lng.
    set lp2 to getimpact():lat-landingsite:lat. 
    if lp1 >0 {
        set SHIP:CONTROL:TOP to 1.
    } else {
        set SHIP:CONTROL:TOP to -1.
    }
    if lp2 >0 {
        set SHIP:CONTROL:STARBOARD to 1.
    } else {
        set SHIP:CONTROL:STARBOARD to -1.
    }
    if alt:radar <=200 {
        set SHIP:CONTROL:FORE to 1.
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
    
    lock steer to lookdirup(result, facing:topvector).
    rcorrs().
    if ship:verticalspeed >= -100 {
        set val to R((ship:up:pitch+steer:pitch)/2,steer:yaw,270).
    }
    else {
        set val to R(steer:pitch,steer:yaw,270).
    }
    return val.
}

//--Throttle--\\

function throt {

wait until alt:radar <=alts[3].
mechazilla().
wait until alt:radar <= abs(ship:verticalspeed*3).
set done_ag1 to false.
    until ag10 {
    set sd to 450.
    if ship:verticalspeed <= -100 {
        if abs(ship:verticalspeed) > 400 {
            set mn to 1.
        } else {
            set mn to 0.5.
        }
            lock throttle to min(max(sd/(alt:radar-altoffset),mn),1).
    } else {
    lock Hin to round(errorVector():mag).
    set sd to 130.
    set radius to 5.
    lock factor to min(max(((H1+1)/Hin),1),5).

    lock throttle to min(max(factor*((ship:verticalspeed^2)/(2*9.81*(alt:radar-sd))),0.1),1).

    if alt:radar <=160{
        lock steering to R(ship:up:pitch,ship:up:yaw,270).
        toggle ag2.
        lock factor to 1.
    }
        if done_ag1 = false {
        toggle ag1.
        set done_ag1 to true.
    }
}
    wait 0.05.
    }
}

//--Mechazilla--\\
function mechazilla {

    SET MESSAGE TO "Connecting Mechazilla and booster".
    SET C TO VESSEL("Mechazilla"):CONNECTION.
    IF C:SENDMESSAGE(MESSAGE) {                         // This is why you need to run MZ code before launching
        PRINT "Catching".                               // This function send a message to Mechazilla so it can understand it need to act
    }
    
}

//--Main--\\
wait until ship:verticalspeed <0.
lock steering to getsteering().
throt().
wait until ag10. // To end just press ag10.
