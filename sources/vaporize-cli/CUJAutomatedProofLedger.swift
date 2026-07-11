import Foundation

enum CUJAutomatedProofState: String, Codable, CaseIterable {
  case missingBinding = "missing-binding"
  case bindingOnly = "binding-only"
  case executableBound = "executable-bound"
  case evidenceBacked = "evidence-backed"
  case proven
  case invalidProvenClaim = "invalid-proven-claim"
}

enum CUJProofObligationKind: String, Codable {
  case declareProofReference = "declare-proof-reference"
  case resolveExecutableProof = "resolve-executable-proof"
  case captureGreenReceipt = "capture-green-receipt"
  case recordLastProvenChronon = "record-last-proven-chronon"
  case migrateTypedDefinition = "migrate-typed-definition"
}

struct CUJProofObligation: Codable, Equatable {
  var kind: CUJProofObligationKind
  var message: String
}

struct CUJAutomatedProofLedgerEntry: Codable, Equatable {
  var definitionID: String
  var title: String
  var projectKey: String
  var projectName: String
  var owningHomePath: String
  var definitionPaths: [String]
  var sourceClasses: [CUJArtifactClass]
  var statusOrdinal: Int?
  var proofState: CUJAutomatedProofState
  var declaredProofReferences: [CUJDeclaredProofReference]
  var resolvedExecutableProofPaths: [String]
  var savedEvidencePaths: [String]
  var lastProvenAtChrononID: Int?
  var structuralIssues: [String]
  var obligations: [CUJProofObligation]
}

struct CUJAutomatedProofLedgerSummary: Codable, Equatable {
  var definitionCount: Int
  var obligationCount: Int
  var byProofState: [String: Int]
}

struct CUJAutomatedProofLedgerReceipt: Codable, Equatable {
  var modelVersion: String = "0.1.0"
  var schemaVersion: String = "0.1.0"
  var schemaFamilySlug: String = "vaporize-schemas"
  var schemaFamilyVersion: String = "0.0.1"
  var schemaRef: String = Self.schemaReference
  var ledgerID: String = "substrate-cuj-automated-proof-ledger"
  var canonicalHome: String = Self.canonicalLedgerHome
  var scannedPath: String
  var generatedAt: String
  var generatedBy: String
  var summary: CUJAutomatedProofLedgerSummary
  var entries: [CUJAutomatedProofLedgerEntry]
  var boundaries: [String]

  enum CodingKeys: String, CodingKey {
    case modelVersion = "CUJAutomatedProofLedgerModel"
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
    case entries
    case boundaries
  }

  static let schemaReference =
    "private/universal/domain/tooling/schema-families/vaporize-schemas/v0.0.1/json/vaporize-schemas-v000-000-001/schemas/cuj-automated-proof-ledger/cuj-automated-proof-ledger.schema.json"

  static let canonicalLedgerHome =
    "private/universal/substrate/collectives/spaces-universal/private/universal/kura-spaces/workflows/vaporware-cuj-state-workstream/v0.1.0/automated-proofs/cuj-automated-proof-ledger.su.json"
}

enum CUJAutomatedProofLedgerBuilder {
  static func makeReceipt(
    from result: CUJPortfolioAuditResult,
    vaporizeVersion: String,
    generatedAt: Date = Date()
  ) -> CUJAutomatedProofLedgerReceipt {
    let homes = Dictionary(uniqueKeysWithValues: result.projects.map { ($0.key, $0.homePath) })
    let entries = result.definitions.map { definition in
      makeEntry(
        definition,
        owningHomePath: homes[definition.projectKey] ?? definition.sourcePaths.first ?? "unknown"
      )
    }
    var byProofState: [String: Int] = [:]
    for entry in entries {
      byProofState[entry.proofState.rawValue, default: 0] += 1
    }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return CUJAutomatedProofLedgerReceipt(
      scannedPath: result.scannedPath,
      generatedAt: formatter.string(from: generatedAt),
      generatedBy: "vaporize.cli@wrkstrm-core.clia.sh \(vaporizeVersion)",
      summary: CUJAutomatedProofLedgerSummary(
        definitionCount: entries.count,
        obligationCount: entries.reduce(0) { $0 + $1.obligations.count },
        byProofState: byProofState
      ),
      entries: entries,
      boundaries: [
        "This ledger is the canonical cross-portfolio index; it is not executable proof by itself.",
        "Executable automated proofs remain in the owning implementation package.",
        "Saved green execution receipts remain in the owning product proving-ground or release evidence home.",
        "A strict proven claim requires a declared proof reference, a resolved executable proof, saved green evidence, and lastProvenAtChrononID.",
        "Automated proof supports release review but never substitutes for required human approval.",
      ]
    )
  }

