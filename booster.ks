Clearscreen.
SET spot TO LATLNG(latitude,longitude).

PRINT spot:LAT.
PRINT spot:LNG.

wait until alt:radar >=65000.

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
SET landingpad TO latlng(spot:lat, spot:lng). //change to your landing pad latitude and longtitude
SET targetDistOld TO 0.
SET landingpoint TO ADDONS:TR:IMPACTPOS.
set lngoff to (landingpad:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472.
set latoff to (landingpad:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472.
RCS on.
lock steering to heading ((landingpad:heading-180), 40).     //all this is used to get around the problem of kOS' slow and inefficient steering problem
wait 0.5.
lock steering to heading ((landingpad:heading-180), 50).
wait 0.5.
lock steering to heading ((landingpad:heading-180), 60).
wait 0.5.
lock steering to heading ((landingpad:heading-180), 70).
wait 0.5.
lock steering to heading ((landingpad:heading-180), 80).
wait 0.5.
lock steering to lookDirUp( up:forevector, ship:facing:topvector).
lock steering to heading (landingpad:heading, 80).
wait 0.5.
lock steering to heading (landingpad:heading, 70).
wait 0.5.
lock steering to heading (landingpad:heading, 60).
wait 0.5.
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
lock throttle to 0.2.

when altitude > 4000 then {
		set lngoff to (landingpad:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472.
		set latoff to (landingpad:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472.
		wait 0.1.
		preserve.
		}

when lngoff > 2000 then {
		
		lock throttle to 0.1.
		}
				
when lngoff > 37.1 then { 
		lock throttle TO 0.
		unlock throttle.
        unlock steering.
        wait until ship:verticalspeed < -300.
        run land.
		}

When throttle > 0 then {
when latoff < -1 then {
lock steering to heading (landingpad:Heading - 2,0).
preserve.
}

when latoff > 1 then {
lock steering to heading (landingpad:heading + 2,0).
preserve.
}

}

wait until ship:verticalspeed < -5.
print "Boostback burn succesful". 
wait until ship:verticalspeed < 300.
print"Superheavy go for tower catch.".
lock steering to srfRetrograde.
run land.