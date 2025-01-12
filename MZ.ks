clearscreen.
print "Waiting for Booster Signal acquisition".
Signal().
function Signal {
  until false {
    WHEN NOT SHIP:MESSAGES:EMPTY then {
      arms().
    }  
  }
}

function arms {
 until vessel("Heavy Booster"):altitude <=200 {
   angle().
 }
 ag1 on.
}

function angle {  // Target angle
  set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
  set MZANG to Mechazilla:getmodule("ModuleSLEController").
  lock v0 to -ship:prograde:starvector.
  lock v1 to vxcl(up:vector, vessel("Heavy Booster"):position).
  lock ang to vang(v1,v0)-90.
  lock mDist to (v1 - vxcl(up:vector, SHIP:geoposition:position)):mag.
  if mdist <20 {
    ag1 on.
  } else {
    print "mdist " + mdist.
  }
  print "target angle : " + ang.
  MZANG:setfield("target angle",ang).
}

//SET anArrow TO VECDRAW(V(0,0,0),V(a,b,c),RGB(1,0,0),"See the arrow?",1.0,TRUE,0.2,TRUE,TRUE).
