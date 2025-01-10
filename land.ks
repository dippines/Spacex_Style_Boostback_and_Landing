ld().// load distance
set k to 1. // error scaling
lock m to ship:mass. // mass
lock g to constant:g* body:mass / body:radius^2. // gravity
lock p to m * g. // weight
lock vi to -25. // desired speed
lock se to vi - ship:verticalspeed. // speed error
lock fm to ship:availablethrust. // available thrust
lock thr to (se * m) / (fm + p). // throttle that will make the ship stay at vi
function getImpact {
    if addons:tr:hasimpact { return addons:tr:impactpos. }
    return ship:geoposition.
}
if hastarget {set landingsite to latlng(target:geoposition:lat, target:geoposition:lng).} else {set landingsite to latlng(28.6370253021226,-80.6014334665529). }
function errorVector {
    return getImpact():position - landingsite:position.}
function defAOA {
    local vspeed is ship:verticalspeed. // vertical speed
    local gspeed is ship:groundspeed. // ground speed
    local h is (alt:radar/apoapsis). // altitude ratio you might change apoapsis to the max alt that your ship had reach.
    local t is (1-alt:radar/140000). // atmosphere something
    local vm is vspeed/1500. // speed/maxspeed
    if throttle >0 {
        lock aoa to -1*(arctan(abs(vspeed/gspeed))*t*abs(vm)*h).
    } 
    else {lock aoa to (arctan(abs(vspeed/gspeed))*t*abs(vm)*h). 
    }
    return aoa.
    
}

function getSteering { // main steering function
    local errorVector is errorVector().
    local velVector is -ship:velocity:surface.
    local correctionVector to errorVector() * k.
    local result is velVector + correctionVector.
    local aoa is defAOA(). 
    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }
    return lookdirup(result, facing:topvector).
    
}

function vs {
    Declare parameter desiredAltitude.
Set integral to 0.
Set Kp to 0.4.
Set Ki to 0.1.
Set Kd to 0.2.
Set out to 0.
Set outMax to 1.
Set outMin to 0.
Set dt to 0.1.
Set count to 0.
Set previousError to desiredAltitude - alt:radar.
Until ship:verticalspeed >=-100{
    mechazilla().
	Set error to desiredAltitude - alt:radar.
	Set integral to integral + (error * dt).
	If (integral * Ki ) > outMax{
		Set integral to outMax / Ki.}.
	If (integral * Ki) < outMin{
		Set integral to outMin / Ki.}.
	Set derivative to (error - previousError) / dt.
	If (mod(count, 10) = 0){
		Print "Error Term:      " + (Kp * error).
		Print "Integral Term:   " + (Ki * integral).
		Print "Derivative Term: " + (Kd * derivative).
		Print "---------------".}.
	Set out to ((Kp * error) + (Ki * integral) + (Kd * derivative)).
	If (out > outMax){
		Set out to outMax.}.
	If (out < outMin){
		Set out to outMin.}.
	Lock throttle to out.
    Set previousError to error.
	Wait 0.1.
	Set count to count + 1.}}

function land{
    set toTargetVector to (landingsite:position - ship:position):normalized. // Vector pointing from the ship to the target
    set steeringStrength to 0.003.
    set steeringVector to ship:up:vector + steeringStrength * toTargetVector.
    set steeringVectorDir to steeringVector:direction.
    lock steering to R(steeringVectorDir:pitch, steeringVectorDir:yaw, -90).}

function vectorInclude {
parameter included.
parameter input.
return vectorExclude(vectorExclude(included, input), input).}

function excludeUp {
parameter input.
return vectorExclude(up:vector, input).}

function hv { 
    until ship:groundspeed <=2.5 {
        local lOS is landingsite:position - ship:position. //line of sight to target landing
        local velocityDelta is vectorInclude(excludeUp(lOS), ship:velocity:surface) - excludeUp(lOS):normalized*ln(excludeUp(lOS):mag/1000+1)*120. //non linear desired velocity to avoid tipping over at large distances
        local normalVelocity is excludeUP(vectorExclude(excludeUp(lOS), ship:facing:vector)).
        local gravity is (constant():g*body:mass)/(body:radius^2).
        set desSteer to lookdirup(up:vector * gravity - 0.2*velocityDelta - 0.2*normalVelocity ,ship:facing:topvector). //move towards desired location at velocityDelta speed, kill any normal Velocity.
        lock steering to desSteer.
        mechazilla().
        }
    lock steering to lookDirUp(up:forevector,ship:facing:topvector).
    mechazilla().
}

function mechazilla {

    SET MESSAGE TO "Connecting Mechazilla and booster".
    SET C TO VESSEL("Mechazilla"):CONNECTION.
    IF C:SENDMESSAGE(MESSAGE) {
        PRINT "Catching".
    }
    
}

toggle ag3.// toggle gridfins 30°
lock steering to getSteering().
wait until alt:radar <=1000.
land(). // Steer toward landingsite
vs(450). // Pid landing throttle
wait until ship:verticalspeed >=-100. 
toggle ag1. // Three engines
lock throttle to thr. // throttle to reach vi(line 5)
toggle ag2.
hv().
wait until alt:radar<=180.
lock vi to -15.
lock throttle to thr.
wait until ship:groundspeed <1.
toggle ag10.
wait until ship:verticalspeed>-5.
toggle ag8.
wait until ship:oxidizer and ship:liquidfuel <=0.// catched booster continue thrusting until fuel is empty.
