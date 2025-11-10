clearscreen.

// PUT THIS IN BOOT FOLDER
// AND MAKE THE TOWER RUN THIS CODE AT LAUNCH



//--Ships--\\

set sh to "Heavy Booster".
// set s to "Starship".

//--Main--\\

until false {
  set v1 to vxcl(up:vector, vessel(sh):position).
  set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0]. 
  set MZ to Mechazilla:getmodule("ModuleSLEController"). 
  set v0 to -ship:prograde:starvector. 
  set ang to vang(v1,v0)-90. 
  set startalt to 1000. // Approximate vessel throttle start
  MZ:setfield("target angle",ang). // Where does the arms need to point
  set closang to vessel(sh):altitude*113.5/startalt.// Cross product to determine the angle that arms need to be opened (113.5 being the max when vessel at 1km)
  if closang <=30 { // If the vessel close
   ag1 on. // Close arms
  } else { 
    MZ:setfield("arms open angle",closang).
  }
wait 0.5.
}
