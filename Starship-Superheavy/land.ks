set distance to 150000.
function ld {
SET kuniverse:defaultloaddistance:flying:LOAD TO distance.   
SET kuniverse:defaultloaddistance:flying:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:flying:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:flying:PACK TO distance.   
SET kuniverse:defaultloaddistance:escaping:LOAD TO distance.   
SET kuniverse:defaultloaddistance:escaping:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:escaping:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:escaping:PACK TO distance.   
SET kuniverse:defaultloaddistance:SUBORBITAL:LOAD TO distance.   
SET kuniverse:defaultloaddistance:SUBORBITAL:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:SUBORBITAL:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:SUBORBITAL:PACK TO distance.   
SET kuniverse:defaultloaddistance:ORBIT:LOAD TO distance.   
SET kuniverse:defaultloaddistance:ORBIT:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:ORBIT:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:ORBIT:PACK TO distance.   
SET kuniverse:defaultloaddistance:prelaunch:LOAD TO distance.   
SET kuniverse:defaultloaddistance:prelaunch:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:prelaunch:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:prelaunch:PACK TO distance.   
SET kuniverse:defaultloaddistance:landed:LOAD TO distance.   
SET kuniverse:defaultloaddistance:landed:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:landed:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:landed:PACK TO distance.   
}
ld().
//------------------------Variables------------------------\\

//------------Lists------------\\
set alts to list(50000,25000,13500,5000,20). // The stages of your flight. Feel free to change
set f to list(-1,1). // Factor for the angle of attack (aoa)
set maoa to list(4,10,6,5,3). // The AoAs, each value represent the value of the aoa for the stage of the flight in alts, they have the same index number. Feel free to change

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

function fdynaoax { // /!\ I try to use common terms in here for you to understand better but the best thing is to run the code and see what you get.
    local errorVector is getimpact():position - landingsite:position.
    local H1 is errorVector:mag. // Scalar value of the error vector
    lock rx to i().
    set radius to 10. //radius of 20m of landingsite
    if alts[rx] <= alt:radar { // <==> If you are in the range of the values in alts
        if H1 < radius { // If you're impact-pos is in a radius of 10m of landingsite
            if throttle > 0{
                if ship:verticalspeed >=-80 {
                    set maoa[4] to 1.2*vang(-ship:velocity:surface, ship:up:vector). // 3 engines corrections
                    set radius to 2.
                } else {
                    set fx to f[0]. // You slow down (13 engines)
                }
            }
            else {set fx to f[1].} // You don't throttle so you just follow the trajectory
        } else {
            if throttle > 0 {
                if ship:verticalspeed >=-80 {
                    set maoa[4] to 1.5*vang(-ship:velocity:surface, ship:up:vector). //  3 engines corrections
                    set radius to 5.
                } else {
                    set fx to f[1]. // You're outside the radius so you throttle in direction of it
                }
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
    // return R(val:pitch,val:yaw,270).
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

function final{
    // avoir un vrai déclencheur
        lock throttle to 1.
        lock steering to getSteering().
        wait until ship:verticalspeed >=-80.
        toggle ag1.
        mechazilla().
        lock throttle to fnthrot(-25).
        lock steering to getSteering().
}



wait until ship:verticalspeed <0. // When you start the descent
lock steering to srfRetrograde. // You lock steering to retrograde
Brakes on. // And open gridfins
SAS OFF.
RCS ON.
wait until alt:radar <=80000. // Until you enter atmosphere
lock steering to getsteering(). // And you start correcting your trajectory
wait until alt:radar <=1200.
final().
wait until ag10. // To end just press ag10.
