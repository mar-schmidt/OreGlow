# Testing

**27 Lua tests pass locally using LuaJIT in Lua 5.1 mode.** Synthetic tests
cover identity/hover deduplication, burst retries, false positives, secret
values, API failure, combat/death/taxi, source switches, startup, settings,
window controls, languages, readiness and the input-transparent pulse envelope.

The ZIP builder checks TOC existence, version agreement, integrity, one addon
root and SHA-256. Actual game access and range still need confirmation.

## In-game checklist

1. Load on Forever 1.60.1/enUS or enGB without a blocked-action error.
2. `/og test`: one soft gold pulse at all edges, clear center, normal input,
   clean fade. Blizzard's low-health warning stays intact.
3. Enable Interact Key in Options > Controls; approach a Copper Vein exposed
   as your interaction target. Confirm one pulse.
4. Linger for 30 seconds and briefly lose/regain the target: no repeats.
5. Approach a different same-name vein: its distinct GUID should alert.
6. Disable nearby alerts. An untouched minimap should never alert. Hover a
   real mining blip: one pulse. Held/repeated quick hovers stay silent.
7. Try Poor Copper, Tin, Iron and other veins. Herbs, chests, NPCs and quests
   must remain silent.
8. Combat/death/flight taxi pause observations; normal detection resumes later.
9. Check source switches, strength, duration, Swedish labels and saved settings.
10. Disable Interact Key: setup guidance appears and the game setting stays
    unchanged. Hover detection can still work with Find Minerals.
11. If using a minimap replacement, confirm real hover reaches the native API.

Report `/og status` and what was nearby/hovered. No account details are needed.
