set landingsite to latlng(28.478863,-80.528986).


until false {
  function getImpact {
    if addons:tr:hasimpact { return addons:tr:impactpos. 
  }
  return ship:geoposition.
}
function errorVector {   
    return  landingsite:position - getImpact():position.
}

lock lngoff to (landingsite:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472.
lock latoff to (landingsite:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472.
print "lngoff .......... :" + lngoff.
print "latoff .......... :" + lngoff.

lock g to constant:g * body:mass / body:radius^2.
lock maxDecel to (ship:availablethrust / ship:mass) - g.
lock stopDist to (ship:verticalspeed^2 / (2 * maxDecel)) * 2.
local acc to ship:availablethrust/ship:mass.
lock idealThrust to acc/(ship:availablethrust/ship:mass).

if alt:radar<=stopDist and alt:radar <=10000  {

if abs(lngoff) or abs(latoff) <= 10 {
  lock steering to -ship:velocity:surface.
  lock throttle to idealThrust.
} else {
  global horizontal_factor is 0.1.
  lock verticalVelocity to ship:up:vector * ship:verticalSpeed. // upwards vertical speed
  lock steering to (- verticalVelocity - horizontal_factor*(ship:velocity:surface-verticalVelocity)):direction. //lock against velocity with a bias to horizontal
  lock throttle to idealThrust.
  
}

} 
else {
  lock y to landingsite:position-ship:position.
lock steering to 2*errorVector()+y.
}

}
