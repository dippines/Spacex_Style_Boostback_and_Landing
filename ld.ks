set distance to 500000.
function ld {
SET kuniverse:defaultloaddistance:flying:LOAD TO distance.   
SET kuniverse:defaultloaddistance:flying:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:flying:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:flying:PACK TO distance.   
SET kuniverse:defaultloaddistance:escaping:LOAD TO distance.   
SET kuniverse:defaultloaddistance:escaping:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:escaping:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:escaping:PACK TO distance.   
SET kuniverse:defaultloaddistance:SUBORBITAL:LOAD TO distance.   
SET kuniverse:defaultloaddistance:SUBORBITAL:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:SUBORBITAL:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:SUBORBITAL:PACK TO distance.   
SET kuniverse:defaultloaddistance:ORBIT:LOAD TO distance.   
SET kuniverse:defaultloaddistance:ORBIT:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:ORBIT:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:ORBIT:PACK TO distance.   
SET kuniverse:defaultloaddistance:prelaunch:LOAD TO distance.   
SET kuniverse:defaultloaddistance:prelaunch:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:prelaunch:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:prelaunch:PACK TO distance.   
SET kuniverse:defaultloaddistance:landed:LOAD TO distance.   
SET kuniverse:defaultloaddistance:landed:UNLOAD TO distance. 
SET kuniverse:defaultloaddistance:landed:UNPACK TO distance. 
SET kuniverse:defaultloaddistance:landed:PACK TO distance.   
}
ld().

// Load distance add-on, it can burn to hell and summon the kraken so use with precaution, 
//don't push too far the limit 500km works good for me, if you want to run a starship orbit code while a superheavy + mechazilla landing one,
//you want the distance to be the minimal distance between the pad and starship, else kOS couldn't control starship.
// Idk if you must do it but I run it on every kOS computer like mechazilla, booster and starship. 
