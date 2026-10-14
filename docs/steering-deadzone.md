# Central steering deadzone

Small accumulated mouse movements around the steering center can make it difficult
to hold a neutral steering command. This option creates an adjustable central
region with exactly zero output, while preserving full steering lock on both sides.

`STEERING_DEADZONE` defaults to `0.02` (2%) and accepts values from `0` to `0.1`
(10%). Set it to `0` to recover the original steering response.

The setting is declared in `extension/lua/mouse-steering/MSA/settings.ini` using
the existing Content Manager script settings mechanism. Where supported, find
**Steering deadzone** in the Mouse Steering Assist script settings. Otherwise,
edit the key in the existing `[SETTINGS]` section of that file. Use decimal
fractions with a decimal point. User overrides loaded by CSP take precedence
over script defaults. Restart the driving session after changing the value.

The script accumulates `deltaX` and clamps the raw position to [-1, 1], including
the existing optional FFB adjustment. Only the final output is remapped:

```text
abs(input) <= deadzone: output = 0
otherwise: output = sign(input) * (abs(input) - deadzone) / (1 - deadzone)
```

The remapped output never replaces the accumulated position. Repeated small
movements can therefore cross the boundary, and small movements away from the
center are still effective. The mapping is continuous at the boundary and keeps
the endpoints at -1 and +1. Its outer slope is necessarily `1 / (1 - deadzone)`;
no extra sensitivity change, temporal filter or automatic centering is added.
Throttle, brake, clutch and the existing optional FFB behavior are preserved.

## Automated checks

From the repository root with LuaJIT 2.1 available:

```sh
luajit tests/test_deadzone.lua
```

The tests execute the complete script in an isolated environment with a simulated
CSP API. They cover the center, values inside and exactly at either boundary,
the transition immediately outside, full lock, saturation, intermediate values,
disabled deadzone, the 10% configuration, out-of-range numeric settings, repeated
small movements, returning to the center and stationary updates.

Regression sequences compare steering and pedal outputs with the pre-change MSA
from upstream commit `4661c0b8899513f73e2b66743d63ae37456c0fd1`.
That baseline is preserved in `tests/fixtures/assist-before-deadzone.lua`.
The sequences exercise both branches of the existing CSP version compatibility
guard, FFB on/off, 0%/2%/10%, pedal press/release, alternate keys, Shift and scroll.
Newer CSP behavior is simulated; this is not a test in that CSP release.

## Validation still required in Assetto Corsa

The code was tested with LuaJIT 2.1 and inspected against the installed CSP
0.2.11 build 3465 SDK. No actual driving session or visual confirmation of the
new Content Manager field has been performed. The implementation is a proposal
pending integration and driving validation.

1. Start an offline practice session with 2%. With the car stationary, verify a
   central region with zero steering command on an input indicator.
2. Continue making small movements in one direction until steering leaves that
   region. Check smooth transitions on both sides, then return slowly to center.
3. Verify full steering lock in both directions. Repeat with 10% and then 0%.
4. Check throttle/brake keys or mouse buttons, alternate keys, scroll and Shift;
   confirm that clutch behavior remains unchanged.
5. Drive slowly in a clear area and assess steering transitions and oscillations.
   Repeat with the optional existing FFB enabled if normally used.
6. Restart Content Manager and a session to verify persistence and effective
   application of the selected setting, and check CSP logs for Lua errors.

Manual mouse movements cannot precisely measure normalized boundary values;
the numerical tests cover those values, while the game checks cover integration
and the practical control response.
