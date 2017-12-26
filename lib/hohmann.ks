// Computes a Hohmann transfer burn from a circular(ish) orbit around a planet
// to intercept one of its moons at the specified altitude.
// DOES NOT perform that burn.

// Works by computing the theoretical delta-V required to reach the moon's
// orbit, constructing a node for it, and sliding the node along until intercept
// is achieved.
// Then it fiddles with the timing and delta-V until the flyby altitude is as
// desired.

// Note that the plane of the orbit should already be aligned with the moon.

// Target moon, periapsis altitude for the flyby, and true/false for a
// "backhanded" orbit - that is one with the opposite direction of rotation.
// Backhanded transfers are indifferent for landings, but better for flyby
// returns, since they slingshot down, rather than up.
declare parameter moon, altitude, backhand.

runoncepath("stepsearch").

// Since our orbit might not be circular, I use our periapsis altitude as the
// basis. That overestimates delta-V, which means we'll still achieve intercept,
// but not necessarily efficiently. Then the hill-climbing part can optimize for
// altitude.

set r1 to ship:orbit:periapsis + ship:orbit:body:radius.
set r2 to moon:orbit:apoapsis + moon:orbit:body:radius.
print "Planning a Hohmann transfer from " + round(r1 / 1000) + "km to " + (r2 / 1000) + "km.".

set dv to sqrt(ship:orbit:body:mu / r1) * (sqrt(2 * r2 / (r1 + r2)) - 1).
print "Expected delta-V " + round(dv).

set nd to Node(time:seconds + 10, 0, 0, dv).
add nd.

until nd:orbit:hasnextpatch {
  set nd:eta to nd:eta + 5.
}

function moonOrbit {
  set destOrbit to nd:orbit.
  until destOrbit:body = moon {
    set destOrbit to destOrbit:nextpatch.
  }
  return destOrbit.
}

// Now we should have an intercepting orbit.
print "Intercept achieved, periapsis altitude " + round(moonOrbit():periapsis) + "km".


set getB to { return moonOrbit():periapsis. }.
set adjustA to { parameter newA. set nd:eta to newA - time:seconds. }.

set epoch to time:seconds.

// Now begin refining that orbit to achieve our target periapsis around the moon.
// Since the theoretical delta-V should be minimal(?) we binary-search the
// timing.
// stepsearch(MinA, StepA, TargetB, BTolerance, GetB, AAdjust).
// First, we target the center of the moon, then go either way.
stepsearch(nd:eta + epoch, 10, -moon:radius, 2000, getB, adjustA).
set deltaA to -1.
if backhand { set deltaA to 1. }
stepsearch(nd:eta + epoch, deltaA, altitude, 2000, getB, adjustA).

print "Transfer refined: periapsis altitude " + round(moonOrbit():periapsis) +
    ", inclination " + moonOrbit():inclination.

