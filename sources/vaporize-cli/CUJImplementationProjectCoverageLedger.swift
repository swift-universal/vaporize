import Foundation

enum CUJImplementationProjectMappingConfidence: String, Codable, CaseIterable {
  case unmapped
  case medium
  case high
}

enum CUJImplementationProjectCoverageBand: String, Codable, CaseIterable {
  case unclassifiedNoCUJ = "unclassified-no-cuj"
  case mappedNoCUJ = "mapped-no-cuj"
  case definitionOnly = "definition-only"
  case bindingComplete = "binding-complete"
  case executableComplete = "executable-complete"
  case evidenceComplete = "evidence-complete"
  case strictProvenComplete = "strict-proven-complete"
  case mixedProgress = "mixed-progress"
  case structurallyBlocked = "structurally-blocked"
}

enum CUJImplementationProjectActionKind: String, Codable, CaseIterable {
  case classifyCUJApplicability = "classify-cuj-applicability"
  case authorOrLinkCUJ = "author-or-link-cuj"
  case confirmProjectMapping = "confirm-project-mapping"
  case migrateTypedDefinition = "migrate-typed-definition"
  case declareProofReference = "declare-proof-reference"
  case resolveExecutableProof = "resolve-executable-proof"
  case captureGreenReceipt = "capture-green-receipt"
  case recordLastProvenChronon = "record-last-proven-chronon"
  case repairStructuralIssue = "repair-structural-issue"
}

struct CUJImplementationProjectAction: Codable, Equatable {
  var kind: CUJImplementationProjectActionKind
  var quantity: Int
  var message: String
}

struct CUJImplementationProjectProofLegCounts: Codable, Equatable {
  var definitionCount: Int
  var standaloneTypedDefinitionCount: Int
  var legacyDefinitionCount: Int
  var declaredBindingDefinitionCount: Int
  var executableDefinitionCount: Int
  var evidenceBackedDefinitionCount: Int
  var chrononRecordedDefinitionCount: Int
  var structurallyValidDefinitionCount: Int
  var structuralIssueDefinitionCount: Int
  var strictProvenDefinitionCount: Int
  var invalidProvenClaimCount: Int
}

struct CUJImplementationProjectCoverageRecord: Codable, Equatable {
  var projectID: String
  var homePath: String
  var owner: String?
  var domain: String
  var productLine: String
  var surfaceKinds: [OwnedSurfaceKind]
  var surfacePaths: [String]
  var projectMappings: [CUJImplementationProjectMappingRecord]
  var mappingConfidence: CUJImplementationProjectMappingConfidence
  var definitionIDs: [String]
  var definitionRefs: [CUJDefinitionIdentityRef]
  var definitionSourceClassCounts: [String: Int]
  var proofLegs: CUJImplementationProjectProofLegCounts
  var proofStateCounts: [String: Int]
  var definitionObligationCounts: [String: Int]
  var proofLegCompletionBasisPoints: Int
  var coverageBand: CUJImplementationProjectCoverageBand
  var nextActions: [CUJImplementationProjectAction]
}

struct CUJImplementationProjectCoverageRollup: Codable, Equatable {
  var key: String
  var projectCount: Int
  var mappedProjectCount: Int
  var projectWithDefinitionCount: Int
  var definitionAssociationCount: Int
  var standaloneTypedDefinitionCount: Int
  var declaredBindingDefinitionCount: Int
  var executableDefinitionCount: Int
  var evidenceBackedDefinitionCount: Int
  var strictProvenDefinitionCount: Int
  var structuralIssueDefinitionCount: Int
  var nextActionCount: Int
}

struct CUJImplementationProjectCoverageSummary: Codable, Equatable {
  var implementationProjectCount: Int
  var implementationSurfaceCount: Int
  var mappedProjectCount: Int
  var unmappedProjectCount: Int
  var projectWithDefinitionCount: Int
  var projectWithoutDefinitionCount: Int
  var projectQualifiedDefinitionCount: Int
  var distinctDefinitionIDCount: Int
  var duplicatedDefinitionIDCount: Int
  var definitionRecordsUsingDuplicatedIDs: Int
  var definitionAssociationCount: Int
  var nextActionCount: Int
  var byCoverageBand: [String: Int]
  var byMappingConfidence: [String: Int]
  var bySurfaceKind: [String: Int]
  var byNextAction: [String: Int]
  var byOwner: [CUJImplementationProjectCoverageRollup]
  var byDomain: [CUJImplementationProjectCoverageRollup]
}

