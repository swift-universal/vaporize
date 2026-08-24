# Vaporize Bead Lifecycle

This is the canonical Kura bead home for the Vaporize product line.

## Lifecycle lanes

- Files directly in `beads/` are active work. Active scanners may treat only this lane as the current queue.
- `closed/` contains completed records and their evidence. Closed identities remain searchable so a recurrence can reopen the same worldline instead of minting a duplicate.
- `archived/` contains superseded, obsolete, or sealed historical material. Normal active-work discovery must ignore this lane.
- `receipts/` contains receipts for active records and historical migrations. Closed i18n receipt families move with their owning identities under `closed/receipts/`.

## Identity

New human-authored bug IDs and filenames use lowercase kebab case, beginning with `bug-vaporize-`. Existing detector-authored and historical uppercase identities remain stable because renaming them would break evidence and checksum chains.

The historical product name `craze` may remain inside provenance, quotations, compatibility names, and `previousPath` values. Current product identities, source markers, and live cross-links use `vaporize` and this Kura home.

## Evidence integrity

Moving a record between lifecycle lanes does not authorize rewriting sealed evidence. Preserve artifact bytes and recorded hashes unless the owning detector regenerates the complete receipt, evidence, and worldline chain.

For detector-authored families, the newest canonical `.beads-issue.json` is the lifecycle authority. Older `.su.json` sidecars may preserve an earlier open observation inside the same closed family; their historical payload is not rewritten by hand.
