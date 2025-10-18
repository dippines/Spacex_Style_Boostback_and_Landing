//------------------------Variables------------------------\\

//------------Lists------------\\
set alts to list(50000,25000,13500,5000,20). // The stages of your flight. Feel free to change
set f to list(-1,1). // Factor for the angle of attack (aoa)
set maoa to list(4,7,8,4,3). // The AoAs, each value represent the value of the aoa for the stage of the flight in alts, they have the same index number. Feel free to change
set radius to 50.
//------------Target------------\\
//set LZ1 to latlng(28.6083884601472,-80.6497481659008).
//set OCISLY to latlng(28.6356819213369,-79.4865254914434)
//LPD latlng(28.6373715753433,-80.6050788442709)
if hastarget { 
    set landingsite to latlng(target:geoposition:lat, target:geoposition:lng).
} else {
    set landingsite to latlng(28.637138460196,-80.6050788442709). // Your landingsite position
}


//------------------------Functions------------------------\\

//------------Throttle------------\\

function fnthrot {
    parameter targetSpeed.
lock g to constant:g * body:mass / body:radius^2.
lock gravityForce to ship:mass * g.
lock speedError to targetSpeed - ship:verticalspeed.
lock throttleAdjustment to (speedError * ship:mass) / (ship:availablethrust + gravityForce).
lock ApproachThrottle to throttleAdjustment.
return ApproachThrottle. // Gives a throttle that fixes you at a certain speed (not to mistake with hovering)
}

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
    local errorVector is getimpact():position - landingsite:position.
    local H1 is abs(errorVector:mag).
    lock rx to i().
    if alts[rx] <= alt:radar {
        if H1 < radius {
            if throttle > 0{
                if ship:verticalspeed >=-35 {
                    set maoa[4] to vang(-ship:velocity:surface, ship:up:vector).
                    set fx to f[0].
                } else {
                    set fx to f[1].
                }
            }
            else {set fx to f[1].}
        } else {
            if throttle > 0 {
                if ship:verticalspeed >=-80 {
                    set maoa[4] to 12.
                    set fx to f[1].
                } else {
                    set fx to f[1].
                }
            } 
            else {set fx to f[0].}
        }
        set maxaoa to maoa[rx]*fx.
        return maxaoa.
    }
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
    
    lock steer to lookdirup(result, facing:topvector).
    // rcsx().
    // return val.
    if alt:radar <=1000 {set val to R(ship:up:pitch, steer:yaw,270).}
    else {set val to R(steer:pitch,steer:yaw,270).}


    return val.
}

//function rcsx {
//    lock latoff to (landingsite:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472.  
//        if latoff > 0 {set z to 1.} 
//        else {set z to -1.}
//
//    set ship:control:starboard to min(max(z,0),1).
//    print("sbtest...."+latoff).
//
//}
//------------Mechazilla------------\\
function mechazilla {

    SET MESSAGE TO "Connecting Mechazilla and booster".
    SET C TO VESSEL("Mechazilla"):CONNECTION.
    IF C:SENDMESSAGE(MESSAGE) {                         // This is why you need to run MZ code before launching
        PRINT "Catching".                               // This function send a message to Mechazilla so it can understand it need to act
    }
    
}

//------------------------LANDING------------------------\\

function final{
    if ship:verticalspeed <=-300 {
        set sd to 400. // you want to be stop at 400m
        lock throttle to min(max(sd/(alt:radar-39.94),0),1).
        lock steering to getSteering().
        mechazilla().
        wait until ship:verticalspeed >=-80.
        set radius to 1.
        toggle ag1.
        lock throttle to fnthrot(-20).
        lock steering to getSteering().
        wait until alt:radar <=200.
        lock steering to R(ship:up:pitch,ship:up:yaw,270).
    }
}


toggle ag3. // Gridfins
wait until ship:verticalspeed <0. // When you start the descent
lock steering to srfRetrograde. // You lock steering to retrograde
Brakes on. // And open gridfins
SAS OFF.
RCS ON.
wait until alt:radar <=80000. // Until you enter atmosphere
set radius to 20.
lock steering to getsteering(). // And you start correcting your trajectory
wait until alt:radar <=1000.
set radius to 10.
final().
wait until ag10. // To end just press ag10.
