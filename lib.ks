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
    local sites is lexicon(
        "a", list(latlng(25.9962485183524, -97.154732239204), "OLT-A"),
        "b", list(latlng(25.9967515622019, -97.1579564069524), "OLT-B"),
        "c", list(latlng(28.6081826102928, -80.601304446744), "OLT-C"),
        "w", list(latlng(25.9962480647979, -96), "Water Test"),
        "3", list(latlng(34.63310839876, -120.615155971947), "LZ-3"),
        "2", list(latlng(28.4877484442497, -80.5449202044373), "LZ-2"),
        "1", list(latlng(28.4857625502468, -80.5429426267221), "LZ-1")
    ).

    clearscreen.
    print "Select Landing Site (t, a, b, c, w, o, 1, 2, 3):" AT (0,0).
    print "Corresponding letters :" AT (0,1).
    print "t : target" AT (0,2).
    print "a : OLT-A" AT (0,3).
    print "b : OLT-B" AT (0,4).
    print "o : ASOG" AT (0,5).
    print "w : water test" AT (0,6).
    print "1 : LZ-1" AT (0,7).
    print "2 : LZ-2" AT (0,8).
    print "3 : LZ-3" AT (0,9).

    until false {
        local choice is terminal:input:getchar().
        local selection is list().

        if choice = "t" and hastarget {
            set selection to list(target:geoposition, "Target: " + target:name).
        } else if choice = "o" {
            set selection to list(Vessel("ASOG"):geoposition, "ASOG").
        } else if sites:haskey(choice) {
            set selection to sites[choice].
        }

        if selection:length > 0 {
            clearscreen.
            print "Landingsite : " + selection[1] AT (0,0).
            addons:tr:settarget(selection[0]).
            return selection[0].
        }
    }
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
        local lngoff is getimpact():lat - pos:lng.
        local latoff is getimpact():lat - pos:lat.
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
    PRINT "Speed           : " + ROUND(SHIP:VELOCITY:SURFACE:MAG)*3.6 + " km/h   " AT (0,1).
    PRINT "Max Thrust      : " + ROUND(SHIP:MAXTHRUST, 2) + " kN      " AT (0,2).
    PRINT "Mass            : " + ROUND(SHIP:MASS, 3) + " t       " AT (0,3).
    print "Error vector    : " + ROUND(errorVector(pos):mag) + " m       " AT (0,4).
    print "AoA             : " + vang(ship:facing:vector,ship:velocity:surface) + " °   " AT (0,5).
    print "Burn alt        : " + (ship:velocity:surface:mag^2)/(2*((ship:maxThrust/ship:mass)-ship:sensors:grav:mag)) + " m " AT (0,6).
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
    local aoa is aoa(). 

    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }

    return lookdirup(result, facing:topvector).
}
