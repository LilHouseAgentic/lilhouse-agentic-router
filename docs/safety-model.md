# Safety Model

LilHouse is designed around permission-gated autonomy.

The public repo should default to observe-only behaviour.

Core principles:

1. Workers are read-only unless explicitly marked otherwise.
2. AI-generated output is proposal material, not executable truth.
3. Risky actions require human approval.
4. Supported actions must be allowlisted.
5. State/config backups should be made before changes.
6. Destructive actions are disabled by default.
7. Notification spam is treated as a system failure.
8. The highest active brain owns user-facing alerts.
