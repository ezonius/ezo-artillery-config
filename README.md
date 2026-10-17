# Configurable Artillery

Adds startup multiplier settings for artillery, applied to **all** artillery turrets and wagons — vanilla and modded.

## Settings (startup, all default to 1 = vanilla)

- **Artillery range multiplier** — firing range of every artillery turret and wagon. The manual-fire range (automatic range × manual range modifier, vanilla 2.5) scales by the same multiplier.
- **Artillery gun cooldown multiplier** — cooldown between shots (lower = faster firing).
- **Artillery turret rotation speed multiplier** — how fast the barrel tracks targets.
- **Artillery shell damage multiplier** — damage dealt by shell projectiles.
- **Artillery splash radius multiplier** — explosion/area radius effects of shell projectiles.
- **Artillery minimum range multiplier** — minimum firing range; artillery never fires at closer targets.

Modded shells are included too: projectiles are discovered generically by walking each artillery gun's ammo trigger chain (no entity or projectile names are hard-coded). The manual range modifier itself is intentionally not scaled to avoid squaring the range effect.

Settings are startup settings (prototype values); changing them requires a game restart.
