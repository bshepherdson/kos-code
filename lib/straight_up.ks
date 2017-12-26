// Flight profile:
// - Burn straight up to the parameter Ap.
// - Burn on re-entering the atmosphere, below TWR, to slow the fall, until we
//   run out of fuel.
// - Ride the engines and tanks all the way down for heat resistance.
// - Pop parachutes at a safe altitude/speed.
// Staging:
// - Chutes
// - Decoupler
// - Launch

declare parameter ap. // Target apoapsis for the lob shot.

runoncepath("twr").

wait 2.
lock steering to up + R(0, 0, -90).

lock tgt_throttle to throttle_twr(1.8).
lock throttle to tgt_throttle.

stage.

wait until ship:orbit:apoapsis > ap.
lock throttle to 0.
wait until ship:verticalspeed < 0.
lock steering to srfretrograde.
wait until ship:altitude < 70000.

lock tgt_throttle to throttle_twr(0.9).
lock throttle to tgt_throttle.

wait until altitude < 10000.
stage. // Drop tanks.
wait until airspeed < 250.
stage. // Pop chutes.
unlock throttle.
wait 3.
unlock steering.

print "Safe landings!".

