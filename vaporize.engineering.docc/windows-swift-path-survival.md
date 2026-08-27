# Windows Swift Path Survival

Deep source topology is legitimate product structure, but generated SwiftPM
state multiplies that depth with repository hashes, target names, intermediate
directories, object names, and plugin outputs. Windows long-path switches do
not make every tool in that chain long-path aware.

Vaporize therefore applies a conservative path budget before launching
SwiftPM. Short packages retain their inline `.build` workspace. A deep Windows
package receives a deterministic per-package scratch path under
`C:/b/v/<stable-package-key>`. The operator may select a different short,
writable root with `VAPORIZE_SWIFTPM_SCRATCH_ROOT`, and an explicit
`--scratch-path` remains authoritative.

The policy warns when a selected root still lacks predicted headroom. It does
not rename canonical product identities, silently reinterpret a DocC runtime
failure as a path failure, or claim ownership of scratch retention.

Scratch disk capacity is a separate lifecycle contract. The next slice must
add leases with owner, purpose, quota, heartbeat, expiry, success cleanup,
bounded failure retention, and pressure receipts. Short paths prevent legacy
path exhaustion; leases prevent short-path storage exhaustion.
