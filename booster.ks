My boostback and landing are an edit of the one from edwin robert.
// Works in RSS, never tried in stock but is more likely to work.
Clearscreen.
SET spot TO LATLNG(latitude,longitude).
//JRTI : 28.5388641357422,-77.8600616455078
//LZ2 : 28.499088440369,-80.5358512374503
PRINT spot:LAT.
PRINT spot:LNG.
toggle ag2.
wait until alt:radar >=63000.
lock throttle to 0.5.
wait until alt:radar >=63000.
toggle ag1.
lock throttle to 0.2.
wait until alt:radar >=64000.
toggle ag1.
lock throttle to 0.1.
wait until alt:radar >=69500.

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



lock throttle to 0.1.
if ADDONS:TR:AVAILABLE {
    			if ADDONS:TR:HASIMPACT {
       			 PRINT ADDONS:TR:IMPACTPOS.
    			} else {
       			 PRINT "Impact position is not available".
   			 }
			} else {
   			 PRINT "Trajectories is not available.".
			}
SET runMode to 0.

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
RCS on.
SAS off.
SET landingpad TO latlng(spot:lat, spot:lng). //change to your landing pad latitude and longitude
SET targetDistOld TO 0.
SET landingpoint TO ADDONS:TR:IMPACTPOS.
set lngoff to (landingpad:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472.
set latoff to (landingpad:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472.
RCS on.

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
wait 7.
toggle ag5.
lock throttle to 1.
wait 2.
toggle ag8.
wait until ship:liquidfuel <= 20000.
toggle ag9.

when altitude > 4000 then {
		set lngoff to (landingpad:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472.
		set latoff to (landingpad:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472.
		wait 0.1.
		preserve.
		}

when lngoff > 500 then {
		lock throttle to 0.1.
		}
				
when lngoff > 10 then { 	
		lock throttle TO 0.
		unlock throttle.
        unlock steering.
        wait until ship:verticalspeed < -300.
        run land.
		}

When throttle > 0 then {
when latoff < -20 then {
lock steering to heading (landingpad:Heading - 2,0).
preserve.
}

when latoff > 20 then {
lock steering to heading (landingpad:heading + 2,0).
preserve.
}

}

wait until ship:verticalspeed < -5.
print "Boostback burn succesful". 
wait until ship:verticalspeed < 300.
print"Superheavy go for tower catch.".
run land.
