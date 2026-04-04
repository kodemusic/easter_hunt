# Easter Hunt — Project Progress

> Update this file as features are completed. Use it as a reference at the start of each coding session.

---

## Player

| System | Status | File | Notes |
|--------|--------|------|-------|
| First-person movement (WASD + sprint) | ✅ Done | `scripts/player/player_controler.gd` | walk 3.0, sprint 6.0 (set in scene) |
| Mouse look (yaw + pitch) | ✅ Done | `scripts/player/player_controler.gd` | pitch clamped ±80° |
| Gravity | ✅ Done | `scripts/player/player_controler.gd` | 18 m/s² |
| Head bob | ✅ Done | `scripts/player/player_controler.gd` | amp 0.05, freq 2.0, scales with speed |
| Flashlight (SpotLight3D + particles) | ✅ Done | `scenes/player/player.tscn` | attached to Camera3D, warm color |
| Flashlight flicker (2-layer + bunny proximity) | ✅ Done | `scripts/player/flashlight.gd` | micro ±0.05 every frame; macro dip every 3–8s (1–2s near bunny); called by bunny_ai |
| Footstep audio | ✅ Done | `scripts/player/player_controler.gd` | step timer synced to bob frequency, calls AudioManager.play_footstep() |
| Interaction raycast (press E) | ✅ Done | `scripts/player/interactions.gd` | 2.5m range, hits Area3D + bodies, walks node hierarchy for "interactable" group |
| Camera script | ⬜ Pending | `scripts/player/camera_3d.gd` | placeholder — no effects yet |

---

## Pickups

| System | Status | File | Notes |
|--------|--------|------|-------|
| EggPickup scene | ✅ Done | `scenes/pickups/EggPickup.tscn` | egg.glb + Area3D (r=0.4) at root level, "interactable" group, egg_pickup.gd attached |
| egg_pickup.gd — interact() stub | ✅ Done | `scripts/pickups/egg_pickup.gd` | calls GameManager.collect_egg() + queue_free() |
| egg_pickup.gd — signal to GameManager | ✅ Done | `scripts/pickups/egg_pickup.gd` | calls GameManager.collect_egg() in interact() |
| Egg counter (total collected) | ✅ Done | `autoload/GameManager.gd` | egg_count var + egg_collected(total) signal |
| CheckpointShrine | ⬜ Pending | `scenes/pickups/CheckpointShrine.tscn` / `scripts/pickups/checkpoint.gd` | placeholder |

---

## Level / Progression

| System | Status | File | Notes |
|--------|--------|------|-------|
| Level layout | ✅ Done | `scenes/level/level01.tscn` | built and imported |
| Gate (opens on egg count) | ✅ Done | `scripts/level/gate.gd` | hides mesh + disables CollisionShape3D children; plays gate SFX via AudioManager |
| Door | ⬜ Pending | `scripts/level/door.gd` | placeholder |
| Trigger zones | ⬜ Pending | `scripts/level/trigger_zone.gd` | placeholder |

---

## Enemies

| System | Status | File | Notes |
|--------|--------|------|-------|
| Bunny visual presence | ✅ Done | `scenes/enemies/rabbit.tscn` | works visually |
| Bunny AI | ✅ Done | `scripts/enemies/bunny_ai.gd` | HIDDEN→VISIBLE(stare)→CHASE→CATCH states; gravity; smooth rotation; anim speed exports; flashlight proximity; emits player_caught signal |
| Patrol | ⬜ Pending | `scripts/enemies/patrol.gd` | placeholder |
| Enemy manager | ✅ Done | `scripts/managers/EnemieManager.gd` | timer-based spawning; egg-count frequency scaling; min spawn distance filter (8m); reload on catch |

---

## UI

| System | Status | File | Notes |
|--------|--------|------|-------|
| HUD (egg counter display) | ⬜ Pending | `scripts/ui/hud.gd` | placeholder |
| Death screen | ⬜ Pending | `scripts/ui/death_screen.gd` | placeholder |
| Win screen | ⬜ Pending | `scripts/ui/win_screen.gd` | placeholder |

---

## Autoload / Global

| System | Status | File | Notes |
|--------|--------|------|-------|
| GameManager | ✅ Done | `autoload/GameManager.gd` | egg_count, egg_collected signal |
| AudioManager | ✅ Done | `autoload/AudioManager.gd` | music (loop), ambience (loop), rabbit SFX (appear + periodic near/chase), gate SFX, footsteps (random from 3 wet files, pitch variation) |

---

## Input Actions (Project Settings → Input Map)

| Action | Status | Key |
|--------|--------|-----|
| move_forward | ✅ Done | W |
| move_back | ✅ Done | S |
| move_left | ✅ Done | A |
| move_right | ✅ Done | D |
| sprint | ✅ Done | Shift |
| interact | ⬜ Verify | E — add if missing |
| ui_cancel | ✅ Done | Escape |

---

## Known Issues / Bugs Fixed

- `collide_with_areas = true` required on raycast query — Area3D eggs were invisible to ray by default
- `NodePath("Camera3D")` was wrong (looked for child); fixed to `NodePath("../Camera3D")` (sibling)
- EggPickup Area3D was nested inside scaled egg_1 (0.02×) making collision sphere 0.05 world units — moved to root, radius now 0.4
- `egg_pickup.gd` had bunny AI code pasted into it by accident — no `interact()` method, pickup silently skipped
- Bunny AnimationPlayer has `"idle "` with a trailing space — that is the real key name; `"idle"` will not found
- EnemyManager: rabbit export not assigned → nil crash on `player_caught` signal connect; guarded with null check + push_error
