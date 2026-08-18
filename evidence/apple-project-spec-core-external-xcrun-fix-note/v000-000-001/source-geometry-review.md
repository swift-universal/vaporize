# AppleProjectSpecCore Fix Note — Source Geometry Review

**Recorded:** 2026-08-17  
**Scope:** exactly three active page-identity sources listed in
`active-source-digests.sha256`.

This is a source-native review record for the fix-note assets. It is not a
DocC viewer capture, Digikoma judgment, CPO design acceptance, installed
product proof, release, or Chairman decision.

## Exact Denominator

| Role | Source | viewBox | SHA-256 |
| --- | --- | --- | --- |
| icon | `apple-project-spec-core-external-xcrun-fix-note-2026-08-17-icon.svg` | `0 0 512 512` | `4f7b3a8f1fd697d32fb505dfca170603c0ec7850e47b1efa45c42309fc336c3f` |
| card | `apple-project-spec-core-external-xcrun-fix-note-2026-08-17-card.svg` | `0 0 1200 630` | `10bf3fe5bba202c705ae47b77d6fe3b49f2cc60be6df2508885eb93a4c23345a` |
| hero | `apple-project-spec-core-external-xcrun-fix-note-2026-08-17-hero.svg` | `0 0 1600 600` | `d5b37f5a6bd2f71553ea34fe9091276ac1cc9d0641f5c9b567da3cc97223f63d` |

## Checks And Findings

| Check | Result | Finding |
| --- | --- | --- |
| XML parse with `xmllint --noout` | passed | All three source files parse as SVG XML. |
| Source guard for scripts, style, gradients, and filled background rectangles | passed | None of the prohibited source constructs appears. Each canvas is transparent. |
| Text-free diagram source | passed | Labels remain in DocC headings and role-specific alt text rather than inside the art. |
| Native raster inspection at icon, card, and hero sizes | passed | The source declaration, generated world-state, execution boundary, and proof mark remain distinct. Connector rails visibly stop before semantic outlines; no accidental crossings, clipping, or element overlap was observed. |

The initial source review exposed a connector endpoint that extended through a
node outline. The active revision uses short rails with deliberate visible gaps
between every semantic station. The digests above identify that successor;
earlier preview rasters are not active evidence.

## Next Gates

Apple DocC conversion is separately proven for this source bundle. The
following remain open in
`activity-apple-project-spec-core-external-xcrun-fix-note-page-identity-review-v000-000-001-2026-08-17`:

1. retained rendered light and dark captures;
2. Website Visual Review Digikoma receipt for those exact captures;
3. explicit CPO review or change request.
