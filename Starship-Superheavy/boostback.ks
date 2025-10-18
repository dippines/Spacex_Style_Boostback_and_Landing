set distance to 150000.
function ld {
SET kuniverse:defaultloaddistance:flying:LOAD TO distance.   
SET kuniverse:defaultloaddistance:flying:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:flying:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:flying:PACK TO distance.   
SET kuniverse:defaultloaddistance:escaping:LOAD TO distance.   
SET kuniverse:defaultloaddistance:escaping:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:escaping:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:escaping:PACK TO distance.   
SET kuniverse:defaultloaddistance:SUBORBITAL:LOAD TO distance.   
SET kuniverse:defaultloaddistance:SUBORBITAL:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:SUBORBITAL:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:SUBORBITAL:PACK TO distance.   
SET kuniverse:defaultloaddistance:ORBIT:LOAD TO distance.   
SET kuniverse:defaultloaddistance:ORBIT:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:ORBIT:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:ORBIT:PACK TO distance.   
SET kuniverse:defaultloaddistance:prelaunch:LOAD TO distance.   
SET kuniverse:defaultloaddistance:prelaunch:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:prelaunch:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:prelaunch:PACK TO distance.   
SET kuniverse:defaultloaddistance:landed:LOAD TO distance.   
SET kuniverse:defaultloaddistance:landed:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:landed:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:landed:PACK TO distance.   
}
ld().
//--Variables--\\

//OLTC28.637138460196,-80.6050788442709
set meco to 72500. // Boostback start altitude.
set maxalt to 100000. //max alt you want the apoapsis of the boostback to go to : W.I.P.
set launchpos to latlng(28.6367249957965,-80.6050180698562). // launchsite position
lock landingsite to latlng(28.6367249957965,-80.6050180698562). // latlng coordinates of your desired landingsite

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

//----------------------------------------------------------------------------------BOOSTBACK CODE V1.2-------------------------------------------------------------------------------\\

//--MECO SEQUENCE--\\

when alt:radar >=65000 then {
  toggle ag1.
  lock throttle to 1.
}
when alt:radar >=67000 then {
  toggle ag1.
  lock throttle to 1.
}
when alt:radar >=69500 then {
  lock steering to srfprograde.
  lock throttle to 0.1.
}

//--Activator--\\

wait until alt:radar >= meco.

//--More variables--\\
set t1 to landingsite:position - getImpact():position. // Landingsite - your impact pos, needed for my throttle ratio formula
set x to 0. // lngoff you want
set y to 100. // beware because y act like a clamp, As superheavy is more uncontrollable than F9, don't put very low value unless you're certain about it

//--longitude and latitude offset in meters--\\

lock lngoff to (landingsite:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472. 
lock latoff to (landingsite:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472. 

until lngoff > x and abs(latoff) < y or AG10 {    
    
    lock corr to VXCL(ship:sensors:grav,landingsite:position-ship:position). // straight vec from you to landingpos, on the same plan as errorvec.
    lock ang to VANG(corr, errorVector()).// Angle between the latest vec and errorvec, you want this to be = 0

    //--Tilt--\\
    lock pr to t1:mag/maxalt.
        if apoapsis>=maxalt {
            lock tilt to -15.
        } else {
            lock tilt to 5.
        }
    //--Steering--\\
    if launchpos:lng - landingsite:lng < 0 {
        set k to -1.
    } else {
        set k to 1.
    }

    if getimpact():lng - landingsite:lng >0.001 and getimpact():lat - landingsite:lat >0.001 {
        lock steering to heading(k*landingsite:heading-ang, tilt).
        print("1").
    } else if getimpact():lng - landingsite:lng <-0.001 and getimpact():lat - landingsite:lat <-0.001 {
        lock steering to heading(k*landingsite:heading+ang, tilt).
        print("2").
    } else{
        lock steering to heading(k*landingsite:heading,tilt).
        print("3").
    }
    //--Fuel--\\
    if ag6 {
     when ship:liquidfuel >=10000 then {ag7 on.}
     when ship:liquidfuel <=10000 then {ag8 on.}}
    
    //--Throttle--\\
    lock bbt to errorVector():mag/t1:mag.
    lock throttle to abs(min(max(bbt,0.05),1))*pr.
wait 0.1.
}
