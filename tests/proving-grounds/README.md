# Vaporize Proving Grounds

This directory holds checked-in proving-ground specimens used by Vaporize CUJ
tests.

- `xcodegen-to-pkl-parity/` proves legacy XcodeGen `project.yml` records and
  XcodeProjectDefinition Pkl records evaluate to the same project signature.
- `pkl-project-generation/` proves Pkl-backed Apple project generation emits
  `.xcodeproj` world-state for checked-in specimens.

These fixtures are release evidence. They are intentionally small, but each one
must be targetable from a CUJ test before release evidence can rely on it.
