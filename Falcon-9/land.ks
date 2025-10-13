// The falcon-9 variant of my landing code.
// What you should change to adapt it to you : 
// - Landingsites positions
// - k value in startalt()
// The code still have many flaws, but will sure get you on point

//------------------------Variables------------------------\\

//------------Lists------------\\
set alts to list(50000,25000,13500,5000,20). // The stages of your flight. Feel free to change
set f to list(-1,1). // Factor for the angle of attack (aoa)
set maoa to list(3,4,5,3,2). // The AoAs, each value represent the value of the aoa for the stage of the flight in alts, they have the same index number. Feel free to change

//------------Target------------\\
//set LZ1 to latlng(28.6083884601472,-80.6497481659008).
//set OCISLY to latlng(28.6356819213369,-79.4865254914434)

if hastarget { 
    set landingsite to latlng(target:geoposition:lat, target:geoposition:lng).
} else {
    set landingsite to latlng(28.4971749954165,-80.5349879288904). // Your landingsite position
}


//------------------------Functions------------------------\\

//------------Throttle------------\\

function startalt {
    lock v1 to ship:verticalSpeed/2. 
    lock Fr to ship:maxthrust.
    lock dm to ship:drymass.
    lock M to (ship:mass+dm)/2. 
    lock g to constant:g * body:mass / body:radius^2.		
    lock n to 0.95. // Expected throttle
    lock k to 1.27. // Adapt this to you the greater it is, the lower your h will be 
    lock h to (v1^2)/(k*(n*(Fr/M)-g)).
    return h.
}

function fnthrot {
    parameter targetSpeed.
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

function fdynaoax { // /!\ I try to use common terms in here for you to understand better but the best thing is to run the code and see what you get.
    local errorVector is getimpact():position - landingsite:position.
    local H1 is errorVector:mag. // Scalar value of the error vector
    lock rx to i().
    if alts[rx] <= alt:radar { // <==> If you are in the range of the values in alts
        if H1 < 8 { // If you're impact-pos is in a radius of 15m of landingsite
            if throttle > 0 {
                set maoa[4] to vang(-ship:velocity:surface, ship:up:vector). // [4] <==> Hoverslam
                set fx to f[0]. // You break
            }
            else {set fx to f[1].} // You don't throttle so you just follow the trajectory
        } else {
            if throttle > 0 {
                set maoa[4] to vang(-ship:velocity:surface, ship:up:vector). // [4] <==> Hoverslam
                set fx to f[1]. // You're outside the radius so you throttle in direction of it
            } 
            else {set fx to f[0].} // You're outside but you don't throttle : you break to guide your trajectory into it
        }
        set maxaoa to maoa[rx]*fx. // The value of the aoa is the corresponding maoa value of alts (by index) * the factor
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
    lock val to lookdirup(result, facing:topvector).
    return val.
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
wait until ship:verticalspeed >= -1300.
RCS on.
set al to startalt().
wait until altitude <= al.
lock throttle to 1.
wait until ship:verticalspeed >= -100.
toggle ag1. // You skip to your last engine sequence
lock throttle to fnthrot(-20).
lock steering to up.
wait until altitude <=300.
lock throttle to fnthrot(-5).
wait until ag10. // To end just press ag10.
