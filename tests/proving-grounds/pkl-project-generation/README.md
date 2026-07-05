# Pkl Project-Generation Proving Ground

This fixture is the checked-in proving ground for Vaporize's Pkl-backed Apple
project generation path.

It is intentionally small, but it drives the same track shape as the release
gate:

- `skid-pad`: malformed or unsupported target shapes are rejected by CUJ-14.
- `hill-climb`: a Pkl project graph generates `.xcodeproj` world state.
- `crash-barrier`: unsupported target types remain expected failures.
- `inspection-bay`: release evidence and Release Doctor name the proof.
- `prototype-track`: this checked-in fixture is the stable specimen before
  fleet build parity is complete.

The proving-ground harness owns the doctrine. This directory is the concrete
Pkl project-generation specimen that drives those tracks.
