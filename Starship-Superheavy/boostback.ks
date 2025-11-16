// DEV PREVIEW : I put this here because it works and is <1 meter precise, but the whole fuel 
// calculs are not finished



//--Variables--\\
set done_ag1 to false.
set done_ag5 to false.
set meco to 70000. // Boostback start altitude.
set maxalt to 100000. //max alt you want the apoapsis of the boostback to go to : W.I.P.
lock landingsite to latlng(25.9959261063009 , -97.153023799664). // latlng coordinates of your desired landingsite
//--Functions--\\

//--GetImpact--\\

function getImpact {
    if addons:tr:hasimpact { 
    return addons:tr:impactpos. 
    }
return ship:geoposition.
}

//--Target--\\

if hastarget { 
    lock landingsite to latlng(target:geoposition:lat, target:geoposition:lng). // latlng in case you have a target set
}

//--Error vector--\\

function errorVector {   
    return  landingsite:position - getImpact():position.
}

//----------------------------------------------------------------------------------BOOSTBACK-------------------------------------------------------------------------------\\

//--MECO SEQUENCE--\\

when alt:radar >=meco-5000 then {
  toggle ag1.
  lock throttle to 1.
}

when alt:radar >=meco-2500 then {
  toggle ag1.
  lock throttle to 1.
}

when alt:radar >=meco-500 then {
  lock throttle to 0.1.
  stage.
}

//--Activator--\\

wait until alt:radar >= meco.

//--More variables--\\
set t1 to landingsite:position - getImpact():position. // Landingsite - your impact pos, needed for my throttle ratio formula
set x to 0. // lngoff you want in real life this would be like -100
set y to 20. // beware because y act like a clamp, As superheavy is more uncontrollable than F9, don't put very low value unless you're certain about it (im certain about it 😎)

//--longitude and latitude offset in meters--\\

lock lngoff to (landingsite:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472. 
lock latoff to (landingsite:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472. 
toggle ag3. // Gridfins
RCS on.
SAS OFF.

if abs(getImpact():lng) - abs(landingsite:lng) > 0 {
    set k to -1.
} else {
    set k to 1.
}


until vang(heading(k*landingsite:heading,0):vector,ship:facing:forevector) <= 10 {
    set ship:control:top to (ship:up:pitch - ship:facing:pitch)/abs((ship:up:pitch - ship:facing:pitch)).           
    set ship:control:starboard to -1.
    lock steering to heading(k*landingsite:heading, 0).
    lock throttle to 0.1.
}

until lngoff > x and abs(latoff) < y or AG10 {    
    if done_ag5 = false {
        toggle ag5.
        set done_ag5 to true.
    }
    //--Tilt--\\
    if apoapsis>=maxalt {
        lock tilt to -5.
    } else {
        lock tilt to 5.
    }
    lock pr to t1:mag/maxalt.

    //--Steering--\\

    set corr to VXCL(ship:sensors:grav,landingsite:position-ship:position). // straight vec from you to landingpos, on the same plan as errorvec.
    set tsvl to VXCL(ship:sensors:grav,(ship:direction:STARVECTOR)*latoff).

    if abs(lngoff) <=5000 {
        set nv to corr+10*tsvl.
    } else {
        set nv to corr+5*tsvl.
    }

    if abs(getimpact():lat) - abs(landingsite:lat) < 0 {
        set ang to 1*vang(corr, nv).
    } else {
        set ang to -1*vang(corr, nv).
    }

    lock steering to heading(k*landingsite:heading+ang, tilt).

    //--RCS--\\
    

    //--Fuel--\\

    //  when ship:liquidfuel >=10000 then {ag7 on.}
    //  when ship:liquidfuel <=10000 then {ag8 on.}


    //--RCS AND FUEL CONTROL--\\

    if vang(heading(k*landingsite:heading+ang, tilt):vector,ship:facing:forevector) <= 10 {
    set lp2 to getimpact():lat-landingsite:lat. 
    set t to abs(errorVector():mag/ship:velocity:surface:mag).
    set fcalc to ((ship:liquidfuel-10000)/3886.20).

        if lp2 = 0 {
            set SHIP:CONTROL:STARBOARD to 0.
        } else {
            set SHIP:CONTROL:STARBOARD to -(lp2/abs(lp2)).
        }

        print(round(T-fcalc)).
    
    }

    //--Throttle--\\

    if abs(lngoff) <=100 and done_ag1 = false { 
        toggle ag1.
        set done_ag1 to true.    
    }

    lock bbt to errorVector():mag/t1:mag.
    lock throttle to abs(min(max(bbt,0.01),1))*pr.
wait 0.1.
}
print ("Final lng error : " + lngoff).
print ("Final lat error : " + latoff).
set ship:control:starboard to 0.
toggle ag8.
lock throttle to 0.
