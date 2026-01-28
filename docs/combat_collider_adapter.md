# Combat Collider + HitPayload Bridge

How to use Combat Collider with our hurtbox pipeline:

1) Add your Combat Collider hitbox Areas under the actor’s `Hitboxes` node (or any child). Keep their collision layers/masks as needed.
2) Attach `engine/combat/HitPayloadAdapter.gd` to each hitbox Area. Set damage/knockback/owner_id/hitbox_id/tags in the inspector.
3) Ensure the actor hurtbox uses `engine/combat/HurtboxReceiver.gd` (already wired in our actors). It will read `get_hit_payload` or `hit_payload` meta from the colliding hitbox and forward to `ActorInterface.apply_hit`, which then triggers FSM Hurt and stats damage.
4) For projectiles or custom hitboxes, either:
   - Add `HitPayloadAdapter` directly, or
   - Populate meta `hit_payload` with a `HitPayload` resource or a Dictionary (damage, source_id, knockback) so `HurtboxReceiver` can normalize it.

Notes:
- No changes to Combat Collider logic are required; the adapter simply exposes a `get_hit_payload` compatible with our bridge.
- If Combat Collider already exposes its own payload method, you can skip the adapter and set `hit_payload` meta or implement `get_hit_payload` on the hitbox node to return a `HitPayload`.