struct CUJImplementationProjectCoverageLedgerReceipt: Codable, Equatable {
  var modelVersion: String = "0.1.0"
  var schemaVersion: String = "0.1.0"
  var schemaFamilySlug: String = "vaporize-schemas"
  var schemaFamilyVersion: String = "0.0.1"
  var schemaRef: String = Self.schemaReference
  var ledgerID: String = "substrate-cuj-implementation-project-coverage-ledger"
  var canonicalHome: String = Self.canonicalLedgerHome
  var scannedPath: String
  var generatedAt: String
  var generatedBy: String
  var summary: CUJImplementationProjectCoverageSummary
  var projects: [CUJImplementationProjectCoverageRecord]
  var boundaries: [String]

  enum CodingKeys: String, CodingKey {
    case modelVersion = "CUJImplementationProjectCoverageLedgerModel"
    case schemaVersion
    case schemaFamilySlug
    case schemaFamilyVersion
    case schemaRef
    case ledgerID
    case canonicalHome
    case scannedPath
    case generatedAt
    case generatedBy
    case summary
    case projects
    case boundaries
  }

  static let schemaReference =
    "private/universal/domain/tooling/schema-families/vaporize-schemas/v0.0.1/json/vaporize-schemas-v000-000-001/schemas/cuj-implementation-project-coverage-ledger/cuj-implementation-project-coverage-ledger.schema.json"

  static let canonicalLedgerHome =
    "private/universal/substrate/collectives/spaces-universal/private/universal/kura-spaces/workflows/vaporware-cuj-state-workstream/v0.1.0/automated-proofs/cuj-implementation-project-coverage-ledger.su.json"
}

enum CUJImplementationProjectCoverageLedgerBuilder {
  static func makeReceipt(
    from result: CUJPortfolioAuditResult,
    vaporizeVersion: String,
    generatedAt: Date = Date()
  ) -> CUJImplementationProjectCoverageLedgerReceipt {
    let definitionsByRef = Dictionary(
      uniqueKeysWithValues: result.definitions.map {
        (CUJDefinitionIdentityRef(projectKey: $0.projectKey, definitionID: $0.id).compositeKey, $0)
      }
    )
    let proofEntriesByRef = Dictionary(
      uniqueKeysWithValues: CUJAutomatedProofLedgerBuilder.makeReceipt(
        from: result,
        vaporizeVersion: vaporizeVersion,
        generatedAt: generatedAt
      ).entries.map {
        (CUJDefinitionIdentityRef(projectKey: $0.projectKey, definitionID: $0.definitionID).compositeKey, $0)
      }
    )
    let projects = result.implementationProjects.map { project in
      makeProjectRecord(
        project,
        definitionsByRef: definitionsByRef,
        proofEntriesByRef: proofEntriesByRef
      )
    }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return CUJImplementationProjectCoverageLedgerReceipt(
      scannedPath: result.scannedPath,
      generatedAt: formatter.string(from: generatedAt),
      generatedBy: "vaporize.cli@wrkstrm-core.clia.sh \(vaporizeVersion)",
      summary: makeSummary(projects, definitions: result.definitions),
      projects: projects,
      boundaries: [
        "Every active-owned implementation project receives one row; aggregate bands never replace project detail.",
        "A project row records mapping provenance, implementation surfaces, every proof leg, structural validity, and quantified next actions.",
        "No-CUJ projects receive an applicability-classification action, not an automatic mandate to invent a user journey for infrastructure.",
        "Definition associations may appear in more than one implementation project when the same product journey spans multiple owning surfaces.",
        "Automated coverage detail is evidence and planning input; it does not approve a human governance or launch gate.",
      ]
    )
  }

