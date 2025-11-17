// Put this in boot folder, and make the tower run this at launch


//--Ships--\\

set sh to Vessel("Heavy Booster").
// set s to "Starship".
set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
set MZ to Mechazilla:getmodule("ModuleSLEController").

//--Main--\\

until false {
  set v1 to VXCL(sh:geoposition:position-Mechazilla:position,ship:up:vector):normalized.
  set v0 to Mechazilla:facing:starvector. 
  
  if round(sh:geoposition:lat-ship:geoposition:lat) > 0 {
    set ang to max(-vang(v1,v0)+8,-56.8).
  } else if round(sh:geoposition:lat-ship:geoposition:lat) < 0{
    set ang to min(vang(v1,v0)+8,56.8).
  } else {
    set ang to 8.
  }

  if sh:altitude <=160{ // If the vessel close
    ag1 on.
    wait until sh:altitude <=150.
    break. // Close arms
  }
  
  
  MZ:setfield("target angle",ang). // Where does the arms need to point
 wait 0.15.
}
