// Flight profile:
// - Burn straight up to the parameter Ap.
// - Wait for impact.
// Staging:
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

print "Done.".

