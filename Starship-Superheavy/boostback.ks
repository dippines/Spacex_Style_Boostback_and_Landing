//----------------------------------------------------------------------------------BOOSTBACK SCRIPT-------------------------------------------------------------------------------\\


//--Variables--\\

set doneprev to false.
set donenext to false.
set chosetarget to false.
set meco to 60000. // Boostback start altitude.
set x to 0.// lngoff you want
set cluster to ship:partsnamed("SEP.25.BOOSTER.CLUSTER")[0]:getmodule("ModuleSEPEngineSwitch").
set dt to 0.2.
set landingsite to targetland().

//--------Functions--------\\

//--Target--\\

function targetland {
    until chosetarget = true{
        Print("Waiting for user to chose a landingsite.").
        
        set keyPress to terminal:input:getchar().
        
        if keyPress = "t" { 
            set landpos to latlng(target:geoposition:lat, target:geoposition:lng).
            set chosetarget to true.
        }
        if keyPress = "a" {
            set landpos to latlng(25.9962480647979,-97.1547020248853). // OLT-A
            clearScreen.
            print("Go for boostback at OLT-A").
            set chosetarget to true.
        }   
        if keyPress = "b" {
            set landpos to latlng(25.9967515622019,-97.1579564069524). // OLT-B
            clearScreen.
            print("Go for boostback at OLT-B").
            set chosetarget to true.
        }
        if keyPress = "c" {
            set landpos to latlng(28.6081826102928,-80.601304446744). // OLT-C
            clearScreen.
            print("Go for boostback at OLT-C").
            set chosetarget to true.
        }
        if keyPress = "w" {
            set landpos to latlng(25.9962480647979,-96). // Water Test
            clearScreen.
            print("Catch aborted, Go for boostback for water landing").
            set chosetarget to true.
        }
        if keyPress = "o" {
            set landpos to latlng(25.8669450105354,-95.5781057662035). // Offshore platform
            clearScreen.
            print("Go for boostback at OFFSHORE PLATFORM").
            set chosetarget to true.
        }
    wait 0.5.
    }
    return landpos.
}

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

until vang(heading(k*landingsite:heading,0):vector,ship:facing:forevector) <= 20 {
    unlock steering.
    set ship:control:top to 1.
    set ship:control:starboard to (ship:up:pitch - ship:facing:pitch)/abs((ship:up:pitch - ship:facing:pitch)).
    lock throttle to 0.5.
    if doneprev = false and vang(heading(k*landingsite:heading,0):vector,ship:facing:forevector) <= 45 {
        cluster:doevent("previous engine mode").
        set doneprev to true.
    }
}

until lngoff > x or AG10 {

    lock bbt to errorVector():mag/t1:mag.
    set corr to VXCL(ship:sensors:grav,landingsite:position-ship:position). // straight vec from you to landingpos, on the same plan as errorvec.
    set tsvl to VXCL(ship:sensors:grav,(ship:direction:STARVECTOR)*latoff).

    //--Engines--\\

    if abs(lngoff) <=50 and donenext = false { 
        cluster:doevent("next engine mode").
        set donenext to true.    
        set dt to 0.05.
    }

    //--Steering--\\
    
    set nv to corr + 15* tsvl.

    if abs(getimpact():lat) - abs(landingsite:lat) < 0 {
        set ang to 1*vang(corr, nv).
    } else {
        set ang to -1*vang(corr, nv).
    }

    set fdir to heading(k*landingsite:heading+ang,0).

    //--RCS AND FUEL CONTROL--\\

    if vang(heading(k*landingsite:heading+ang, 0):vector,ship:facing:forevector) <= 10 {
        local lat_error is getimpact():lat-landingsite:lat. 
        local rcsthrust is (lat_error/abs(lat_error)).
        local str is round(cos(ship:facing:roll)).
        local tp is round(sin(ship:facing:roll)). 
        local t is abs(errorVector():mag/ship:velocity:surface:mag).
        local fcalc is ((ship:liquidfuel-9000)/3886.20).

        // Fuel drain
        if round(fcalc) <= abs(round(tin)-round(t)) {
            if ship:liquidfuel >=11000 {
                ag7 on.
            } else {
                ag8 on.
            }
        }
        // Rcs corrections
        if str = 1 or tp = -1{
            set ship:control:starboard to rcsthrust.
        } else {
            set ship:control:starboard to -rcsthrust.
        }
    }

    //--Main Control--\\
    lock steering to lookdirup(fdir:vector, ship:up:vector)*R(0,0,180).
    lock throttle to abs(min(max(bbt,0.01),1)).
    print("lngoff  " + lngoff ).
    print("latoff  "+ latoff ).
wait dt.
}

lock throttle to 0.
set ship:control:starboard to 0.
set ship:control:top to 0.

wait until ship:verticalspeed<=0.
until vang(srfRetrograde:vector,ship:facing:forevector) <= 25 {
    unlock steering.
    set ship:control:top to -0.5.
    set ship:control:starboard to (ship:up:yaw - ship:facing:yaw)/abs((ship:up:yaw - ship:facing:yaw)).
}
set ship:control:starboard to 0.
set ship:control:top to 0.
lock steering to srfRetrograde.
wait until alt:radar <=75000 or ABORT.
print("Go for landing").

stage. // HSR
