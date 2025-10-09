//--Variables--\\

//--ALTS--\\
set alts to list(50000,25000,13500,6750,3375).

//--Target--\\
if hastarget { 
    set landingsite to latlng(target:geoposition:lat, target:geoposition:lng).
} else {
    set landingsite to latlng(28.478863,-80.528986).
}

////--Impact-Distance--\\
//if addons:tr:available and addons:tr:hasimpact
//{lock impactDist to addons:tr:impactpos:distance+100.}
//
//
////--Throttle--\\
//
//lock g to constant:g * body:mass / body:radius^2.					
//lock maxDecel to (ship:availablethrust / ship:mass) - g.			
//lock stopDist to ship:velocity:surface:sqrmagnitude / (2 * maxDecel).
//lock idealThrottle to stopDist / impactDist.


//--Functions--\

//--Error vector--\\
function errorVector {   
    return  landingsite:position - getImpact():position.
}

//--GetImpact--\\
function getImpact {
    if addons:tr:hasimpact { 
    return addons:tr:impactpos. 
    }
return ship:geoposition.
}

//--AoA--\\
function i {

    if alt:radar > alts[0] { return 0. }
    if alt:radar <= alts[alts:length - 1] { return 4. } 
    for idx in range(0, alts:length - 1) {
        if alt:radar <= alts[idx] and alt:radar > alts[idx+1] {
            return idx + 1.
        }
    }
}

function fdynaoax {
    local errorVector is getimpact():position - landingsite:position.
    local horizontalError is errorVector:mag.
    set f to list(-1,1).
    set maoa to list(40,20,15,10,5).
    lock rx to i().
    if alts[rx] <= alt:radar {
        if horizontalError < 100 {
            if throttle > 0 {
                set fx to f[0].
                print(1).
            } else {
                set fx to f[1].
                print(-1).
            }
        } else {
            set fx to f[0].
            print(1).
        }

        if rx <=3 {
            set maxaoa to maoa[rx]*fx.
        } else {
            set maxaoa to maoa[rx]*f[1].
        }
        set dynaoa to min(horizontalError, maxaoa).
        return dynaoa.
    }
}

//--Steering--\\

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

//----------------------------------------------------------------------------------LANDING-------------------------------------------------------------------------------\\

//--Main-Loop--\\

until false {
    lock steering to getsteering().
wait 0.1.
}

