# Audit for translate — 2026-06-16T00-35-37Z

- Root: /Users/sonoma/mono/private/universal/substrate/collectives/wrkstrm-core/private/apple/apps
- Timestamp: 2026-06-16T00-35-37Z
- Mode: library
- Base: 0.0/0
- Penalty points: 0
- Blocking: 1/8
- Advisory: 1/12

## Downloads

- JSON report: 
  
  `/Users/sonoma/mono/private/universal/substrate/collectives/wrkstrm-core/private/apple/spm/vaporize@wrkstrm-core.cli/.wrkstrm/foundry/audit/translate/2026-06-16T00-35-37Z.json`

## Blocking checks

|ID               |Title                                       |Status|Message                                                         |
|-----------------|--------------------------------------------|------|----------------------------------------------------------------|
|docc-placeholder |DocC contains placeholder marker            |⏭️ skip|No .docc bundles found                                          |
|library-cli      |Library provides CLI target                 |❌ fail|Package.swift not readable                                      |
|license-present  |LICENSE present                             |❌ fail|Missing LICENSE (repo or package root)                          |
|package-swift    |Package.swift present                       |❌ fail|Missing                                                         |
|platforms-min    |Minimum platforms (policy: sla, macOS >= 15)|❌ fail|Package.swift not readable                                      |
|process-blacklist|No direct Foundation.Process usage          |✅ pass|score: 0 (no direct Process usages)                             |
|release-tag      |Semantic version release tag present        |⏭️ skip|Package root is not a git repository; skipping release tag check|
|tests            |Tests exist (Swift Testing only)            |❌ fail|No .swift tests; penalty: 0                                     |

## Advisory checks

|ID                          |Title                                         |Status|Message                                                                                                                                           |
|----------------------------|----------------------------------------------|------|--------------------------------------------------------------------------------------------------------------------------------------------------|
|ci-linux-test               |Linux test job present                        |❌ fail|Add a Linux job with swift test                                                                                                                   |
|common-cli-usage            |CommonCLI usage in CLI targets                |⏭️ skip|No executable targets found                                                                                                                       |
|common-shell-usage          |CommonShell/CommonProcess usage in CLI targets|⏭️ skip|No executable targets found                                                                                                                       |
|docc-build                  |DocC builds                                   |⏭️ skip|No .docc bundles found                                                                                                                            |
|docc-bundle                 |DocC bundle present                           |⚠️ warn|No .docc bundles detected                                                                                                                         |
|docc-minimum-layout         |DocC minimum layout pages                     |⏭️ skip|No .docc bundles found                                                                                                                            |
|github-actions              |GitHub Actions workflows present              |⚠️ warn|No workflows found                                                                                                                                |
|kebab-case                  |Kebab-case names                              |❌ fail|Root path not found:
/Users/sonoma/mono/private/universal/substrate/collectives/wrkstrm-core/private/apple/spm/vaporize@wrkstrm-core.cli/translate|
|network-foundationnetworking|FoundationNetworking guard present            |✅ pass|No URLSession usage detected                                                                                                                      |
|readme-present              |README present                                |⚠️ warn|Missing README at package root                                                                                                                    |
|swift-format                |Swift format config present                   |⏭️ skip|No .swift-format found; skipping                                                                                                                  |
|swift-tools-version-header  |Swift tools version header spacing            |❌ fail|Package.swift not readable                                                                                                                        |
