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
    lock v1 to -ship:verticalspeed. 
    lock Fr to ship:maxthrust.
    lock M to ship:mass.
    lock g to constant:g * body:mass / body:radius^2.		
    lock n to 1. // Should always be > to your desired throttle
    lock h to (v1^2)/(2*(n*(Fr/M)-g)). // The altitude you want to start throttling IF the throttle = n
    return h.
}

function fnthrot {
    
lock gravityForce to ship:mass * g.
set targetSpeed to -15. 
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
        if H1 < 15 { // If you're impact-pos is in a radius of 15m of landingsite
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


//------------Mechazilla------------\\
function mechazilla {

    SET MESSAGE TO "Connecting Mechazilla and booster".
    SET C TO VESSEL("Mechazilla"):CONNECTION.
    IF C:SENDMESSAGE(MESSAGE) {                         // This is why you need to run MZ code before launching
        PRINT "Catching".                               // This function send a message to Mechazilla so it can understand it need to act
    }
    
}

//------------------------LANDING------------------------\\



function fuel {
    local isp is 300.
    local deltav is ship:deltav:current.
    local mass_initial is ship:mass.
    local mass_final is mass_initial / constant:e^(deltaV / (Isp * constant:G0)).
    local t is mass_initial - mass_final.
    local unitmass is ship:liquidfuel:mass / ship:liquidfuel.
    local needed is t / unitmass.
    return needed.                                                          // W.I.P. #1

}

wait until ship:verticalspeed <0. // When you start the descent
lock steering to srfRetrograde. // You lock steering to retrograde
Brakes on. // And open gridfins
SAS OFF.
RCS ON.
wait until alt:radar <=80000. // Until you enter atmosphere
RCS OFF. // Then you don't really need rcs
lock steering to getsteering(). // And you start correcting your trajectory
wait until alt:radar <=10000. // When the hoverslam will soon start
RCS on. 
// W.I.P. #1
wait until alt:radar <= startalt(). // You need to start the hoverslam
lock throttle to 0.9. // So you throttle just a little bit less than the n value (IT SHOULD NEVER BE >, i dont really know if it can be =)
wait until ship:verticalspeed >= -50. // Then when you've braked enough
toggle ag1. // You skip to your last engine sequence
lock throttle to fnthrot(). // And throttle at a specific value
wait until ag10. // To end just press ag10.
