// Does a bounding leap then binary search for the optimal value.
// Can be used to eg. circularize an orbit by adding prograde delta-V until the
// target periapsis is achieved.

function stepsearch {
  parameter startA, stepA, targetB, bTolerance, getB, adjustA.
  local a1 is 0.
  local a2 is startA.
  local b1 is 0.
  local b2 is getB().

  // Do the stepwise scan to bracket the target.
  until false {
    set a1 to a2.
    set b1 to b2.
    set a2 to a1 + stepA.
    adjustA(a2).
    set b2 to getB().
    if abs(b2 - targetB) < bTolerance {
      return.
    }
    if ((b1 - targetB) < 0) <> ((b2 - targetB) < 0) {
      break. // We've got the target bracketed.
    }
  }

  // a1 and a2 bracket the target now.
  // To simplify the binary search, we swap a1 and a2 so that b1 < b2.
  if b1 > b2 {
    local tmp is a2.
    set a2 to a1.
    set a1 to tmp.
    set tmp to b2.
    set b2 to b1.
    set b1 to tmp.
  }

  // Now the binary search. We repeatedly halve the interval until we find a
  // tolerable value for Bs.
  until false {
    local As is (a1 + a2) / 2.
    adjustA(As).
    local Bs is getB().
    if abs(Bs - targetB) < bTolerance {
      return.
    }

    if Bs < targetB {
      set a2 to As.
    } else {
      set a1 to As.
    }
  }
}