  private static func makeProjectRecord(
    _ project: CUJImplementationProjectRecord,
    definitionsByRef: [String: CUJDefinitionRecord],
    proofEntriesByRef: [String: CUJAutomatedProofLedgerEntry]
  ) -> CUJImplementationProjectCoverageRecord {
    let definitions = project.definitionRefs.compactMap { definitionsByRef[$0.compositeKey] }
    let proofEntries = project.definitionRefs.compactMap { proofEntriesByRef[$0.compositeKey] }
    var sourceClassCounts: [String: Int] = [:]
    for definition in definitions {
      for sourceClass in definition.sourceClasses {
        sourceClassCounts[sourceClass.rawValue, default: 0] += 1
      }
    }
    var proofStateCounts: [String: Int] = [:]
    var obligationCounts: [String: Int] = [:]
    for entry in proofEntries {
      proofStateCounts[entry.proofState.rawValue, default: 0] += 1
      for obligation in entry.obligations {
        obligationCounts[obligation.kind.rawValue, default: 0] += 1
      }
    }

    let proofLegs = CUJImplementationProjectProofLegCounts(
      definitionCount: definitions.count,
      standaloneTypedDefinitionCount: definitions.count { $0.isStandaloneTypedDefinition },
      legacyDefinitionCount: definitions.count {
        $0.sourceClasses.allSatisfy { !$0.isStandaloneTypedDefinition }
      },
      declaredBindingDefinitionCount: definitions.count { $0.declaredProofReferenceCount > 0 },
      executableDefinitionCount: definitions.count { !$0.resolvedExecutableProofPaths.isEmpty },
      evidenceBackedDefinitionCount: definitions.count { !$0.savedEvidencePaths.isEmpty },
      chrononRecordedDefinitionCount: definitions.count { $0.lastProvenAtChrononID != nil },
      structurallyValidDefinitionCount: definitions.count { $0.structuralIssues.isEmpty },
      structuralIssueDefinitionCount: definitions.count { !$0.structuralIssues.isEmpty },
      strictProvenDefinitionCount: definitions.count { $0.isProven },
      invalidProvenClaimCount: proofEntries.count { $0.proofState == .invalidProvenClaim }
    )
    let mappingConfidence = mappingConfidence(for: project)
    let actions = makeActions(
      project: project,
      definitions: definitions,
      proofLegs: proofLegs,
      mappingConfidence: mappingConfidence
    )

    return CUJImplementationProjectCoverageRecord(
      projectID: "implementation-project:\(project.homePath)",
      homePath: project.homePath,
      owner: project.owner,
      domain: project.domain,
      productLine: project.productLine,
      surfaceKinds: project.surfaceKinds,
      surfacePaths: project.surfacePaths,
      projectMappings: project.projectMappings,
      mappingConfidence: mappingConfidence,
      definitionIDs: project.definitionIDs,
      definitionRefs: project.definitionRefs,
      definitionSourceClassCounts: sourceClassCounts,
      proofLegs: proofLegs,
      proofStateCounts: proofStateCounts,
      definitionObligationCounts: obligationCounts,
      proofLegCompletionBasisPoints: proofLegCompletionBasisPoints(proofLegs),
      coverageBand: coverageBand(
        proofLegs: proofLegs,
        proofStateCounts: proofStateCounts,
        isMapped: !project.projectMappings.isEmpty
      ),
      nextActions: actions
    )
  }

  private static func mappingConfidence(
    for project: CUJImplementationProjectRecord
  ) -> CUJImplementationProjectMappingConfidence {
    let methods = project.projectMappings.flatMap(\.methods)
    if methods.contains(.pathOverlap) { return .high }
    if methods.contains(.uniqueProductName) { return .medium }
    return .unmapped
  }

  private static func proofLegCompletionBasisPoints(
    _ proofLegs: CUJImplementationProjectProofLegCounts
  ) -> Int {
    guard proofLegs.definitionCount > 0 else { return 0 }
    let completed =
      proofLegs.standaloneTypedDefinitionCount
      + proofLegs.declaredBindingDefinitionCount
      + proofLegs.executableDefinitionCount
      + proofLegs.evidenceBackedDefinitionCount
      + proofLegs.chrononRecordedDefinitionCount
    let denominator = proofLegs.definitionCount * 5
    return (completed * 10_000 + denominator / 2) / denominator
  }

