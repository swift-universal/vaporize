# Cross-Platform Project Ownership

Vaporize owns the project declaration. Xcode, SwiftPM, and WCode are execution
adapters; none of them is the project model.

## Product Requirement

One `project.pkl` must describe the platform products an application intends to
ship without making an Apple-only tool the authority for Windows or Linux.
Platform declarations therefore live in Vaporize's `platformTargets` mapping.
The transitional `targets` mapping remains the input for the Xcode adapter.

Each platform target declares its platform, adapter, SwiftPM product, and
optional package path, entry point, presentation facade, UI backend, and
resources. These are intent fields. An adapter may consume only the fields it
understands, but it must not reinterpret another adapter's declaration as its
own target.

## Critical User Journey

An application maintainer adds a thin Windows entry point, declares it once in
`project.pkl`, and asks Vaporize to build through WCode. WCode evaluates the
Vaporize model, selects the named Windows target, delegates compilation to
SwiftPM, and materializes the resulting Windows artifact. The same declaration
can still be passed to the Xcode adapter, which projects only the existing
Apple `targets` and ignores `platformTargets`.

The journey succeeds when all of the following are true:

1. Pkl rejects an invalid platform, adapter, presentation, or backend value.
2. WCode finds the target only through `platformTargets`.
3. The Windows SwiftPM product builds from the declared thin entry point.
4. Xcode generation retains its Apple target count and names.
5. Existing platform views are not rewritten to accommodate another backend.

## Implementation Sequence

1. Keep the Xcode definition schema open only so Vaporize can extend it during
   the migration period.
2. Define the typed cross-platform fields in `Pkl/vaporize-project.pkl`.
3. Decode those fields through `VaporizeProjectModel`.
4. Migrate WCode from `XcodeProjectDefinition.targets` to
   `VaporizeProject.platformTargets`.
5. Move consumers one project at a time to the Vaporize schema.
6. Prove each consumer on its native adapter and re-run the unaffected adapter
   as a non-regression check.

## Failure Policy

A Windows compile failure is evidence of a missing SwiftUUI or backend feature.
The repair belongs in that facade or backend whenever possible. It is not
authorization to simplify, delete, or rewrite working SwiftUI or macOS code.

Warnings may report recoverable migration gaps. Typed declaration errors,
adapter ownership violations, and unsafe artifact paths remain blocking because
continuing would produce ambiguous or unsafe world-state.