  private static func makeEntry(
    _ definition: CUJDefinitionRecord,
    owningHomePath: String
  ) -> CUJAutomatedProofLedgerEntry {
    let proofState: CUJAutomatedProofState
    if definition.isStandaloneTypedDefinition && definition.statusOrdinal == 3
      && !definition.isProven
    {
      proofState = .invalidProvenClaim
    } else if definition.isProven {
      proofState = .proven
    } else if !definition.savedEvidencePaths.isEmpty {
      proofState = .evidenceBacked
    } else if !definition.resolvedExecutableProofPaths.isEmpty {
      proofState = .executableBound
    } else if definition.declaredProofReferenceCount > 0 {
      proofState = .bindingOnly
    } else {
      proofState = .missingBinding
    }

    var obligations: [CUJProofObligation] = []
    if definition.declaredProofReferenceCount == 0 {
      obligations.append(
        CUJProofObligation(
          kind: .declareProofReference,
          message: "Add a typed automated proof reference to the CUJ definition."
        )
      )
    }
    if definition.resolvedExecutableProofPaths.isEmpty {
      obligations.append(
        CUJProofObligation(
          kind: .resolveExecutableProof,
          message:
            "Bind the journey to a resolvable Swift Testing type and test method in the owning implementation package."
        )
      )
    }
    if definition.savedEvidencePaths.isEmpty {
      obligations.append(
        CUJProofObligation(
          kind: .captureGreenReceipt,
          message:
            "Run the owning proof lane and save its green receipt in the owning proving-ground or release evidence home."
        )
      )
    }
    if definition.isStandaloneTypedDefinition
      && definition.statusOrdinal == 3
      && definition.lastProvenAtChrononID == nil
    {
      obligations.append(
        CUJProofObligation(
          kind: .recordLastProvenChronon,
          message:
            "Record lastProvenAtChrononID only after the bound proof and saved receipt are green."
        )
      )
    }
    if definition.sourceClasses.allSatisfy({ !$0.isStandaloneTypedDefinition }) {
      obligations.append(
        CUJProofObligation(
          kind: .migrateTypedDefinition,
          message:
            "Migrate this legacy or matrix journey into a standalone typed CUJ before claiming strict proven status."
        )
      )
    }

    return CUJAutomatedProofLedgerEntry(
      definitionID: definition.id,
      title: definition.title,
      projectKey: definition.projectKey,
      projectName: definition.projectName,
      owningHomePath: owningHomePath,
      definitionPaths: definition.sourcePaths,
      sourceClasses: definition.sourceClasses,
      statusOrdinal: definition.statusOrdinal,
      proofState: proofState,
      declaredProofReferences: definition.declaredProofReferences,
      resolvedExecutableProofPaths: definition.resolvedExecutableProofPaths,
      savedEvidencePaths: definition.savedEvidencePaths,
      lastProvenAtChrononID: definition.lastProvenAtChrononID,
      structuralIssues: definition.structuralIssues,
      obligations: obligations
    )
  }
}

enum CUJAutomatedProofLedgerRenderer {
  static func renderJSON(
    _ result: CUJPortfolioAuditResult,
    vaporizeVersion: String,
    generatedAt: Date = Date()
  ) throws -> Data {
    let receipt = CUJAutomatedProofLedgerBuilder.makeReceipt(
      from: result,
      vaporizeVersion: vaporizeVersion,
      generatedAt: generatedAt
    )
    return try VaporInventoryRenderer.makeJSONEncoder().encode(receipt)
  }
}
