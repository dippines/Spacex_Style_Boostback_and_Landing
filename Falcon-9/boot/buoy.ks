
// VERY VERY VERY WORK IN PROGRESS ITS JUST THE BEGINNING AND MAY NOT WORKS

// Put this in boot folder, and make the buoy run this at launch on the KAL9000

until ag10 {
set vs to vessel("boost"). // Your vessel name
    set rollpart to ship:partsnamed("rotoServo.02")[0].
    set rollmod to rollpart:getmodule("ModuleRoboticRotationServo").
    set pitpart to ship:partsnamed("hinge.01")[0].
    set pitmod to pitpart:getmodule("ModuleRoboticServoHinge").
    
    set distvec to vs:geoposition:position-ship:geoposition:position.
    set tow to ship:facing:starvector.

    set rdist to vs:position-ship:position.
    
    if vs:geoposition:lng-ship:geoposition:lng <0 {
        set pit to -1*vang(rdist,ship:up:vector). 
    } else {
        set pit to vang(rdist,ship:up:vector).
    }
    if vs:geoposition:lat-ship:geoposition:lat <0 {
        set roll to vang(tow,distvec).
    } else {
        set roll to -1*vang(tow,distvec).
    }

    // MODIF POUR FAIRE AVEC COS SIN

    lock steering to R(331.446,249.769,179.932).
    pitmod:setfield("angle cible", pit).  // My game is in french so i still need to test if it works on other languages
    rollmod:setfield("angle cible", roll).
}
