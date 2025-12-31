//----------------------------------------------------------------------------LIBRARY----------------------------------------------------------------------------\\
clearscreen.
//------Maths------\\

function clamp {
    parameter val, min_val, max_val.
    return min(max(val, min_val), max_val).
}

function sign {
    parameter val.
    if val = 0 return 1.
    return val / abs(val).
}

//------Target------\\

function targetland {
    local target_chosen is false.
    local selected_pos is geoposition.
    
    until target_chosen {
        clearscreen.
        print "Select Landing Site (t, a, b, c, w, o):".
        local char is terminal:input:getchar().
        
        if char = "t" and hastarget {
            set selected_pos to latlng(target:geoposition:lat, target:geoposition:lng).
            set target_chosen to true.
        } else if char = "a" {
            set selected_pos to latlng(25.9962485183524, -97.154732239204).
            set target_chosen to true.
        } else if char = "b" {
            set selected_pos to latlng(25.9967515622019, -97.1579564069524).
            set target_chosen to true.
        } else if char = "c" {
            set selected_pos to latlng(28.6081826102928, -80.601304446744).
            set target_chosen to true.
        } else if char = "w" {
            set selected_pos to latlng(25.9962480647979, -96).
            set target_chosen to true.
        } else if char = "o" {
            set selected_pos to latlng(25.8669450105354, -95.5781057662035).
            set target_chosen to true.
        }
    }
    return selected_pos.
}

//------Steering------\\

function getImpact {
    if addons:tr:hasimpact { 
    return addons:tr:impactpos. 
    }
return ship:geoposition.
}

function errorVector {   
    parameter pos.
    return pos:position - getImpact():position.
}


function rcscorrections {
    parameter activation, pos.
    if alt:radar <= activation {
        local ro is ship:facing:roll.
        local lngoff is ship:geoposition:lng - pos:lng.
        local latoff is ship:geoposition:lat - pos:lat.
        local top_cmd is (-latoff * COS(ro)) - (lngoff * SIN(ro)).
        local starboard_cmd is (-latoff * SIN(ro)) + (lngoff * COS(ro)).

        if top_cmd > 0 {
            set SHIP:CONTROL:TOP to 1.
        } else if top_cmd < 0 {
            set SHIP:CONTROL:TOP to -1.
        } else {
            set SHIP:CONTROL:TOP to 0.
        }

        if starboard_cmd > 0 {
            set SHIP:CONTROL:STARBOARD to 1.
        } else if starboard_cmd < 0 {
            set SHIP:CONTROL:STARBOARD to -1.
        } else {
            set SHIP:CONTROL:STARBOARD to 0.
        }
    }
}

//------Misc------\\


function debug {
    parameter pos.
    PRINT "Vitesse Surface : " + ROUND(SHIP:VELOCITY:SURFACE:MAG, 1) + " m/s   " AT (0,0).
    PRINT "Gravite         : " + ROUND(SHIP:SENSORS:GRAV:MAG, 3) + " m/s^2 " AT (0,1).
    PRINT "Poussee Max     : " + ROUND(SHIP:MAXTHRUST, 2) + " kN      " AT (0,2).
    PRINT "Masse           : " + ROUND(SHIP:MASS, 3) + " t       " AT (0,3).
    print "Error vector             : " + ROUND(pos:position-ship:geoposition:position):mag + " m       " AT (0,4).
    print "G force         : " + SHIP:SENSORS:ACC:MAG / CONSTANT:g0 + " m/s^2    " AT (0,6).
}    

function debugvisual {}



function globallanding {
    // A function that make your vessel lands (no steering control).
    // It start at activationalt and will land you either at 'offset' ground level (if offset 120, you will have 0 velocity at 120 meter)
    // Condition block 1 is a block that you can add or delete and that will do something under a certain circonstance (next engine, gears etc), as it is in a loop, bools need to be false prior to the start of the function.
    // F.Y.I. : You can add a counter to the condition block to do some action a certain amount of time just be aware of kOS tick rate
    
    parameter activationalt.
    parameter offset is 0.
    set bool1 to false.
    wait until alt:radar <= activationalt.
        until ship:verticalspeed >=0 {

            // Condition Block 1
            
            if bool1 = false and ship:verticalspeed >= -100 { // Exemple with ship:verticalspeed >= -100 as a condition
                // The actions you want the vessel to do once
                toggle ag1.
                toggle gear.
                // action is finished and will happen only once
                set bool1 to true.
            }


        lock throttle to min(max(((ship:velocity:surface:mag^2)/(2*ship:sensors:grav:mag*(ship:bounds:bottomaltradar-offset))),0),1).
    }

}

function globalsteering {
    // Steering function made by Edwin Roberts on github
    parameter pos. // Your landingsite
    local velVector is -ship:velocity:surface.
    local correctionVector to errorVector(pos).
    local result is velVector + correctionVector.
    local aoa is aoax(). 

    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }

    return lookdirup(result, facing:topvector).
}