  private static func coverageBand(
    proofLegs: CUJImplementationProjectProofLegCounts,
    proofStateCounts: [String: Int],
    isMapped: Bool
  ) -> CUJImplementationProjectCoverageBand {
    guard proofLegs.definitionCount > 0 else {
      return isMapped ? .mappedNoCUJ : .unclassifiedNoCUJ
    }
    if proofLegs.structuralIssueDefinitionCount > 0 { return .structurallyBlocked }
    if proofLegs.strictProvenDefinitionCount == proofLegs.definitionCount {
      return .strictProvenComplete
    }
    if proofStateCounts.values.filter({ $0 > 0 }).count > 1 { return .mixedProgress }
    if proofLegs.evidenceBackedDefinitionCount == proofLegs.definitionCount {
      return .evidenceComplete
    }
    if proofLegs.executableDefinitionCount == proofLegs.definitionCount {
      return .executableComplete
    }
    if proofLegs.declaredBindingDefinitionCount == proofLegs.definitionCount {
      return .bindingComplete
    }
    return .definitionOnly
  }

  private static func makeActions(
    project: CUJImplementationProjectRecord,
    definitions: [CUJDefinitionRecord],
    proofLegs: CUJImplementationProjectProofLegCounts,
    mappingConfidence: CUJImplementationProjectMappingConfidence
  ) -> [CUJImplementationProjectAction] {
    var actions: [CUJImplementationProjectAction] = []
    if definitions.isEmpty {
      if project.projectMappings.isEmpty {
        actions.append(
          CUJImplementationProjectAction(
            kind: .classifyCUJApplicability,
            quantity: 1,
            message:
              "Classify whether this implementation project owns an operator journey or is covered through a consuming product's CUJs."
          )
        )
      } else {
        actions.append(
          CUJImplementationProjectAction(
            kind: .authorOrLinkCUJ,
            quantity: 1,
            message:
              "The project maps to a known product record but no CUJ definition resolves; author a direct CUJ or repair the owning link."
          )
        )
      }
    }
    if mappingConfidence == .medium {
      actions.append(
        CUJImplementationProjectAction(
          kind: .confirmProjectMapping,
          quantity: max(1, project.projectMappings.count),
          message:
            "Confirm the unique-name mapping with an explicit owning-home link before treating it as canonical."
        )
      )
    }
    appendAction(
      &actions,
      kind: .migrateTypedDefinition,
      quantity: proofLegs.legacyDefinitionCount,
      message: "Migrate legacy or matrix-only journeys into standalone typed CUJ definitions."
    )
    appendAction(
      &actions,
      kind: .declareProofReference,
      quantity: proofLegs.definitionCount - proofLegs.declaredBindingDefinitionCount,
      message: "Add typed automated-proof references to the affected CUJ definitions."
    )
    appendAction(
      &actions,
      kind: .resolveExecutableProof,
      quantity: proofLegs.definitionCount - proofLegs.executableDefinitionCount,
      message: "Resolve owning executable tests for the affected CUJ definitions."
    )
    appendAction(
      &actions,
      kind: .captureGreenReceipt,
      quantity: proofLegs.definitionCount - proofLegs.evidenceBackedDefinitionCount,
      message: "Execute the owning proof lane and save green evidence for the affected CUJs."
    )
    let evidenceWithoutChronon = definitions.count {
      !$0.savedEvidencePaths.isEmpty && $0.lastProvenAtChrononID == nil
    }
    appendAction(
      &actions,
      kind: .recordLastProvenChronon,
      quantity: evidenceWithoutChronon,
      message: "Record the last-proven Chronon for evidence-backed CUJs after proof verification."
    )
    appendAction(
      &actions,
      kind: .repairStructuralIssue,
      quantity: proofLegs.structuralIssueDefinitionCount,
      message: "Repair structural proof-contract violations before advancing any proven claim."
    )
    return actions.sorted { $0.kind.rawValue < $1.kind.rawValue }
  }

