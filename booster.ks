My boostback and landing are an edit of the one from edwin robert.
// Works in RSS, never tried in stock but is more likely to work.
Clearscreen.
SET spot TO LATLNG(latitude,longitude). // get launching site coordinates, only if launching/landing site is the same this is basically to don't have to enter manually  the coordinates and to launch from any launchpads

PRINT spot:LAT.
PRINT spot:LNG. 

// Launch 

wait until alt:radar >=65000. // This is the altitude where you stage, feel free to change.

if ADDONS:TR:AVAILABLE {
    			if ADDONS:TR:HASIMPACT {
       			 PRINT ADDONS:TR:IMPACTPOS.
    			} else {
       			 PRINT "Impact position is not available".			// Check from the TRAJECTORIES MOD
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
SET landingpad TO latlng(spot:lat, spot:lng). // the spot from the launch is used here, you can change spot:lat and spot:lng by their correspondng coordinates.
SET targetDistOld TO 0.
SET landingpoint TO ADDONS:TR:IMPACTPOS.
set lngoff to (landingpad:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472.	// Converts degree in meters
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
				
when lngoff > 37.1 then { 				// This is the lngoff that works for me, it will probably not be that for you, try first with big and low numbers 0/500 and try smallest numbers after that. This part is much more launching and correcting your code and retry.
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
lock steering to srfRetrograde. // feel free to change.
run land. // run the landing program.
