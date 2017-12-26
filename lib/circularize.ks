// Circularizes our orbit at the current apoapsis.

set n to NODE(time:seconds + eta:apoapsis, 0, 0, 1).
add n.

set ap to ship:orbit:apoapsis + 0.5.
until n:orbit:apoapsis > ap {
  set n:prograde to n:prograde + (ap - n:orbit:apoapsis) * 0.5.
}