  private static func appendAction(
    _ actions: inout [CUJImplementationProjectAction],
    kind: CUJImplementationProjectActionKind,
    quantity: Int,
    message: String
  ) {
    guard quantity > 0 else { return }
    actions.append(CUJImplementationProjectAction(kind: kind, quantity: quantity, message: message))
  }

  private static func makeSummary(
    _ projects: [CUJImplementationProjectCoverageRecord],
    definitions: [CUJDefinitionRecord]
  ) -> CUJImplementationProjectCoverageSummary {
    var byCoverageBand: [String: Int] = [:]
    var byMappingConfidence: [String: Int] = [:]
    var bySurfaceKind: [String: Int] = [:]
    var byNextAction: [String: Int] = [:]
    for project in projects {
      byCoverageBand[project.coverageBand.rawValue, default: 0] += 1
      byMappingConfidence[project.mappingConfidence.rawValue, default: 0] += 1
      for surfaceKind in project.surfaceKinds {
        bySurfaceKind[surfaceKind.rawValue, default: 0] += 1
      }
      for action in project.nextActions {
        byNextAction[action.kind.rawValue, default: 0] += action.quantity
      }
    }
    let definitionsByID = Dictionary(grouping: definitions, by: \.id)
    let duplicatedDefinitionGroups = definitionsByID.values.filter { $0.count > 1 }
    return CUJImplementationProjectCoverageSummary(
      implementationProjectCount: projects.count,
      implementationSurfaceCount: projects.reduce(0) { $0 + $1.surfacePaths.count },
      mappedProjectCount: projects.count { $0.mappingConfidence != .unmapped },
      unmappedProjectCount: projects.count { $0.mappingConfidence == .unmapped },
      projectWithDefinitionCount: projects.count { $0.proofLegs.definitionCount > 0 },
      projectWithoutDefinitionCount: projects.count { $0.proofLegs.definitionCount == 0 },
      projectQualifiedDefinitionCount: definitions.count,
      distinctDefinitionIDCount: definitionsByID.count,
      duplicatedDefinitionIDCount: duplicatedDefinitionGroups.count,
      definitionRecordsUsingDuplicatedIDs: duplicatedDefinitionGroups.reduce(0) {
        $0 + $1.count
      },
      definitionAssociationCount: projects.reduce(0) { $0 + $1.proofLegs.definitionCount },
      nextActionCount: projects.reduce(0) {
        $0 + $1.nextActions.reduce(0) { $0 + $1.quantity }
      },
      byCoverageBand: byCoverageBand,
      byMappingConfidence: byMappingConfidence,
      bySurfaceKind: bySurfaceKind,
      byNextAction: byNextAction,
      byOwner: makeRollups(projects) { $0.owner ?? "unowned" },
      byDomain: makeRollups(projects) { $0.domain }
    )
  }

  private static func makeRollups(
    _ projects: [CUJImplementationProjectCoverageRecord],
    key: (CUJImplementationProjectCoverageRecord) -> String
  ) -> [CUJImplementationProjectCoverageRollup] {
    Dictionary(grouping: projects, by: key).map { rollupKey, group in
      CUJImplementationProjectCoverageRollup(
        key: rollupKey,
        projectCount: group.count,
        mappedProjectCount: group.count { $0.mappingConfidence != .unmapped },
        projectWithDefinitionCount: group.count { $0.proofLegs.definitionCount > 0 },
        definitionAssociationCount: group.reduce(0) { $0 + $1.proofLegs.definitionCount },
        standaloneTypedDefinitionCount: group.reduce(0) {
          $0 + $1.proofLegs.standaloneTypedDefinitionCount
        },
        declaredBindingDefinitionCount: group.reduce(0) {
          $0 + $1.proofLegs.declaredBindingDefinitionCount
        },
        executableDefinitionCount: group.reduce(0) {
          $0 + $1.proofLegs.executableDefinitionCount
        },
        evidenceBackedDefinitionCount: group.reduce(0) {
          $0 + $1.proofLegs.evidenceBackedDefinitionCount
        },
        strictProvenDefinitionCount: group.reduce(0) {
          $0 + $1.proofLegs.strictProvenDefinitionCount
        },
        structuralIssueDefinitionCount: group.reduce(0) {
          $0 + $1.proofLegs.structuralIssueDefinitionCount
        },
        nextActionCount: group.reduce(0) {
          $0 + $1.nextActions.reduce(0) { $0 + $1.quantity }
        }
      )
    }.sorted {
      if $0.projectCount != $1.projectCount { return $0.projectCount > $1.projectCount }
      return $0.key.localizedStandardCompare($1.key) == .orderedAscending
    }
  }
}

