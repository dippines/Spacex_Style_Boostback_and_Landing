// Put this in boot folder, and make the tower run this at launch


//--Variables--\\
set offset to ship:altitude.
set sh to Vessel("Heavy Booster").
// set s to "Starship".
set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
set MZ to Mechazilla:getmodule("ModuleSLEController").

//--Main--\\

until false {
  set v1 to VXCL(sh:geoposition:position-Mechazilla:position,ship:up:vector):normalized.
  set vcomp to Mechazilla:facing:starvector.
  set v0 to ship:direction:starvector:normalized. 

  if vdot(v1, v0) > 0 {
    set ang to max(-vang(v1,v0)+8,-56.8).
  } else if vdot(v1, v0) < 0 {
    set ang to min(vang(v1,vcomp)+8,56.8).
  } else {
    set ang to 8.
  }

  if sh:altitude <=140 + offset { // If the vessel close
    MZ:doevent("close arms").
    wait until sh:velocity:surface:mag <= 5.
    break.
  }
  
  MZ:setfield("target angle",ang). // Where does the arms need to point
 wait 0.01.
}
//--Variables--\\

set offset to ship:altitude.

set sh to Vessel("Heavy Booster").

// set s to "Starship".

set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].

set MZ to Mechazilla:getmodule("ModuleSLEController").



//--Main--\\
until false {
  set v1 to VXCL(sh:geoposition:position-Mechazilla:position,ship:up:vector):normalized.
  set v0 to Mechazilla:facing:starvector.
  if round(sh:geoposition:lat-ship:geoposition:lat,5) > 0 {
    set ang to max(-vang(v1,v0)+8,-56.8).
  } else if round(sh:geoposition:lat-ship:geoposition:lat,5) < 0 {
    set ang to min(vang(v1,v0)+8,56.8).
  } else {
    set ang to 8.
  }

  if sh:altitude <=160 + offset { // If the vessel close
    MZ:doevent("close arms").
    wait until sh:velocity:surface:mag <= 5.
    break.
  }
  MZ:setfield("target angle",ang). // Where does the arms need to point
 wait 0.15.
}
