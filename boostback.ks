
function ld {// load distances( visible tower and ship from 500km, camera feed etc)
SET kuniverse:defaultloaddistance:flying:LOAD TO 500000.   
SET kuniverse:defaultloaddistance:flying:UNLOAD TO 500000. 
SET kuniverse:defaultloaddistance:flying:UNPACK TO 500000. 
SET kuniverse:defaultloaddistance:flying:PACK TO 500000.   
SET kuniverse:defaultloaddistance:escaping:LOAD TO 500000.   
SET kuniverse:defaultloaddistance:escaping:UNLOAD TO 500000. 
SET kuniverse:defaultloaddistance:escaping:UNPACK TO 500000. 
SET kuniverse:defaultloaddistance:escaping:PACK TO 500000.   
SET kuniverse:defaultloaddistance:SUBORBITAL:LOAD TO 500000.   
SET kuniverse:defaultloaddistance:SUBORBITAL:UNLOAD TO 500000. 
SET kuniverse:defaultloaddistance:SUBORBITAL:UNPACK TO 500000. 
SET kuniverse:defaultloaddistance:SUBORBITAL:PACK TO 500000.   
SET kuniverse:defaultloaddistance:ORBIT:LOAD TO 500000.   
SET kuniverse:defaultloaddistance:ORBIT:UNLOAD TO 500000. 
SET kuniverse:defaultloaddistance:ORBIT:UNPACK TO 500000. 
SET kuniverse:defaultloaddistance:ORBIT:PACK TO 500000.   
SET kuniverse:defaultloaddistance:prelaunch:LOAD TO 500000.   
SET kuniverse:defaultloaddistance:prelaunch:UNLOAD TO 500000. 
SET kuniverse:defaultloaddistance:prelaunch:UNPACK TO 500000. 
SET kuniverse:defaultloaddistance:prelaunch:PACK TO 500000.   
SET kuniverse:defaultloaddistance:landed:LOAD TO 500000.   
SET kuniverse:defaultloaddistance:landed:UNLOAD TO 500000. 
SET kuniverse:defaultloaddistance:landed:UNPACK TO 500000. 
SET kuniverse:defaultloaddistance:landed:PACK TO 500000.   
}
ld().
Clearscreen.

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
  lock throttle to 0.5.
}
wait until alt:radar>=70000.
stage.
wait until ship:apoapsis.

RCS on.
if ADDONS:TR:AVAILABLE {
    			if ADDONS:TR:HASIMPACT {
       			 PRINT ADDONS:TR:IMPACTPOS.
    			} else {
       			 PRINT "Impact position is not available".
   			 }
			} else {
   			 PRINT "Trajectories is not available.".
			}

when throttle = 0 then { 
      set STEERINGMANAGER:MAXSTOPPINGTIME to 15.
      set STEERINGMANAGER:PITCHPID:KD to 2.
      set STEERINGMANAGER:YAWPID:KD to 2.
preserve.	
} 
when throttle > 0 then {
      set STEERINGMANAGER:MAXSTOPPINGTIME to 15.
      set STEERINGMANAGER:PITCHPID:KD to 1.
      set STEERINGMANAGER:YAWPID:KD to 1.
	  
preserve.
}


RCS ON.
SAS off.
if hastarget {set landingpad to latlng(target:geoposition:lat, target:geoposition:lng).}     
    else {set landingpad to latlng(28.6370253021226,-80.6014334665529). }
set lngoff to (landingpad:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472. // longitude offset in meter 
set latoff to (landingpad:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472. // latitude offset in meter
lock steering to heading ((landingpad:heading-180), 40).     //all this is used to get around the problem of kOS' slow and inefficient steering problem
wait 0.5.
lock throttle to  0.1.
lock steering to heading ((landingpad:heading-180), 50). 
wait 0.5.
lock steering to heading ((landingpad:heading-180), 60).
wait 0.5.
lock steering to heading ((landingpad:heading-180), 70).
wait 0.5.
lock steering to heading ((landingpad:heading-180), 80).
wait 0.5.
lock throttle to 0.2.
lock steering to lookDirUp( up:forevector, ship:facing:topvector).
lock steering to heading (landingpad:heading, 80).
wait 0.5.
lock steering to heading (landingpad:heading, 70).
wait 0.5.
lock steering to heading (landingpad:heading, 60).
wait 0.5.
lock throttle to 0.3.
lock steering to heading (landingpad:heading, 50).
wait 0.5.
lock steering to heading (landingpad:heading, 40).
wait 0.5.
lock steering to heading (landingpad:heading, 30).
wait 0.5.
lock steering to heading (landingpad:heading, 20).
wait 0.5.
lock steering to heading (landingpad:heading, 10).
wait 0.5.
lock steering to heading (landingpad:heading, 0).
RCS on.
wait 10.
toggle ag5. // switch to 13 engines
lock throttle to 1. 
wait 10. // wait for the booster to have rotated change it to your needs

when ship:liquidfuel >=10000 then {toggle ag8.}
when ship:liquidfuel <=10000 then {toggle ag9.}

when lngoff >-1000 then {
toggle ag1.
lock throttle to 0.4.
}

when lngoff >-500 then {
lock throttle to 0.1.
}

when lngoff >-5000 then {
	lock throttle to 0.5.}.

when altitude > 4000 then {
		set lngoff to (landingpad:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472. 
		set latoff to (landingpad:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472.
		print "lngoff: " + lngoff.
		print "latoff: " + latoff.
		wait 0.1.
		preserve.
		}

				
when lngoff >= -1.5 then {
		lock throttle to 0.
		toggle ag5.
		toggle ag10. //purge stop
        unlock steering.
        wait until ship:verticalspeed < -300.
        run land.
		}

When throttle > 0 then { 

when latoff < -20 then {
lock steering to heading (landingpad:Heading - 2,-0.05).
preserve.
}

when latoff > 20 then {

lock steering to heading (landingpad:heading + 2, -0.05). // Slightly negative to kill vertical velocity like a near-nul retrograde
preserve.
}
}

wait until lngoff >=-1.5.
run land.