enum CUJImplementationProjectCoverageLedgerRenderer {
  static func renderJSON(
    _ result: CUJPortfolioAuditResult,
    vaporizeVersion: String,
    generatedAt: Date = Date()
  ) throws -> Data {
    let receipt = CUJImplementationProjectCoverageLedgerBuilder.makeReceipt(
      from: result,
      vaporizeVersion: vaporizeVersion,
      generatedAt: generatedAt
    )
    return try VaporInventoryRenderer.makeJSONEncoder().encode(receipt)
  }

  static func renderCSV(
    _ result: CUJPortfolioAuditResult,
    vaporizeVersion: String,
    generatedAt: Date = Date()
  ) -> String {
    let receipt = CUJImplementationProjectCoverageLedgerBuilder.makeReceipt(
      from: result,
      vaporizeVersion: vaporizeVersion,
      generatedAt: generatedAt
    )
    var rows = [[
      "projectID", "homePath", "owner", "domain", "productLine", "surfaceKinds",
      "surfacePaths", "mappingConfidence", "projectMappings", "definitionIDs", "definitionRefs",
      "definitionCount", "typedCount", "legacyCount", "declaredBindingCount",
      "executableCount", "evidenceCount", "chrononCount", "structurallyValidCount",
      "structuralIssueCount", "strictProvenCount", "invalidProvenClaimCount",
      "proofStateCounts", "definitionObligationCounts", "completionBasisPoints",
      "coverageBand", "nextActions",
    ]]
    rows.append(contentsOf: receipt.projects.map { project in
      [
        project.projectID,
        project.homePath,
        project.owner ?? "",
        project.domain,
        project.productLine,
        project.surfaceKinds.map(\.rawValue).joined(separator: "|"),
        project.surfacePaths.joined(separator: "|"),
        project.mappingConfidence.rawValue,
        project.projectMappings.map { mapping in
          "\(mapping.projectKey):\(mapping.methods.map(\.rawValue).joined(separator: "+"))"
        }.joined(separator: "|"),
        project.definitionIDs.joined(separator: "|"),
        project.definitionRefs.map(\.compositeKey).joined(separator: "|"),
        String(project.proofLegs.definitionCount),
        String(project.proofLegs.standaloneTypedDefinitionCount),
        String(project.proofLegs.legacyDefinitionCount),
        String(project.proofLegs.declaredBindingDefinitionCount),
        String(project.proofLegs.executableDefinitionCount),
        String(project.proofLegs.evidenceBackedDefinitionCount),
        String(project.proofLegs.chrononRecordedDefinitionCount),
        String(project.proofLegs.structurallyValidDefinitionCount),
        String(project.proofLegs.structuralIssueDefinitionCount),
        String(project.proofLegs.strictProvenDefinitionCount),
        String(project.proofLegs.invalidProvenClaimCount),
        renderCounts(project.proofStateCounts),
        renderCounts(project.definitionObligationCounts),
        String(project.proofLegCompletionBasisPoints),
        project.coverageBand.rawValue,
        project.nextActions.map { "\($0.kind.rawValue):\($0.quantity)" }.joined(separator: "|"),
      ]
    })
    return rows.map { $0.map(csvField).joined(separator: ",") }.joined(separator: "\n") + "\n"
  }

  private static func renderCounts(_ counts: [String: Int]) -> String {
    counts.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value)" }.joined(separator: "|")
  }

  private static func csvField(_ value: String) -> String {
    guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
      return value
    }
    return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
  }
}
