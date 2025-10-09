// THINGS TO DO & TO COME : 
- Automatic & precise throttle : 10/2025
- Final approach toward landingsite at the end in case it's not already on point : 11/2025
- Better aoa calculation depending on horizontalerror rather than an if else : 10/2025



// FOR ALL READERS : 
For now this code won't get you pinpoint but i'd say in a ~50m radius. The code works this way: It points retrograde, when at 50km, it will steer to the getsteering function,
what you need to know about this function is it either "go toward" or "brakes" depending on the value of the aoa, this value is set in the //--AoA--\\ part
The aoa depends on various factors : The altitude (i function) and the angle linked to it by their index (//--Lists--\\).
If the horizontalerror is "past" the impact position, it will brake (to visualise : it bring the trajectory toward the vessel(and so toward the landingsite))
and if it's not past it will "go toward" this is decided according to the H1 value and the f list (-1 = brake, 1 = go toward).
What you need to know if you want to change the maoa list: the more H1 is little, the more the values in that list should be little

//--Variables--\\

//--Lists--\\
set alts to list(50000,25000,13500,6750,3375).
set maoa to list(40,15,10,5,2).
set f to list(-1,1).

//--Target--\\
if hastarget { 
    set landingsite to latlng(target:geoposition:lat, target:geoposition:lng).
} else {
    set landingsite to latlng(28.478863,-80.528986).
}

//--Impact-Distance--\\
if addons:tr:available and addons:tr:hasimpact
{lock impactDist to addons:tr:impactpos:distance+100.}


//--Throttle--\\

lock g to constant:g * body:mass / body:radius^2.					
lock maxDecel to (ship:availablethrust / ship:mass) - g.			
lock stopDist to ship:velocity:surface:sqrmagnitude / (2 * maxDecel).
lock idealThrottle to stopDist / impactDist.


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
    local H1 is errorVector:mag.
    lock rx to i().
    if alts[rx] <= alt:radar {
        if H1 < 150 {
            if throttle > 0 {
                set fx to f[0].
            } else {
                set fx to f[1].
            }
        } else {
            set fx to f[0].
        }

        if rx <=3 {
            set maxaoa to maoa[rx]*fx.
        } else {
            set maxaoa to maoa[rx]*f[1].
        }
        set dynaoa to maxaoa.
        print(fx).
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

lock steering to srfRetrograde.
Brakes on.
SAS OFF.
RCS ON.
wait until alt:radar <=50000.
lock steering to getsteering().
wait until alt:radar <=5000.
wait until alt:radar <= stopDist+500.
lock throttle to idealThrottle.
wait until false.






