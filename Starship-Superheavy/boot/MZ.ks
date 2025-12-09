// Put this in boot folder, and make the tower run this at launch on a KAL9000

//--Variables--\\

set offset to ship:bounds:bottomaltradar.
set sh to Vessel("Heavy Booster").
// set s to "Starship".
set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
set MZ to Mechazilla:getmodule("ModuleSLEController").
set angleoffset to 8.
set geolat to ship:geoposition:lat.
set geolng to ship:geoposition:lng.
set northVector TO SHIP:NORTH:VECTOR.
set upVector TO SHIP:UP:VECTOR.
set eastVector TO VCRS(upVector, northVector).
set shipvec TO VXCL(ship:facing:forevector,ship:facing:starvector).
set northComponent TO -ROUND(VDOT(shipvec, northVector)).
set eastComponent TO ROUND(VDOT(shipvec, eastVector)).

//--Main--\\

until false {
  local v1 is VXCL(sh:geoposition:position-Mechazilla:position,ship:up:vector):normalized.
  local v0 is ship:facing:starvector.

  local dlat is sh:geoposition:lat-geolat.
  local dlng is sh:geoposition:lng-geolng.

  local orientdelta is round(eastComponent*dlat + northComponent*dlng,5). // 5 ==> meter precision, 4 ==> 10m precision

  if orientdelta > 0  {
    set ang to max(-vang(v1,v0)+angleoffset,-56.8).
  } else if orientdelta < 0 {
    set ang to min(vang(v1,v0),56.8).
  } else {
    set ang to angleoffset.
  }
  if sh:altitude <=160 + offset { // If the vessel close
    MZ:doevent("close arms").
    wait until sh:velocity:surface:mag <= 5.
    toggle ag2.
    break.
  }
  MZ:setfield("target angle",ang). // Where does the arms need to point
 wait 0.15.
}
