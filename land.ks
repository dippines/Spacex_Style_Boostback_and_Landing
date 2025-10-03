// Still work in progress I'm pretty sure it could get you close to target but never pinpoint
// Future updates : create a list that depending on the flight situation apply a certain value that changes the flight plan



//--Variables-------------------------------------------------------------------------|

//--Target-------------------------------------------------------------------|
if hastarget { 
    set landingsite to latlng(target:geoposition:lat, target:geoposition:lng).
} else {
    set landingsite to latlng(28.478863,-80.528986).
}

//--Impact-Distance-----------------------------------|
if addons:tr:available and addons:tr:hasimpact
{	lock impactDist to addons:tr:impactpos:distance+100.}


//--Throttle--------------------------------------------------------|

lock g to constant:g * body:mass / body:radius^2.					
lock maxDecel to (ship:availablethrust / ship:mass) - g.			
lock stopDist to ship:velocity:surface:sqrmagnitude / (2 * maxDecel).
lock idealThrottle to stopDist / impactDist.						


//--Functions----------------------------------------------------------------|

//--Error vector---------------------------------------|
function errorVector {   
    return  landingsite:position - getImpact():position.
}

//--GetImpact--------------------------------------------|
function getImpact {
    if addons:tr:hasimpact { 
    return addons:tr:impactpos. 
    }
return ship:geoposition.
}

//----------------------------------------------------------------------------------LANDING-------------------------------------------------------------------------------//

//--Steering-------------------------------------------------------|
lock ev to errorVector(). // Error Vector
lock rv to srfRetrograde:vector. // Retrograde vector
lock an to VANG(ev,rv). // Angle between error and retrograde vectors
lock stone to heading(landingsite:heading,srfRetrograde:vector:mag+an). // Head toward landingsite, with the retrograde inclination +the "error angle"
lock finaoa to -5. // AoA when th
lock stwo to -ship:velocity:surface:normalized + tan(finaoa) * ev():normalized.

//--Main-Loop-----------------------------------------------------------------|

until false {
if alt:radar <=stopDist and alt:radar <=5000  {

lock steering to stwo.
lock throttle to idealThrottle.

} 
else {

lock steering to stone.

}
wait 0.1.
}

