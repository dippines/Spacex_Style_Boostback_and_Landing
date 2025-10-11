// I'll detail each terms soon

// WORK IN PROGRESS IT'S NOT FINISHED


//------------------------Variables------------------------\\

//------------Lists------------\\
set alts to list(50000,25000,13500,5000,20).
set f to list(-1,1).
set maoa to list(3,4,5,3,2).

//------------Target------------\\
//set ls1 to latlng(28.6083884601472,-80.6497481659008).
//set LZ1 to latlng(28.478863,-80.528986).
if hastarget { 
    set landingsite to latlng(target:geoposition:lat, target:geoposition:lng).
} else {
    set landingsite to latlng(28.4971749954165,-80.5349879288904).
}


//------------------------Functions------------------------\\

//------------Throttle------------\\

function startalt {
    lock v1 to -ship:verticalspeed.
    lock Fr to ship:maxthrust.
    lock M to ship:mass.
    lock g to constant:g * body:mass / body:radius^2.		
    lock n to 0.7. 
    lock h to (v1^2)/(2*(n*(Fr/M)-g)).
    return h.
}

function throt {
    lock n2 to (0.5*v1+g*50)/((Fr/M)*h).
    return n2.
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
function tf {

    // to come
}
function i {
    if alt:radar > alts[0] {
        return 0.
    }
    if alt:radar <= alts[alts:length - 1] {
        return 4.
    } 
    for idx in range(0, alts:length - 1) {
        if alt:radar <= alts[idx] and alt:radar > alts[idx+1] {
            return idx + 1.
        }
    }
}

function fdynaoax {
    local errorVector is getimpact():position - landingsite:position.
    local H1 is errorVector:mag.
    lock rx to i().
    set tfx to 1.
    if alts[rx] <= alt:radar {
        if H1 < 50 {
            if throttle > 0 {
                set maoa[4] to vang(-ship:velocity:surface, ship:up:vector).
                set fx to tfx*2*f[0].
            }
        else {set fx to f[1].}
        } else {
            if throttle > 0 {
                set maoa[4] to vang(-ship:velocity:surface, ship:up:vector).
                set fx to tfx*f[1].
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
    local correctionVector to errorVector() * 1.
    local result is velVector + correctionVector.
    local aoa is fdynaoax(). 

    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }
    return lookdirup(result, facing:topvector).
}

//------------------------LANDING------------------------\\

wait until ship:verticalspeed <0.
lock steering to srfRetrograde.
Brakes on.
SAS OFF.
RCS ON.
lock steering to srfRetrograde.
wait until alt:radar <=80000.
RCS OFF.
lock steering to getsteering().
wait until alt:radar <=10000.
RCS on.
wait until alt:radar <= startalt().
lock throttle to 0.7-throt().
wait until false.
//------------------------LANDING------------------------\\

lock steering to srfRetrograde.
Brakes on.
SAS OFF.
RCS ON.
lock steering to srfRetrograde.
wait until alt:radar <=80000.
lock steering to getsteering().
wait until alt:radar <=10000.
wait until alt:radar <= startalt().
lock throttle to throt().
wait until false.


