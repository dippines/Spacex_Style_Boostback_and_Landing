//----------------------------------------------------------------------------------BOOSTBACK SCRIPT-------------------------------------------------------------------------------\\


//--Variables--\\
set doneprev to false.
set donenext to false.
set chosetarget to false.
set meco to 60000. // Boostback start altitude.
set maxalt to 100000. //max alt you want the apoapsis of the boostback to go to : W.I.P.
set x to 0.// lngoff you want in real life this would be like -100
set y to 20. // beware because y act like a clamp, As superheavy is more uncontrollable than F9, don't put very low value unless you're certain about it (im certain about it 😎)
set cluster to ship:partsnamed("SEP.25.BOOSTER.CLUSTER")[0]:getmodule("ModuleSEPEngineSwitch").

//--------Functions--------\\

//--Target--\\

function targetland {
    until chosetarget = true {
        Print("Waiting for user to chose a landingsite.").
        set keyPress to terminal:input:getchar().
        if hastarget { 
            set landpos to latlng(target:geoposition:lat, target:geoposition:lng).
            set chosetarget to true.
        }
        if keyPress = "a" {
            set landpos to latlng(25.9962480647979,-97.1547020248853). // OLT-A
            set chosetarget to true.
        }   
        if keyPress = "b" {
            set landpos to latlng(25.9967515622019-0.001,-97.1579564069524-0.001). // OLT-B
            set chosetarget to true.
        }
        if keyPress = "c" {
            set landpos to latlng(28.6081649600038,-80.6012491850909). // OLT-C
            set chosetarget to true.
        }
        if keyPress = "w" {
            set landpos to latlng(25.9959261063009,-97.153023799664). // Water Test
            set chosetarget to true.
        }
        if keyPress = "o" {
            set landpos to latlng(25.8669450105354,-95.5781057662035). // Offshore platform
            set chosetarget to true.
        }
    wait 0.5.
    }
    return landpos.
}

set landingsite to targetland().
//--GetImpact--\\

function getImpact {
    if addons:tr:hasimpact { 
    return addons:tr:impactpos. 
    }
return ship:geoposition.
}

//--Error vector--\\

function errorVector {   
    return landingsite:position - getImpact():position.
}



//----------------------------------------------------------------------------------MAIN-------------------------------------------------------------------------------\\

lock steering to R(ship:facing:pitch,ship:facing:yaw,270).
//--MECO SEQUENCE--\\

when alt:radar >=meco-1000 then {
  SAS OFF.
  RCS on.
  cluster:doevent("next engine mode").
  stage.
  lock throttle to 0.25.
}

when alt:radar >=meco-500 then {
  cluster:doevent("next engine mode").
  stage. // Starship engines
  lock throttle to 0.
}

//--Activator--\\

wait until alt:radar >= meco.

//--More variables--\\
set t1 to landingsite:position - getImpact():position. // Landingsite - your impact pos, needed for my throttle ratio formula
set tin to abs(errorVector():mag/ship:velocity:surface:mag/2).
//--longitude and latitude offset in meters--\\

lock lngoff to (landingsite:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472. 
lock latoff to (landingsite:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472. 
toggle ag3. // Gridfins


if abs(ship:geoposition:lng) - abs(landingsite:lng) > 0 {
    set k to -1.
} else {
    set k to 1.
}
until vang(heading(k*landingsite:heading,0):vector,ship:facing:forevector) <= 10 {
    set ship:control:starboard to (ship:up:pitch - ship:facing:pitch)/abs((ship:up:pitch - ship:facing:pitch)).
    lock throttle to 0.1.
    lock steering to heading(k*landingsite:heading, 0).
}
until lngoff > x and abs(latoff) < y or AG10 {    

    if doneprev = false {
        cluster:doevent("previous engine mode").
        set doneprev to true.
    }
    
    lock bbt to errorVector():mag/t1:mag.
    set corr to VXCL(ship:sensors:grav,landingsite:position-ship:position). // straight vec from you to landingpos, on the same plan as errorvec.
    set tsvl to VXCL(ship:sensors:grav,(ship:direction:STARVECTOR)*latoff).

    //--Engines--\\

    if abs(lngoff) <=50 and donenext = false { 
        cluster:doevent("next engine mode").
        set donenext to true.    
    }

    //--Steering--\\
    
    if apoapsis>=maxalt {
        lock tilt to -(ship:apoapsis - maxalt) / 5000.
    } else {
        lock tilt to (ship:apoapsis - maxalt) / 5000.
    }

    set gain to abs(max(10, 20 - (abs(lngoff) / 2500))).
    
    set nv to corr + gain * tsvl.

    if abs(getimpact():lat) - abs(landingsite:lat) < 0 {
        set ang to 1*vang(corr, nv).
    } else {
        set ang to -1*vang(corr, nv).
    }

    set fdir to heading(k*landingsite:heading+ang, tilt).

    //--RCS AND FUEL CONTROL--\\

    if vang(heading(k*landingsite:heading+ang, tilt):vector,ship:facing:forevector) <= 10 {
    
        set lp2 to getimpact():lat-landingsite:lat. 
        set t to abs(errorVector():mag/ship:velocity:surface:mag).
        set fcalc to ((ship:liquidfuel-9000)/3886.20).
        set SHIP:CONTROL:STARBOARD to (lp2/abs(lp2)).

        if round(fcalc) <= abs(round(tin)-round(t)) {
            if ship:liquidfuel >=11000 {
                ag7 on.
            } else {
                ag8 on.
            }
        }
    }

    //--Main Control--\\

    lock steering to R(fdir:pitch,fdir:yaw,fdir:roll+180).
    lock throttle to abs(min(max(bbt,0.01),1)).
    print ("lng error : " + lngoff).
    print ("lat error : " + latoff).

wait 0.2.
}
lock throttle to 0.
unlock steering.
stage. // HSR
set ship:control:starboard to 0.
set ship:control:top to 0.
cluster:doevent("previous engine mode").

wait until ship:verticalspeed<=0.
set ship:control:top to -1.
set ship:control:starboard to (ship:up:pitch - ship:facing:pitch)/abs((ship:up:pitch - ship:facing:pitch)).      
wait 5.
set ship:control:starboard to 0.
set ship:control:top to 0.
lock steering to srfRetrograde.
wait until terminal:input:getchar() = "g".
print("Go for landing").
