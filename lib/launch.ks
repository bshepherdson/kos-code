// Master launch script for a vertically launched rocket.
// Handles a gravity turn, staging, and raises Ap to a requested level.
// Will not achieve orbit on its own; follow it with the orbit script for that.

parameter ap, target_twr.

runoncepath("twr").

set turn_speed to 100. // Start the turn when 100m/s is achieved.
set target_ap_time to 45. // 45 seconds to Ap as a guide for the gravity turn.

print "Heading for " + ap + "m with TWR of " + target_twr.

// Getting started: lock steering to up, throttle to 1, SAS off.
lock steering to HEADING(90, 90) + R(0, 0, -90).
lock throttle to 1.
SAS off.

stage.

// We're underway. Wait for the requested speed to be achieved.
// Start the master staging trigger now, just in case.
on ship:maxthrust {
  list engines in es.
  for e in es {
    if e:flameout {
      stage.
      return true.
    }
  }
  return true.
}

wait until ship:airspeed >= turn_speed.
print "Starting gravity turn.".
lock steering to HEADING(90, 80) + R(0, 0, -90).
lock throttle to throttle_twr(target_twr).

list engines in es.
set total_thrust to 0.
for e in es {
  if e:ignition {
    set total_thrust to total_thrust + e:availablethrust.
  }
}

print "ship:availablethrust = " + ship:availablethrust + ", calculated = " + total_thrust.

wait until vang(srfprograde:forevector, ship:up:forevector) > 10.
lock steering to srfprograde + R(0, 0, -90).

// We let it drift down until our time-to-apoapsis exceeds the target.
wait until eta:apoapsis >= target_ap_time.
set tgt_pitch to 90 - vang(ship:up:forevector, srfprograde:forevector). // Current pitch.
lock steering to HEADING(90, tgt_pitch) + R(0, 0, -90).

// PID for driving the pitch based on the apoapsis ETA.
// Tuning Kp to give a downward pitch change of ~5 degrees for each 10 seconds
// off. Limiting the deltas at +-3 to keep from over-steering.
set max_aoa to 8.
set pid to pidloop(0.5, 0, 0, -max_aoa, max_aoa).
set pid:setpoint to target_ap_time.

until apoapsis >= ap {
  set calc_pitch to 90 - vang(ship:up:forevector, srfprograde:forevector).
  set delta_pitch to pid:update(time:seconds, eta:apoapsis).
  set tgt_pitch to max(2, calc_pitch + delta_pitch).
  wait 0.2.
}

lock throttle to 0.
lock steering to srfprograde + R(0, 0, -90).
print "Coasting to space.".
wait until ship:altitude > 70000.
print "Launch complete!".
unlock throttle.
unlock steering.


