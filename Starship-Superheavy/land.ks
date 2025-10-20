//------------------------Variables------------------------\\

//--Lists---\\
set alts to list(50000,25000,13500,3000,0). // The stages of your flight. Feel free to change
set f to list(-1,1). // Factor for the angle of attack (aoa)
set maoa to list(2,3,6,3,2). // The AoAs, each value represent the value of the aoa for the stage of the flight in alts, they have the same index number. Feel free to change
//--Constants--\\
set radius to 15.
set sd to 500. 


//------------Target------------\\

if hastarget { 
    set landingsite to latlng(target:geoposition:lat, target:geoposition:lng).
} else {
    set landingsite to latlng(28.6358695682399,-80.6013546763036). // Your landingsite position
}

//------------------------Functions------------------------\\


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
    set H1 to errorVector():mag.
    set rx to i().
    if alts[rx] <= alt:radar {
        if H1 < radius {
            if throttle > 0{
                if getimpact():lng-landingsite:lng <0 {
                    set maoa[4] to vang(-ship:velocity:surface, ship:up:vector).
                    set fx to f[0].
                } else {
                    set fx to f[0].
                }
            }
            else {set fx to f[1].}
        
        } else if H1 > radius{
            if throttle > 0 {
                if ship:verticalspeed >=-80 {
                    if getimpact():lng-landingsite:lng >0 {
                        set maoa[4] to 100-vang(errorvector()+ship:up:vector,ship:up:vector).
                        set fx to f[1].
                    } else { set maoa[4] to 2.
                        set fx to f[0].}
                } else {
                    set fx to f[1].
                }
            } 
            else {set fx to f[0].}
        
        } else {
            if alt:radar >= 900 {
            set maoa[rx] to 0.
            set fx to f[1].
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

function getSteering {
    local velVector is -ship:velocity:surface.
    local correctionVector to errorVector().
    local result is velVector + correctionVector.
    local aoa is fdynaoax(). 

    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }
    
    lock steer to lookdirup(result, facing:topvector).
    if alt:radar <=900 {
        set val to R(ship:up:pitch, steer:yaw,270).}
    else {
        set val to R(steer:pitch,steer:yaw,270).}

    return val.
}

//--Throttle--\\

function throt { // W.I.P.
    lock steering to getSteering().
    wait until alt:radar <=1500.
    mechazilla().
    if abs(ship:verticalspeed) > 400 {
        lock throttle to min(max(sd/(alt:radar-39.94),0.7),1).
    } else {
        lock throttle to min(max(sd/(alt:radar-39.94),0.4),1).
    }
    
    wait until ship:verticalspeed >=-80.
    set radius to 15.
    toggle ag1.
    until false {
        if getimpact():lng-landingsite:lng >0 {
            lock throttle to 0.8.
        } else if getimpact():lng-landingsite:lng <0 or ship:verticalspeed >=-35{
            lock throttle to min(max(100/alt:radar,0),0.7). // THIS DONT WORK FOR NOW
            if alt:radar <=200 {lock steering to R(ship:up:pitch,ship:up:yaw,270).}
        }  
        if ship:verticalspeed >=0 {
             lock throttle to 0.
        }
       wait .05.
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
