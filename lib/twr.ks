// Helpers for working with TWR.

// Returns acceleration due to gravity.
function gravity {
  local mu is ship:orbit:body:mu.
  local r is ship:altitude + ship:orbit:body:radius.
  return mu / (r * r).
}


// Computes the TWR of the active Vessel.
declare function twr {
  local accel is ship:availablethrust / ship:mass.
  return accel / gravity().
}

// Returns the throttle setting that achieves the requested TWR.
// Since not all engines respond to throttling, we split the liquid fuel and
// solid fuel engines and compute their contributions separately.
declare function throttle_twr {
  parameter target_twr.

  local max_twr is twr().
  if max_twr = 0 {
    return 0. // Guards against division by 0.
  }


  local needed_thrust is ship:mass * target_twr * gravity().
  local fixed_thrust is 0.
  local throttled_thrust is 0.
  list engines in es.
  for e in es {
    if e:ignition and not e:flameout {
      if e:throttlelock {
        set fixed_thrust to fixed_thrust + e:availablethrust.
      } else {
        set throttled_thrust to throttled_thrust + e:availablethrust.
      }
    }
  }

  if throttled_thrust = 0 {
    return 0. // Avoids division by zero.
  }

  // Throttle setting is the demand (the amount of thrust needed from the
  // throttled engines) divided by the supply (the maximum thrust they can
  // deliver). Capped to [0,1].
  return max(0, min(1, (needed_thrust - fixed_thrust) / throttled_thrust)).
}
