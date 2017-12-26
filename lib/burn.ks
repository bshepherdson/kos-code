// Executes the next manuever node in the flight plan.
// Burn time calculations can handle staging once during the burn, but not
// twice.

// WARNING: These calculations can't handle asparagus staging - if any engines
// currently firing continue to the next stage, it will get confused.


// Returns the amount of usable liquid fuel in the given stage.
// Actually returns the amount of liquid fuel for which there is oxidizer.
function lf_in_stage {
  list parts in ps.
  local lf is 0.
  local lox is 0.
  for p in ps {
    if p:stage >= (stage:number - 1) { // HACK: Fuel tanks are assigned one lower.
      for r in p:resources {
        if r:name = "LiquidFuel" {
          set lf to lf + r:amount.
        } else if r:name = "Oxidizer" {
          set lox to lox + r:amount.
        }
      }
    }
  }

  // Reduce the "usable" LF if there isn't enough oxidizer.
  // 9 parts LF to 11 parts LOX. Both are 5kg/unit.
  if lox < (lf * 11 / 9) {
    set lf to lox * 9 / 11.
  }
  return lf.
}


function mass_search {
  parameter num, part, seen.
  if seen:contains(part) or (part:hasmodule("ModuleDecouple") and
      part:stage >= num) {
    return 0.
  }
  seen:add(part).
  local m is part:mass.
  for c in part:children {
    set m to m + mass_search(num, c, seen).
  }
  return m.
}

function mass_at_stage {
  parameter num.
  return mass_search(num, ship:rootpart, uniqueset()).
}

function active_engines {
  list engines in es.
  local ret is list().
  for e in es {
    if e:ignition {
      ret:add(e).
    }
  }
  return ret.
}


// TODO: Handle different engines with different Isps.
function dv_of_stage {
  local fuel is lf_in_stage().
  local engines is active_engines().
  local total_mass is ship:mass.     // tonnes
  print "Total mass: " + total_mass.
  local wet_mass is fuel * 20 * 5 / 9.   // kg. Extra 5 is from fuel density.
  print "Reaction mass: " + wet_mass.

  local isp is engines[0]:isp.
  print "ISP: " + isp + "s".
  local g0 is kerbin:mu / (kerbin:radius ^ 2).
  print "g0: " + g0.
  local dv is g0 * isp * ln(total_mass / (total_mass - (wet_mass/1000))).
  print "Delta-V: " + dv.
  return dv.
}


// Time for this stage to burn this much delta-V, which might not be the stage's
// limit, but must not be more than the stage could deliver.
function burn_time_of_current_stage {
  parameter dv.

  local fuel is lf_in_stage().
  local engines is active_engines().
  local g0 is kerbin:mu / (kerbin:radius ^ 2).
  local m0 is ship:mass.
  local m1 is m0 / (constant:e ^ (dv / (g0 * engines[0]:isp))).

  local dm is m0 - m1. // Mass drops by this much.
  local flow is 0.
  for e in engines {
    set flow to flow + (e:availablethrust / (g0 * e:isp)).
  }
  return dm / flow.
}


// Computes an accurate burn time by determining the reaction mass in the bottom
// stage and solving the rocket equation to get its delta-V.
// If the burn needs more delta-V than this stage can deliver, we use a cruder
// estimate of the next stage's acceleration to find the burn time.

// Some notes on how that works:
// dv = g0 * Isp * ln(m0/m1)
// (where g0 is g on Kerbin/Earth, converting fuel weight to mass).
// Solving for m1 yields: m1 = m0 / exp(dv / (g0 * Isp)).

// What we want is to determine how much delta-V is in each stage, and how long
// it will take to burn.
// TODO: Handle engines with different Isp firing together.
// TODO: Handle more than 1 staging event during a burn.
function burn_time {
  parameter dv0.
  local total_time is 0.
  local dv is dv0.

  local sdv is dv_of_stage().
  local bt is burn_time_of_current_stage(dv0).
  if dv0 <= sdv {
    return bt.
  }

  // If we're still here, we need the next stage.
  list engines in es.
  local thrust is 0.
  for e in es {
    if e:stage = stage:number - 1 {
      set thrust to thrust + e:availablethrust.
    }
  }

  local mass is mass_at_stage(stage:number - 1).
  local accel is thrust / mass.
  local secondary_time is (dv0 - sdv) / accel.
  return bt + secondary_time.
}


set nd to nextnode.
print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).

set burn_duration to burn_time(nd:deltav:mag).
print "Burn duration estimate: " + round(burn_duration).

set burn_start_time to time:seconds + nd:eta - (burn_duration / 2).
if (burn_start_time - time:seconds) > 90 {
  print "Warping to burn start.".
  kuniverse:timewarp:warpto(burn_start_time - 60).
}

print "Preparing for burn.".
set np to nd:deltav.
lock steering to np.

wait until vang(np, ship:facing:vector) < 0.3.
wait until nd:eta <= (burn_duration / 2).

set tset to 0.
lock throttle to tset.
set dv0 to nd:deltav.

until false {
  set max_acc to ship:maxthrust / ship:mass.
  set tset to min(nd:deltav:mag / max_acc, 1).

  if vdot(dv0, nd:deltav) < 0 {
    print "End burn, remaining dv " + round(nd:deltav:mag, 1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav), 1).
    lock throttle to 0.
    break.
  }

  if nd:deltav:mag < 0.1 {
    print "Finalizing burn, remaining dv " + round(nd:deltav:mag, 1) + "m/s".
    // Burn very gently until our deltaV vector drifts from its original
    // direction.
    wait until vdot(dv0, nd:deltav) < 0.5.
    lock throttle to 0.
    print "End burn, remaining dv " + round(nd:deltav:mag, 1) + "m/s.".
    break.
  }
}

unlock steering.
unlock throttle.
wait 1.
remove nd.

