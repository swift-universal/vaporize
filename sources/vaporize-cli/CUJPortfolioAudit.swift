import Foundation

enum CUJArtifactClass: String, Codable, CaseIterable {
  case typedProductDefinition = "typed-product-definition"
  case typedClientDefinition = "typed-client-definition"
  case typedHarnessDefinition = "typed-harness-definition"
  case typedRoleDefinition = "typed-role-definition"
  case typedOperatorDefinition = "typed-operator-definition"
  case typedWorkflowDefinition = "typed-workflow-definition"
  case typedImplementationDefinition = "typed-implementation-definition"
  case legacyJSONDefinition = "legacy-json-definition"
  case legacyMarkdownDefinition = "legacy-markdown-definition"
  case doccDefinition = "docc-definition"
  case coverageMatrix = "coverage-matrix"
  case coverageReceipt = "coverage-receipt"
  case coverageManifest = "coverage-manifest"
  case testProof = "test-proof"
  case schemaFixture = "schema-fixture"
  case testFixture = "test-fixture"
  case schemaDefinition = "schema-definition"
  case beadReference = "bead-reference"
  case workflowSupport = "workflow-support"
  case roleSupport = "role-support"
  case provingGroundProof = "proving-ground-proof"
  case auditReceipt = "audit-receipt"
  case releaseEvidence = "release-evidence"
  case journeyTree = "journey-tree"
  case unknownCUJArtifact = "unknown-cuj-artifact"

  var isStandaloneTypedDefinition: Bool {
    switch self {
    case .typedProductDefinition, .typedClientDefinition, .typedHarnessDefinition,
      .typedRoleDefinition, .typedOperatorDefinition, .typedWorkflowDefinition,
      .typedImplementationDefinition:
      return true
    default:
      return false
    }
  }

  var isLegacyDefinition: Bool {
    self == .legacyJSONDefinition || self == .legacyMarkdownDefinition || self == .doccDefinition
  }
}

enum CUJProjectScope: String, Codable, CaseIterable {
  case canonicalProductLine = "canonical-product-line"
  case client
  case harnessForm = "harness-form"
  case role
  case operatorJourneySpace = "operator-journey-space"
  case workflow
  case implementationProject = "implementation-project"
  case other
}

struct CUJArtifactRecord: Codable, Equatable {
  var artifactClass: CUJArtifactClass
  var path: String
  var projectKey: String?
  var definitionIDs: [String]
  var structuralIssues: [String]
}

struct CUJDeclaredProofReference: Codable, Equatable, Hashable {
  var claim: String?
  var packagePath: String?
  var testTypeName: String?
  var testMethodName: String?
  var tag: String?
  var declarationPath: String
  var format: String
}

struct CUJDefinitionRecord: Codable, Equatable {
  var id: String
  var title: String
  var projectKey: String
  var projectName: String
  var sourceClasses: [CUJArtifactClass]
  var sourcePaths: [String]
  var statusOrdinal: Int?
  var declaredProofReferenceCount: Int
  var declaredProofReferences: [CUJDeclaredProofReference]
  var resolvedExecutableProofPaths: [String]
  var savedEvidencePaths: [String]
  var lastProvenAtChrononID: Int?
  var evidencePaths: [String]
  var structuralIssues: [String]

  var proofBound: Bool {
    declaredProofReferenceCount > 0
      || !resolvedExecutableProofPaths.isEmpty
      || !savedEvidencePaths.isEmpty
  }

  var isStandaloneTypedDefinition: Bool {
    sourceClasses.contains(where: \.isStandaloneTypedDefinition)
  }

  var isProven: Bool {
    isStandaloneTypedDefinition
      && statusOrdinal == 3
      && declaredProofReferenceCount > 0
      && !resolvedExecutableProofPaths.isEmpty
      && !savedEvidencePaths.isEmpty
      && lastProvenAtChrononID != nil
      && structuralIssues.isEmpty
  }
}

struct CUJProjectRecord: Codable, Equatable {
  var key: String
  var name: String
  var scope: CUJProjectScope
  var homePath: String
  var owner: String?
  var directDefinitionIDs: [String]
  var linkedDefinitionIDs: [String]
  var definitionIDs: [String]
  var standaloneTypedDefinitionCount: Int
  var matrixDefinitionCount: Int
  var legacyDefinitionCount: Int
  var proofBoundDefinitionCount: Int
  var provenDefinitionCount: Int
  var structuralIssueCount: Int
}

struct CUJImplementationProjectRecord: Codable, Equatable {
  var homePath: String
  var owner: String?
  var domain: String
  var productLine: String
  var surfaceKinds: [OwnedSurfaceKind]
  var surfacePaths: [String]
  var mappedProjectKeys: [String]
  var definitionIDs: [String]
}

struct CUJPortfolioAuditSummary: Codable, Equatable {
  var artifactCount: Int = 0
  var uniqueDefinitionCount: Int = 0
  var standaloneTypedDefinitionCount: Int = 0
  var matrixDefinitionCount: Int = 0
  var legacyDefinitionCount: Int = 0
  var proofBoundDefinitionCount: Int = 0
  var executableBoundDefinitionCount: Int = 0
  var evidenceBackedDefinitionCount: Int = 0
  var unboundDefinitionCount: Int = 0
  var provenDefinitionCount: Int = 0
  var invalidProvenClaimCount: Int = 0
  var structurallyInvalidDefinitionCount: Int = 0
  var canonicalProductHomeCount: Int = 0
  var canonicalProductHomesWithDirectDefinitions: Int = 0
  var canonicalProductHomesWithLinkedOnlyDefinitions: Int = 0
  var canonicalProductHomesWithDefinitions: Int = 0
  var canonicalProductHomesWithoutDefinitions: Int = 0
  var activeOwnedSurfaceCount: Int = 0
  var activeOwnedImplementationProjectCount: Int = 0
  var activeOwnedImplementationProjectsWithCUJs: Int = 0
  var activeOwnedImplementationProjectsWithoutCUJs: Int = 0
  var byArtifactClass: [String: Int] = [:]
  var byProjectScope: [String: Int] = [:]
}

struct CUJPortfolioAuditResult: Equatable {
  var scannedPath: String
  var summary: CUJPortfolioAuditSummary
  var projects: [CUJProjectRecord]
  var implementationProjects: [CUJImplementationProjectRecord]
  var definitions: [CUJDefinitionRecord]
  var artifacts: [CUJArtifactRecord]
}

struct CUJPortfolioAuditReceipt: Codable, Equatable {
  var schemaVersion: String = "0.1.0-cuj-portfolio-audit"
  var modelVersion: String = "0.1.0"
  var scannedPath: String
  var scannedAt: String
  var vaporizeVersion: String
  var summary: CUJPortfolioAuditSummary
  var projects: [CUJProjectRecord]
  var implementationProjects: [CUJImplementationProjectRecord]
  var definitions: [CUJDefinitionRecord]
  var artifacts: [CUJArtifactRecord]

  enum CodingKeys: String, CodingKey {
    case schemaVersion
    case modelVersion = "CUJPortfolioAuditModel"
    case scannedPath
    case scannedAt
    case vaporizeVersion
    case summary
    case projects
    case implementationProjects
    case definitions
    case artifacts
  }
}

struct CUJPortfolioAuditScanner {
  enum ScannerError: Error, CustomStringConvertible {
    case pathDoesNotExist(String)
    case pathIsNotDirectory(String)

    var description: String {
      switch self {
      case .pathDoesNotExist(let path):
        return "vaporize cuj-audit: --path does not exist: \(path)"
      case .pathIsNotDirectory(let path):
        return "vaporize cuj-audit: --path is not a directory: \(path)"
      }
    }
  }

  private struct ProjectIdentity: Hashable {
    var key: String
    var name: String
    var scope: CUJProjectScope
    var homePath: String
    var owner: String?
  }

  private struct DefinitionCandidate {
    var id: String
    var title: String
    var project: ProjectIdentity
    var sourceClass: CUJArtifactClass
    var sourcePath: String
    var statusOrdinal: Int?
    var declaredProofReferenceCount: Int
    var declaredProofReferences: [CUJDeclaredProofReference]
    var lastProvenAtChrononID: Int?
    var evidencePaths: [String]
    var structuralIssues: [String]
  }

  private struct ProofSource {
    var path: String
    var searchableText: String
    var isSavedGreenEvidence: Bool
  }

  private struct ScanAccumulator {
    var projects: [String: ProjectIdentity] = [:]
    var artifacts: [CUJArtifactRecord] = []
    var definitions: [DefinitionCandidate] = []
    var proofSources: [ProofSource] = []
  }

  private struct DefinitionAccumulator {
    var id: String
    var title: String
    var projectKey: String
    var projectName: String
    var sourceClasses: Set<CUJArtifactClass> = []
    var sourcePaths: Set<String> = []
    var statusOrdinal: Int?
    var declaredProofReferenceCount: Int = 0
    var declaredProofReferences: Set<CUJDeclaredProofReference> = []
    var lastProvenAtChrononID: Int?
    var evidencePaths: Set<String> = []
    var structuralIssues: Set<String> = []

    mutating func merge(_ candidate: DefinitionCandidate) {
      if title.isEmpty { title = candidate.title }
      sourceClasses.insert(candidate.sourceClass)
      sourcePaths.insert(candidate.sourcePath)
      statusOrdinal = max(statusOrdinal ?? 0, candidate.statusOrdinal ?? 0)
      declaredProofReferenceCount += candidate.declaredProofReferenceCount
      declaredProofReferences.formUnion(candidate.declaredProofReferences)
      if let candidateChronon = candidate.lastProvenAtChrononID {
        lastProvenAtChrononID = max(lastProvenAtChrononID ?? candidateChronon, candidateChronon)
      }
      evidencePaths.formUnion(candidate.evidencePaths)
      structuralIssues.formUnion(candidate.structuralIssues)
    }

    func record(
      resolvedExecutableProofPaths: [String] = [],
      savedEvidencePaths: [String] = [],
      additionalIssues: [String] = []
    ) -> CUJDefinitionRecord {
      CUJDefinitionRecord(
        id: id,
        title: title,
        projectKey: projectKey,
        projectName: projectName,
        sourceClasses: sourceClasses.sorted { $0.rawValue < $1.rawValue },
        sourcePaths: sourcePaths.sorted(by: Self.localizedLessThan),
        statusOrdinal: statusOrdinal == 0 ? nil : statusOrdinal,
        declaredProofReferenceCount: declaredProofReferenceCount,
        declaredProofReferences: declaredProofReferences.sorted {
          ($0.testTypeName ?? $0.packagePath ?? $0.claim ?? "")
            < ($1.testTypeName ?? $1.packagePath ?? $1.claim ?? "")
        },
        resolvedExecutableProofPaths: resolvedExecutableProofPaths.sorted(
          by: Self.localizedLessThan),
        savedEvidencePaths: savedEvidencePaths.sorted(by: Self.localizedLessThan),
        lastProvenAtChrononID: lastProvenAtChrononID,
        evidencePaths: evidencePaths.sorted(by: Self.localizedLessThan),
        structuralIssues: structuralIssues.union(additionalIssues).sorted(
          by: Self.localizedLessThan)
      )
    }

    private static func localizedLessThan(_ lhs: String, _ rhs: String) -> Bool {
      lhs.localizedStandardCompare(rhs) == .orderedAscending
    }
  }

  var fileManager: FileManager = .default

  func scan(path: String) throws -> CUJPortfolioAuditResult {
    let absolutePath = VaporInventoryScanner.resolveAbsolutePath(path)
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: absolutePath, isDirectory: &isDirectory) else {
      throw ScannerError.pathDoesNotExist(absolutePath)
    }
    guard isDirectory.boolValue else {
      throw ScannerError.pathIsNotDirectory(absolutePath)
    }

    let root = URL(fileURLWithPath: absolutePath, isDirectory: true)
    var accumulator = try scanCUJArtifacts(root: root)
    let definitions = consolidateDefinitions(
      accumulator.definitions,
      proofSources: accumulator.proofSources,
      root: root
    )
    let projects = makeProjectRecords(
      identities: accumulator.projects,
      definitions: definitions
    )
    let ownedSurfaceResult = try OwnedSurfaceInventoryScanner(fileManager: fileManager).scan(
      path: absolutePath)
    let implementationProjects = makeImplementationProjects(
      from: ownedSurfaceResult,
      projects: projects,
      root: root
    )

    accumulator.artifacts.sort {
      if $0.artifactClass != $1.artifactClass {
        return $0.artifactClass.rawValue < $1.artifactClass.rawValue
      }
      return localizedLessThan($0.path, $1.path)
    }

    let summary = makeSummary(
      projects: projects,
      implementationProjects: implementationProjects,
      definitions: definitions,
      artifacts: accumulator.artifacts,
      activeOwnedSurfaceCount: ownedSurfaceResult.summary.activeOwnedSurfaces
    )

    return CUJPortfolioAuditResult(
      scannedPath: absolutePath,
      summary: summary,
      projects: projects,
      implementationProjects: implementationProjects,
      definitions: definitions,
      artifacts: accumulator.artifacts
    )
  }

  func receipt(
    from result: CUJPortfolioAuditResult,
    vaporizeVersion: String,
    scannedAt: Date = Date()
  ) -> CUJPortfolioAuditReceipt {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return CUJPortfolioAuditReceipt(
      scannedPath: result.scannedPath,
      scannedAt: formatter.string(from: scannedAt),
      vaporizeVersion: vaporizeVersion,
      summary: result.summary,
      projects: result.projects,
      implementationProjects: result.implementationProjects,
      definitions: result.definitions,
      artifacts: result.artifacts
    )
  }

  private func scanCUJArtifacts(root: URL) throws -> ScanAccumulator {
    let keys: Set<URLResourceKey> = [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey]
    guard
      let enumerator = fileManager.enumerator(
        at: root,
        includingPropertiesForKeys: Array(keys),
        options: [.skipsHiddenFiles],
        errorHandler: { _, _ in true }
      )
    else {
      return ScanAccumulator()
    }

    var accumulator = ScanAccumulator()
    while let candidate = enumerator.nextObject() as? URL {
      let values = try? candidate.resourceValues(forKeys: keys)
      if values?.isDirectory == true {
        if shouldSkipDirectory(candidate) || values?.isSymbolicLink == true {
          enumerator.skipDescendants()
          continue
        }
        if candidate.deletingLastPathComponent().lastPathComponent == "product-lines" {
          let identity = projectIdentity(forProductHome: candidate, root: root)
          accumulator.projects[identity.key] = identity
        }
        continue
      }

      guard values?.isRegularFile == true else { continue }
      let relativePath = relativePath(candidate, root: root)
      let lowerPath = relativePath.lowercased()
      let lowerName = candidate.lastPathComponent.lowercased()

      if candidate.pathExtension.lowercased() == "json", isJSONCUJCandidate(lowerPath: lowerPath) {
        inspectJSON(
          at: candidate,
          relativePath: relativePath,
          root: root,
          accumulator: &accumulator
        )
      } else if candidate.pathExtension.lowercased() == "md",
        isMarkdownCUJCandidate(lowerPath: lowerPath)
      {
        inspectMarkdown(
          at: candidate,
          relativePath: relativePath,
          root: root,
          accumulator: &accumulator
        )
      } else if candidate.pathExtension.lowercased() == "swift",
        isTestProofCandidate(lowerPath: lowerPath, lowerName: lowerName)
      {
        inspectTestProof(at: candidate, relativePath: relativePath, accumulator: &accumulator)
      }
    }
    return accumulator
  }

  private func inspectJSON(
    at url: URL,
    relativePath: String,
    root: URL,
    accumulator: inout ScanAccumulator
  ) {
    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      accumulator.artifacts.append(
        CUJArtifactRecord(
          artifactClass: .unknownCUJArtifact,
          path: relativePath,
          projectKey: nil,
          definitionIDs: [],
          structuralIssues: ["unreadable JSON: \(error.localizedDescription)"]
        )
      )
      return
    }

    let object: [String: Any]
    do {
      guard let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw JSONInspectionError.notObject
      }
      object = decoded
    } catch {
      accumulator.artifacts.append(
        CUJArtifactRecord(
          artifactClass: .unknownCUJArtifact,
          path: relativePath,
          projectKey: nil,
          definitionIDs: [],
          structuralIssues: ["invalid CUJ JSON: \(error.localizedDescription)"]
        )
      )
      return
    }

    let lowerPath = relativePath.lowercased()
    let project = projectIdentity(for: url, root: root)
    accumulator.projects[project.key] = project

    if isSchemaFixture(path: lowerPath) {
      accumulator.artifacts.append(
        CUJArtifactRecord(
          artifactClass: .schemaFixture,
          path: relativePath,
          projectKey: project.key,
          definitionIDs: [],
          structuralIssues: []
        )
      )
      return
    }

    if let supportingClass = supportingArtifactClass(for: lowerPath) {
      accumulator.artifacts.append(
        CUJArtifactRecord(
          artifactClass: supportingClass,
          path: relativePath,
          projectKey: project.key,
          definitionIDs: [],
          structuralIssues: []
        )
      )
      if supportingClass == .provingGroundProof || supportingClass == .auditReceipt
        || supportingClass == .releaseEvidence
      {
        accumulator.proofSources.append(
          ProofSource(
            path: relativePath,
            searchableText: String(decoding: data, as: UTF8.self),
            isSavedGreenEvidence: supportingClass != .releaseEvidence
              && isGreenExecutionEvidence(object, path: relativePath)
          )
        )
      }
      return
    }

    if isJourneyTree(object: object, path: lowerPath) {
      accumulator.artifacts.append(
        CUJArtifactRecord(
          artifactClass: .journeyTree,
          path: relativePath,
          projectKey: project.key,
          definitionIDs: [],
          structuralIssues: []
        )
      )
      return
    }

    if isCoverageMatrix(object: object, path: lowerPath) {
      let candidates = matrixDefinitions(
        object: object,
        project: project,
        sourcePath: relativePath
      )
      accumulator.definitions.append(contentsOf: candidates)
      accumulator.artifacts.append(
        CUJArtifactRecord(
          artifactClass: .coverageMatrix,
          path: relativePath,
          projectKey: project.key,
          definitionIDs: candidates.map(\.id).sorted(by: localizedLessThan),
          structuralIssues: candidates.flatMap(\.structuralIssues)
        )
      )
      accumulator.proofSources.append(
        ProofSource(
          path: relativePath,
          searchableText: String(decoding: data, as: UTF8.self),
          isSavedGreenEvidence: false
        )
      )
      return
    }

    if isCoverageReceipt(path: lowerPath) {
      accumulator.artifacts.append(
        CUJArtifactRecord(
          artifactClass: .coverageReceipt,
          path: relativePath,
          projectKey: project.key,
          definitionIDs: [],
          structuralIssues: []
        )
      )
      accumulator.proofSources.append(
        ProofSource(
          path: relativePath,
          searchableText: String(decoding: data, as: UTF8.self),
          isSavedGreenEvidence: isGreenExecutionEvidence(object, path: relativePath)
        )
      )
      return
    }

    if isCoverageManifest(path: lowerPath) {
      accumulator.artifacts.append(
        CUJArtifactRecord(
          artifactClass: .coverageManifest,
          path: relativePath,
          projectKey: project.key,
          definitionIDs: [],
          structuralIssues: []
        )
      )
      accumulator.proofSources.append(
        ProofSource(
          path: relativePath,
          searchableText: String(decoding: data, as: UTF8.self),
          isSavedGreenEvidence: false
        )
      )
      return
    }

    if let journeys = object["criticalUserJourneys"] as? [[String: Any]] {
      let candidates = legacyJSONDefinitions(
        journeys: journeys,
        project: project,
        sourcePath: relativePath
      )
      accumulator.definitions.append(contentsOf: candidates)
      accumulator.artifacts.append(
        CUJArtifactRecord(
          artifactClass: .legacyJSONDefinition,
          path: relativePath,
          projectKey: project.key,
          definitionIDs: candidates.map(\.id).sorted(by: localizedLessThan),
          structuralIssues: candidates.flatMap(\.structuralIssues)
        )
      )
      return
    }

    if let journeys = object["cujs"] as? [[String: Any]] {
      let candidates = legacyJSONDefinitions(
        journeys: journeys,
        project: project,
        sourcePath: relativePath
      )
      accumulator.definitions.append(contentsOf: candidates)
      accumulator.artifacts.append(
        CUJArtifactRecord(
          artifactClass: .legacyJSONDefinition,
          path: relativePath,
          projectKey: project.key,
          definitionIDs: candidates.map(\.id).sorted(by: localizedLessThan),
          structuralIssues: candidates.flatMap(\.structuralIssues)
        )
      )
      return
    }

    if isCompactCUJDefinition(object) || isLongFormCUJDefinition(object) {
      let artifactClass = typedDefinitionClass(for: lowerPath)
      let definition = individualDefinition(
        object: object,
        project: project,
        sourceClass: artifactClass,
        sourcePath: relativePath
      )
      accumulator.definitions.append(definition)
      accumulator.artifacts.append(
        CUJArtifactRecord(
          artifactClass: artifactClass,
          path: relativePath,
          projectKey: project.key,
          definitionIDs: [definition.id],
          structuralIssues: definition.structuralIssues
        )
      )
      return
    }

    if isLegacySingleCUJDefinition(object) {
      let definition = legacySingleDefinition(
        object: object,
        project: project,
        sourcePath: relativePath
      )
      accumulator.definitions.append(definition)
      accumulator.artifacts.append(
        CUJArtifactRecord(
          artifactClass: .legacyJSONDefinition,
          path: relativePath,
          projectKey: project.key,
          definitionIDs: [definition.id],
          structuralIssues: definition.structuralIssues
        )
      )
      return
    }

    accumulator.artifacts.append(
      CUJArtifactRecord(
        artifactClass: .unknownCUJArtifact,
        path: relativePath,
        projectKey: project.key,
        definitionIDs: [],
        structuralIssues: [
          "CUJ-named JSON is not a recognized definition, matrix, receipt, manifest, tree, or fixture"
        ]
      )
    )
  }

  private func inspectMarkdown(
    at url: URL,
    relativePath: String,
    root: URL,
    accumulator: inout ScanAccumulator
  ) {
    guard let text = try? String(contentsOf: url, encoding: .utf8) else {
      accumulator.artifacts.append(
        CUJArtifactRecord(
          artifactClass: .unknownCUJArtifact,
          path: relativePath,
          projectKey: nil,
          definitionIDs: [],
          structuralIssues: ["unreadable CUJ Markdown"]
        )
      )
      return
    }

    let project = projectIdentity(for: url, root: root)
    accumulator.projects[project.key] = project
    let lowerPath = relativePath.lowercased()
    if isSchemaFixture(path: lowerPath) {
      accumulator.artifacts.append(
        CUJArtifactRecord(
          artifactClass: .schemaFixture,
          path: relativePath,
          projectKey: project.key,
          definitionIDs: [],
          structuralIssues: []
        )
      )
      return
    }

    let artifactClass: CUJArtifactClass =
      lowerPath.contains("/cuj.docc/")
      ? .doccDefinition
      : .legacyMarkdownDefinition
    let definitions = markdownDefinitions(
      text: text,
      url: url,
      project: project,
      sourceClass: artifactClass,
      sourcePath: relativePath
    )
    accumulator.definitions.append(contentsOf: definitions)
    accumulator.artifacts.append(
      CUJArtifactRecord(
        artifactClass: artifactClass,
        path: relativePath,
        projectKey: project.key,
        definitionIDs: definitions.map(\.id).sorted(by: localizedLessThan),
        structuralIssues: definitions.isEmpty
          ? ["CUJ Markdown contains no identifiable journey definition"] : []
      )
    )
  }

  private func inspectTestProof(
    at url: URL,
    relativePath: String,
    accumulator: inout ScanAccumulator
  ) {
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { return }
    accumulator.artifacts.append(
      CUJArtifactRecord(
        artifactClass: .testProof,
        path: relativePath,
        projectKey: nil,
        definitionIDs: [],
        structuralIssues: []
      )
    )
    accumulator.proofSources.append(
      ProofSource(
        path: relativePath,
        searchableText: text,
        isSavedGreenEvidence: false
      )
    )
  }

  private func consolidateDefinitions(
    _ candidates: [DefinitionCandidate],
    proofSources: [ProofSource],
    root: URL
  ) -> [CUJDefinitionRecord] {
    var merged: [String: DefinitionAccumulator] = [:]
    let orderedCandidates = candidates.sorted {
      projectPreference($0.project) < projectPreference($1.project)
    }
    for candidate in orderedCandidates {
      let owner = candidate.project.owner ?? "unowned"
      let key =
        "\(owner)|\(normalizeProjectName(candidate.project.name))|\(candidate.id.lowercased())"
      if merged[key] == nil {
        merged[key] = DefinitionAccumulator(
          id: candidate.id,
          title: candidate.title,
          projectKey: candidate.project.key,
          projectName: candidate.project.name,
          statusOrdinal: candidate.statusOrdinal
        )
      }
      merged[key]?.merge(candidate)
    }

    for key in merged.keys {
      guard var definition = merged[key] else { continue }
      for proof in proofSources where proofMatches(definition.id, proof: proof) {
        definition.evidencePaths.insert(proof.path)
      }
      merged[key] = definition
    }

    return merged.values.map { definition in
      var executablePaths = Set(
        definition.evidencePaths.filter { $0.lowercased().hasSuffix(".swift") }
      )
      var savedEvidencePaths = Set(
        proofSources.filter {
          $0.isSavedGreenEvidence && proofMatches(definition.id, proof: $0)
        }.map(\.path)
      )
      for reference in definition.declaredProofReferences {
        executablePaths.formUnion(resolveExecutableProof(reference, root: root))
      }
      for path in definition.evidencePaths where !path.lowercased().hasSuffix(".swift") {
        guard
          let resolved = resolveEvidencePath(
            path,
            sourcePaths: Array(definition.sourcePaths),
            root: root
          )
        else { continue }
        let url = resolveSubstratePath(resolved, root: root)
        if isGreenExecutionEvidence(at: url, relativePath: resolved) {
          savedEvidencePaths.insert(resolved)
        }
      }

      var additionalIssues: [String] = []
      let isStandaloneTyped = definition.sourceClasses.contains(
        where: \.isStandaloneTypedDefinition)
      if isStandaloneTyped && definition.statusOrdinal == 3 && executablePaths.isEmpty {
        additionalIssues.append("status proven (st=3) requires a resolvable executable proof")
      }
      if isStandaloneTyped && definition.statusOrdinal == 3 && savedEvidencePaths.isEmpty {
        additionalIssues.append("status proven (st=3) requires saved green execution evidence")
      }

      return definition.record(
        resolvedExecutableProofPaths: Array(executablePaths),
        savedEvidencePaths: Array(savedEvidencePaths),
        additionalIssues: additionalIssues
      )
    }.sorted {
      if $0.projectName != $1.projectName {
        return localizedLessThan($0.projectName, $1.projectName)
      }
      return localizedLessThan($0.id, $1.id)
    }
  }

  private func makeProjectRecords(
    identities: [String: ProjectIdentity],
    definitions: [CUJDefinitionRecord]
  ) -> [CUJProjectRecord] {
    let grouped = Dictionary(grouping: definitions, by: \.projectKey)
    return identities.values.map { identity in
      let directDefinitions = grouped[identity.key] ?? []
      let directIDs = Set(directDefinitions.map(\.id))
      let linkedDefinitions = linkedDefinitions(
        for: identity,
        identities: identities,
        definitions: definitions
      ).filter { !directIDs.contains($0.id) }
      let projectDefinitions = directDefinitions + linkedDefinitions
      return CUJProjectRecord(
        key: identity.key,
        name: identity.name,
        scope: identity.scope,
        homePath: identity.homePath,
        owner: identity.owner,
        directDefinitionIDs: directDefinitions.map(\.id).sorted(by: localizedLessThan),
        linkedDefinitionIDs: linkedDefinitions.map(\.id).sorted(by: localizedLessThan),
        definitionIDs: projectDefinitions.map(\.id).sorted(by: localizedLessThan),
        standaloneTypedDefinitionCount: projectDefinitions.filter {
          $0.sourceClasses.contains(where: \.isStandaloneTypedDefinition)
        }.count,
        matrixDefinitionCount: projectDefinitions.filter {
          $0.sourceClasses.contains(.coverageMatrix)
        }.count,
        legacyDefinitionCount: projectDefinitions.filter {
          $0.sourceClasses.contains(where: \.isLegacyDefinition)
        }.count,
        proofBoundDefinitionCount: projectDefinitions.filter(\.proofBound).count,
        provenDefinitionCount: projectDefinitions.filter(\.isProven).count,
        structuralIssueCount: projectDefinitions.reduce(0) { $0 + $1.structuralIssues.count }
      )
    }.sorted {
      if $0.scope != $1.scope { return $0.scope.rawValue < $1.scope.rawValue }
      if $0.name != $1.name { return localizedLessThan($0.name, $1.name) }
      return localizedLessThan($0.homePath, $1.homePath)
    }
  }

  private func linkedDefinitions(
    for identity: ProjectIdentity,
    identities: [String: ProjectIdentity],
    definitions: [CUJDefinitionRecord]
  ) -> [CUJDefinitionRecord] {
    guard identity.scope == .canonicalProductLine else { return [] }
    let normalizedName = normalizeProjectName(identity.name)
    var linked = definitions.filter { definition in
      guard normalizeProjectName(definition.projectName) == normalizedName,
        let sourceIdentity = identities[definition.projectKey]
      else { return false }
      return sourceIdentity.scope == .canonicalProductLine
        || sourceIdentity.scope == .client
        || sourceIdentity.scope == .implementationProject
    }

    let pathComponents = identity.homePath.split(separator: "/").map(String.init)
    if let clientIndex = pathComponents.firstIndex(of: "clients"),
      clientIndex + 1 < pathComponents.count
    {
      let clientOwner = "clients/\(pathComponents[clientIndex + 1])"
      let clientProductHomes = identities.values.filter {
        $0.scope == .canonicalProductLine && $0.owner == clientOwner
      }
      if clientProductHomes.count == 1 {
        linked.append(
          contentsOf: definitions.filter { definition in
            identities[definition.projectKey]?.owner == clientOwner
          })
      }
    }

    var seen: Set<String> = []
    return linked.filter { seen.insert("\($0.projectKey)|\($0.id)").inserted }
  }

  private func makeImplementationProjects(
    from inventory: OwnedSurfaceInventoryResult,
    projects: [CUJProjectRecord],
    root: URL
  ) -> [CUJImplementationProjectRecord] {
    let activeSurfaces = inventory.surfaces.filter { $0.ownershipScope == .activeOwned }
    let grouped = Dictionary(grouping: activeSurfaces) { surface in
      implementationHome(for: surface, root: root)
    }
    let definitionIDsByProject = Dictionary(
      uniqueKeysWithValues: projects.map { ($0.key, $0.definitionIDs) }
    )
    let projectsByNormalizedName = Dictionary(grouping: projects) { normalizeProjectName($0.name) }

    return grouped.map { homePath, surfaces in
      var mappedKeys: Set<String> = []
      for project in projects
      where pathContains(homePath, project.homePath) || pathContains(project.homePath, homePath) {
        mappedKeys.insert(project.key)
      }
      let productName = normalizeProjectName(surfaces.first?.productLine ?? "")
      if let candidates = projectsByNormalizedName[productName], candidates.count == 1,
        let candidate = candidates.first
      {
        mappedKeys.insert(candidate.key)
      }
      let definitionIDs = mappedKeys.flatMap { definitionIDsByProject[$0] ?? [] }
      return CUJImplementationProjectRecord(
        homePath: homePath,
        owner: surfaces.compactMap(\.owner).first,
        domain: surfaces.first?.domain ?? "unclassified",
        productLine: surfaces.first?.productLine ?? "unclassified",
        surfaceKinds: Array(Set(surfaces.map(\.kind))).sorted { $0.rawValue < $1.rawValue },
        surfacePaths: surfaces.map { relativePath($0.path, root: root) }.sorted(
          by: localizedLessThan),
        mappedProjectKeys: mappedKeys.sorted(by: localizedLessThan),
        definitionIDs: Array(Set(definitionIDs)).sorted(by: localizedLessThan)
      )
    }.sorted { localizedLessThan($0.homePath, $1.homePath) }
  }

  private func makeSummary(
    projects: [CUJProjectRecord],
    implementationProjects: [CUJImplementationProjectRecord],
    definitions: [CUJDefinitionRecord],
    artifacts: [CUJArtifactRecord],
    activeOwnedSurfaceCount: Int
  ) -> CUJPortfolioAuditSummary {
    var summary = CUJPortfolioAuditSummary()
    summary.artifactCount = artifacts.count
    summary.uniqueDefinitionCount = definitions.count
    summary.standaloneTypedDefinitionCount =
      definitions.filter {
        $0.sourceClasses.contains(where: \.isStandaloneTypedDefinition)
      }.count
    summary.matrixDefinitionCount =
      definitions.filter {
        $0.sourceClasses.contains(.coverageMatrix)
      }.count
    summary.legacyDefinitionCount =
      definitions.filter {
        $0.sourceClasses.contains(where: \.isLegacyDefinition)
      }.count
    summary.proofBoundDefinitionCount = definitions.filter(\.proofBound).count
    summary.executableBoundDefinitionCount =
      definitions.filter {
        !$0.resolvedExecutableProofPaths.isEmpty
      }.count
    summary.evidenceBackedDefinitionCount =
      definitions.filter {
        !$0.savedEvidencePaths.isEmpty
      }.count
    summary.unboundDefinitionCount = definitions.count - summary.proofBoundDefinitionCount
    summary.provenDefinitionCount = definitions.filter(\.isProven).count
    summary.invalidProvenClaimCount =
      definitions.filter {
        $0.isStandaloneTypedDefinition && $0.statusOrdinal == 3 && !$0.isProven
      }.count
    summary.structurallyInvalidDefinitionCount =
      definitions.filter {
        !$0.structuralIssues.isEmpty
      }.count
    let canonicalProjects = projects.filter { $0.scope == .canonicalProductLine }
    summary.canonicalProductHomeCount = canonicalProjects.count
    summary.canonicalProductHomesWithDirectDefinitions =
      canonicalProjects.filter {
        !$0.directDefinitionIDs.isEmpty
      }.count
    summary.canonicalProductHomesWithLinkedOnlyDefinitions =
      canonicalProjects.filter {
        $0.directDefinitionIDs.isEmpty && !$0.linkedDefinitionIDs.isEmpty
      }.count
    summary.canonicalProductHomesWithDefinitions =
      canonicalProjects.filter {
        !$0.definitionIDs.isEmpty
      }.count
    summary.canonicalProductHomesWithoutDefinitions =
      summary.canonicalProductHomeCount - summary.canonicalProductHomesWithDefinitions
    summary.activeOwnedSurfaceCount = activeOwnedSurfaceCount
    summary.activeOwnedImplementationProjectCount = implementationProjects.count
    summary.activeOwnedImplementationProjectsWithCUJs =
      implementationProjects.filter {
        !$0.definitionIDs.isEmpty
      }.count
    summary.activeOwnedImplementationProjectsWithoutCUJs =
      summary.activeOwnedImplementationProjectCount
      - summary.activeOwnedImplementationProjectsWithCUJs
    for artifact in artifacts {
      summary.byArtifactClass[artifact.artifactClass.rawValue, default: 0] += 1
    }
    for project in projects {
      summary.byProjectScope[project.scope.rawValue, default: 0] += 1
    }
    return summary
  }

  private func individualDefinition(
    object: [String: Any],
    project: ProjectIdentity,
    sourceClass: CUJArtifactClass,
    sourcePath: String
  ) -> DefinitionCandidate {
    let isCompact = isCompactCUJDefinition(object)
    let id =
      string(object[isCompact ? "i" : "slug"])
      ?? URL(fileURLWithPath: sourcePath).deletingPathExtension().lastPathComponent
    let title = string(object[isCompact ? "t" : "title"]) ?? id
    let statusOrdinal =
      integer(object[isCompact ? "st" : "statusOrdinal"])
      ?? statusOrdinal(from: string(object["status"]))
    let proofArray = object[isCompact ? "ap" : "automatedProofs"] as? [Any] ?? []
    let proofReferences = declaredProofReferences(from: proofArray, sourcePath: sourcePath)
    var issues: [String] = []
    if isCompact {
      let requiredKeys = ["i", "t", "s", "c", "k", "st", "a", "g", "sg", "cs"]
      for key in requiredKeys where object[key] == nil {
        issues.append("missing compact CUJ key '\(key)'")
      }
      if integer(object["k"]) != 1 {
        issues.append("compact CUJ path kind 'k' must be 1")
      }
      if (object["sg"] as? [Any])?.isEmpty != false {
        issues.append("compact CUJ requires at least one step in 'sg'")
      }
      if statusOrdinal == 3 && proofArray.isEmpty {
        issues.append("status proven (st=3) requires non-empty automated proofs in 'ap'")
      }
      if statusOrdinal == 3 && object["lP"] == nil {
        issues.append("status proven (st=3) requires last-proven chronon 'lP'")
      }
    }
    return DefinitionCandidate(
      id: id,
      title: title,
      project: project,
      sourceClass: sourceClass,
      sourcePath: sourcePath,
      statusOrdinal: statusOrdinal,
      declaredProofReferenceCount: proofArray.count,
      declaredProofReferences: proofReferences,
      lastProvenAtChrononID: integer(object[isCompact ? "lP" : "lastProvenAtChrononID"]),
      evidencePaths: [],
      structuralIssues: issues
    )
  }

  private func legacyJSONDefinitions(
    journeys: [[String: Any]],
    project: ProjectIdentity,
    sourcePath: String
  ) -> [DefinitionCandidate] {
    journeys.enumerated().map { index, journey in
      let id =
        string(journey["cujID"]) ?? string(journey["id"])
        ?? "cuj-\(slugify(project.name))-\(index + 1)"
      let steps =
        journey["steps"] as? [Any] ?? journey["flow"] as? [Any]
        ?? journey["acceptanceSteps"] as? [Any] ?? []
      var issues: [String] = []
      if steps.isEmpty {
        issues.append("legacy JSON CUJ requires at least one step")
      }
      var proofCount = (journey["automatedProofs"] as? [Any])?.count ?? 0
      if string(journey["verification"]) == "automated" { proofCount += 1 }
      let proofReferences = declaredProofReferences(
        from: journey["automatedProofs"] as? [Any] ?? [],
        sourcePath: sourcePath
      )
      return DefinitionCandidate(
        id: id,
        title: string(journey["title"]) ?? string(journey["journey"]) ?? id,
        project: project,
        sourceClass: .legacyJSONDefinition,
        sourcePath: sourcePath,
        statusOrdinal: nil,
        declaredProofReferenceCount: proofCount,
        declaredProofReferences: proofReferences,
        lastProvenAtChrononID: nil,
        evidencePaths: [],
        structuralIssues: issues
      )
    }
  }

  private func legacySingleDefinition(
    object: [String: Any],
    project: ProjectIdentity,
    sourcePath: String
  ) -> DefinitionCandidate {
    let id =
      string(object["slug"]) ?? string(object["id"])
      ?? URL(fileURLWithPath: sourcePath).deletingPathExtension().lastPathComponent
    let desiredSteps = legacyFlow(in: object)
    var issues: [String] = []
    if desiredSteps.isEmpty { issues.append("legacy JSON CUJ requires a non-empty journey flow") }
    return DefinitionCandidate(
      id: id,
      title: string(object["title"]) ?? id,
      project: project,
      sourceClass: .legacyJSONDefinition,
      sourcePath: sourcePath,
      statusOrdinal: statusOrdinal(from: string(object["status"])),
      declaredProofReferenceCount: (object["automatedProofs"] as? [Any])?.count ?? 0,
      declaredProofReferences: declaredProofReferences(
        from: object["automatedProofs"] as? [Any] ?? [],
        sourcePath: sourcePath
      ),
      lastProvenAtChrononID: integer(object["lastProvenAtChrononID"]),
      evidencePaths: [],
      structuralIssues: issues
    )
  }

  private func matrixDefinitions(
    object: [String: Any],
    project: ProjectIdentity,
    sourcePath: String
  ) -> [DefinitionCandidate] {
    guard let rows = object["cujs"] as? [[String: Any]] else { return [] }
    return rows.enumerated().map { index, row in
      let id = string(row["id"]) ?? "cuj-\(slugify(project.name))-matrix-\(index + 1)"
      var evidence: [String] = []
      var proofCount = 0
      if let receiptPath = string(row["receiptPath"]), !receiptPath.isEmpty {
        evidence.append(receiptPath)
        proofCount += 1
      }
      if let currentEvidence = string(row["currentEvidence"]), !currentEvidence.isEmpty {
        proofCount += 1
      }
      var issues: [String] = []
      if (row["acceptanceSteps"] as? [Any])?.isEmpty != false {
        issues.append("coverage-matrix CUJ requires at least one acceptance step")
      }
      return DefinitionCandidate(
        id: id,
        title: string(row["title"]) ?? id,
        project: project,
        sourceClass: .coverageMatrix,
        sourcePath: sourcePath,
        statusOrdinal: statusOrdinal(fromVerdict: string(row["latestVerdict"])),
        declaredProofReferenceCount: proofCount,
        declaredProofReferences: [],
        lastProvenAtChrononID: nil,
        evidencePaths: evidence,
        structuralIssues: issues
      )
    }
  }

  private func markdownDefinitions(
    text: String,
    url: URL,
    project: ProjectIdentity,
    sourceClass: CUJArtifactClass,
    sourcePath: String
  ) -> [DefinitionCandidate] {
    let lines = text.components(separatedBy: .newlines)
    var found: [(id: String, title: String)] = []
    for line in lines {
      let heading = line.trimmingCharacters(in: .whitespaces)
      guard heading.hasPrefix("#") else { continue }
      let body = heading.drop(while: { $0 == "#" || $0 == " " })
      let words = body.split(separator: " ", omittingEmptySubsequences: true)
      guard let first = words.first else { continue }
      let token = first.trimmingCharacters(in: CharacterSet(charactersIn: ":-"))
      if token.uppercased().hasPrefix("CUJ-") {
        let title = words.dropFirst().joined(separator: " ")
          .trimmingCharacters(in: CharacterSet(charactersIn: " -:"))
        found.append((String(token), title.isEmpty ? String(token) : title))
      }
    }

    if found.isEmpty, sourceClass == .doccDefinition,
      url.lastPathComponent.lowercased() != "index.md",
      let referencedID = firstCUJSlug(in: text)
    {
      found.append((referencedID, firstMarkdownHeading(in: lines) ?? referencedID))
    }

    if found.isEmpty, sourceClass == .doccDefinition {
      let primaryHeadings = lines.compactMap({ line -> String? in
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("##") || trimmed.hasPrefix("###") else { return nil }
        let body = trimmed.drop(while: { $0 == "#" || $0 == " " })
        let lowerBody = body.lowercased()
        return lowerBody.contains("cuj") && !lowerBody.contains("cujs") ? String(body) : nil
      })
      if !primaryHeadings.isEmpty {
        found = primaryHeadings.map { heading in
          let qualifier = heading.replacingOccurrences(
            of: "CUJ", with: "", options: .caseInsensitive)
          return (
            "cuj-\(slugify(project.name))-\(slugify(qualifier.isEmpty ? "primary" : qualifier))",
            heading
          )
        }
      }
    }

    if found.isEmpty, sourceClass == .legacyMarkdownDefinition {
      let parentSlug = url.deletingLastPathComponent().lastPathComponent
      found.append(("cuj-\(slugify(parentSlug))", firstMarkdownHeading(in: lines) ?? parentSlug))
    }

    let proofCount = markdownDeclaredProofCount(text)
    return found.map { item in
      DefinitionCandidate(
        id: item.id,
        title: item.title,
        project: project,
        sourceClass: sourceClass,
        sourcePath: sourcePath,
        statusOrdinal: nil,
        declaredProofReferenceCount: proofCount,
        declaredProofReferences: [],
        lastProvenAtChrononID: nil,
        evidencePaths: [],
        structuralIssues: []
      )
    }
  }

  private func projectIdentity(forProductHome url: URL, root: URL) -> ProjectIdentity {
    let homePath = relativePath(url, root: root)
    return ProjectIdentity(
      key: "canonical-product-line:\(homePath)",
      name: url.lastPathComponent,
      scope: .canonicalProductLine,
      homePath: homePath,
      owner: inferOwner(from: url.pathComponents)
    )
  }

  private func projectIdentity(for url: URL, root: URL) -> ProjectIdentity {
    let components = url.standardizedFileURL.pathComponents
    if let index = components.lastIndex(of: "product-lines"), index + 1 < components.count {
      return identity(
        scope: .canonicalProductLine,
        components: components,
        through: index + 1,
        root: root
      )
    }
    if let index = components.firstIndex(of: "clients"), index + 1 < components.count {
      return identity(scope: .client, components: components, through: index + 1, root: root)
    }
    if let formsIndex = components.lastIndex(of: "forms"), formsIndex + 1 < components.count,
      components.contains("harnesses")
    {
      return identity(
        scope: .harnessForm, components: components, through: formsIndex + 1, root: root)
    }
    if let index = components.lastIndex(of: "roles"), index + 1 < components.count {
      return identity(scope: .role, components: components, through: index + 1, root: root)
    }
    if let index = components.lastIndex(of: "workstreams"), index + 2 < components.count,
      components[index + 1] == "instances"
    {
      let instanceIndex = min(index + 3, components.count - 2)
      return identity(scope: .workflow, components: components, through: instanceIndex, root: root)
    }
    if let index = components.lastIndex(of: "workstream"), components.indices.contains(index + 1) {
      let through = min(index + 3, components.count - 2)
      return identity(scope: .workflow, components: components, through: through, root: root)
    }
    if let index = components.lastIndex(of: "proving-grounds"), index + 1 < components.count {
      return identity(
        scope: .implementationProject,
        components: components,
        through: index + 1,
        root: root
      )
    }
    if let index = components.lastIndex(of: "cujs"), index + 1 < components.count - 1 {
      return identity(
        scope: .operatorJourneySpace,
        components: components,
        through: index + 1,
        root: root
      )
    }
    if let index = components.lastIndex(of: "demo-apps"), index + 1 < components.count {
      return identity(
        scope: .implementationProject,
        components: components,
        through: index + 1,
        root: root
      )
    }
    if let index = components.lastIndex(of: "apps"), index + 1 < components.count {
      return identity(
        scope: .implementationProject,
        components: components,
        through: index + 1,
        root: root
      )
    }
    if let index = components.lastIndex(of: "spm"), index + 1 < components.count {
      return identity(
        scope: .implementationProject,
        components: components,
        through: index + 1,
        root: root
      )
    }
    if let index = components.lastIndex(where: { $0.hasSuffix(".app") }),
      index < components.count - 1
    {
      return identity(
        scope: .implementationProject,
        components: components,
        through: index,
        root: root
      )
    }
    if let index = components.lastIndex(of: "cujs"), index > 0 {
      return identity(
        scope: .other,
        components: components,
        through: index - 1,
        root: root
      )
    }
    let parent = url.deletingLastPathComponent()
    let homePath = relativePath(parent, root: root)
    return ProjectIdentity(
      key: "other:\(homePath)",
      name: parent.lastPathComponent,
      scope: .other,
      homePath: homePath,
      owner: inferOwner(from: components)
    )
  }

  private func identity(
    scope: CUJProjectScope,
    components: [String],
    through index: Int,
    root: URL
  ) -> ProjectIdentity {
    let homeURL = URL(fileURLWithPath: NSString.path(withComponents: Array(components[...index])))
    let homePath = relativePath(homeURL, root: root)
    return ProjectIdentity(
      key: "\(scope.rawValue):\(homePath)",
      name: components[index],
      scope: scope,
      homePath: homePath,
      owner: inferOwner(from: components)
    )
  }

  private func implementationHome(for surface: OwnedSurfaceRecord, root: URL) -> String {
    let url = URL(fileURLWithPath: surface.path)
    switch surface.kind {
    case .swiftPackage, .appleProjectYML, .appleProjectPKL:
      return relativePath(url.deletingLastPathComponent(), root: root)
    case .xcodeProject, .xcodeWorkspace:
      return relativePath(url.deletingLastPathComponent(), root: root)
    }
  }

  private func shouldSkipDirectory(_ url: URL) -> Bool {
    Self.skippedDirectoryNames.contains(url.lastPathComponent)
  }

  private func isJSONCUJCandidate(lowerPath: String) -> Bool {
    lowerPath.contains("cuj") || lowerPath.contains("critical-user-journey")
  }

  private func isMarkdownCUJCandidate(lowerPath: String) -> Bool {
    lowerPath.hasSuffix("/cuj.md") || lowerPath.contains("/cuj.docc/")
  }

  private func isTestProofCandidate(lowerPath: String, lowerName: String) -> Bool {
    let isTestPath = lowerPath.contains("/tests/") || lowerPath.contains("/test/")
    return isTestPath
      && (lowerPath.contains("/cuj-")
        || lowerName.contains("cuj")
        || lowerName.contains("criticaluserjourney"))
  }

  private func isSchemaFixture(path: String) -> Bool {
    (path.contains("/fixtures/") || path.contains("/templates/"))
      && (path.contains("cuj") || path.contains("critical-user-journey"))
  }

  private func supportingArtifactClass(for path: String) -> CUJArtifactClass? {
    if path.contains("/tests/") && path.contains("/resources/") {
      return .testFixture
    }
    if path.contains("cuj-coverage-matrix") || path.contains("/cuj-receipts/")
      || path.contains("cuj-test-coverage") || path.contains("cuj-state-coverage")
      || path.hasSuffix(".cuj.json") || path.hasSuffix(".cuj.su.json")
    {
      return nil
    }
    if path.hasSuffix(".beads-issue.json") || path.contains("/beads/") {
      return .beadReference
    }
    if path.hasSuffix(".schema.json") || path.contains("/schemas/")
      || path.hasSuffix("schema-catalog.family.descriptor.json")
    {
      return .schemaDefinition
    }
    if path.contains("/foundry/audit/") { return .auditReceipt }
    if path.contains("proving-ground") || path.contains("/test-harnesses/") {
      return .provingGroundProof
    }
    if path.contains("launch-review-packet") || path.contains("modern-composition-gate") {
      return .releaseEvidence
    }
    if path.contains("role-surface-manifest") { return .roleSupport }
    if path.contains("/workflows/") || path.contains("/workstreams/") || path.contains(".workflow")
      || path.contains("cuj.gate-set") || path.contains("cuj.formula")
    {
      return .workflowSupport
    }
    return nil
  }

  private func isCoverageMatrix(object: [String: Any], path: String) -> Bool {
    path.contains("cuj-coverage-matrix")
      || string(object["kind"]) == "cuj-coverage-matrix"
      || object["CUJCoverageMatrixModel"] != nil
  }

  private func isJourneyTree(object: [String: Any], path: String) -> Bool {
    path.contains("cuj-tree") || object["CujTree"] != nil
  }

  private func isCoverageReceipt(path: String) -> Bool {
    path.contains("/cuj-receipts/") && path.contains("scenario-receipt")
  }

  private func isCoverageManifest(path: String) -> Bool {
    path.contains("cuj-test-coverage") || path.contains("cuj-state-coverage")
  }

  private func isCompactCUJDefinition(_ object: [String: Any]) -> Bool {
    object["i"] != nil && object["t"] != nil && object["g"] != nil && object["sg"] != nil
  }

  private func isLongFormCUJDefinition(_ object: [String: Any]) -> Bool {
    object["slug"] != nil && object["title"] != nil && object["goal"] != nil
      && object["steps"] != nil
  }

  private func isLegacySingleCUJDefinition(_ object: [String: Any]) -> Bool {
    object["CUJModel"] != nil && object["slug"] != nil && object["title"] != nil
      && (object["goal"] != nil || object["userJourney"] != nil || object["journeys"] != nil)
  }

  private func legacyFlow(in object: [String: Any]) -> [Any] {
    if let flow = object["desiredFlow"] as? [Any] { return flow }
    if let flow = object["currentBlockingFlow"] as? [Any] { return flow }
    if let flow = object["steps"] as? [Any] { return flow }
    if let flow = object["flow"] as? [Any] { return flow }
    if let userJourney = object["userJourney"] as? [String: Any] {
      if let flow = userJourney["desiredFlow"] as? [Any] { return flow }
      if let flow = userJourney["currentBlockingFlow"] as? [Any] { return flow }
      if let flow = userJourney["steps"] as? [Any] { return flow }
    }
    if let journeys = object["journeys"] as? [[String: Any]] {
      return journeys.flatMap { $0["steps"] as? [Any] ?? [] }
    }
    return []
  }

  private func typedDefinitionClass(for path: String) -> CUJArtifactClass {
    if path.contains("/product-lines/") { return .typedProductDefinition }
    if path.contains("/clients/") { return .typedClientDefinition }
    if path.contains("/harnesses/") { return .typedHarnessDefinition }
    if path.contains("/roles/") { return .typedRoleDefinition }
    if path.contains("/workstream/") || path.contains("/workflows/") {
      return .typedWorkflowDefinition
    }
    if path.contains("/operators/") || path.contains("/kura-spaces/cujs/") {
      return .typedOperatorDefinition
    }
    return .typedImplementationDefinition
  }

  private func declaredProofReferences(
    from values: [Any],
    sourcePath: String
  ) -> [CUJDeclaredProofReference] {
    values.compactMap { value in
      guard let proof = value as? [String: Any] else { return nil }
      let link = proof["l"] as? [String: Any]
      let linkTargets = link?["tg"] as? [[String: Any]] ?? []
      let legacyTargets = proof["tg"] as? [[String: Any]] ?? []
      let target = (linkTargets + legacyTargets).first
      let packagePath =
        string(target?["vr"])
        ?? string(target?["v"])
        ?? string(proof["packagePath"])
      let testTypeName = string(proof["tN"]) ?? string(proof["testTypeName"])
      let testMethodName = string(proof["mN"]) ?? string(proof["testMethodName"])
      let claim = string(proof["c"]) ?? string(proof["claim"]) ?? string(proof["t"])
      let format =
        testTypeName != nil || testMethodName != nil
        ? "cuj-test-proof-ref-v0.1.0" : "legacy-proof-ref"
      return CUJDeclaredProofReference(
        claim: claim,
        packagePath: packagePath,
        testTypeName: testTypeName,
        testMethodName: testMethodName,
        tag: string(proof["tg"]),
        declarationPath: sourcePath,
        format: format
      )
    }
  }

  private func resolveExecutableProof(
    _ reference: CUJDeclaredProofReference,
    root: URL
  ) -> [String] {
    guard let packagePath = reference.packagePath else { return [] }
    let candidate = resolveSubstratePath(packagePath, root: root)
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: candidate.path, isDirectory: &isDirectory) else {
      return []
    }

    if !isDirectory.boolValue {
      guard candidate.pathExtension.lowercased() == "swift",
        proofFile(candidate, matches: reference)
      else { return [] }
      return [relativePath(candidate, root: root)]
    }

    let keys: Set<URLResourceKey> = [.isDirectoryKey, .isRegularFileKey]
    guard
      let enumerator = fileManager.enumerator(
        at: candidate,
        includingPropertiesForKeys: Array(keys),
        options: [.skipsHiddenFiles],
        errorHandler: { _, _ in true }
      )
    else { return [] }

    var matches: [String] = []
    while let url = enumerator.nextObject() as? URL {
      let values = try? url.resourceValues(forKeys: keys)
      if values?.isDirectory == true {
        if shouldSkipDirectory(url) { enumerator.skipDescendants() }
        continue
      }
      guard values?.isRegularFile == true,
        url.pathExtension.lowercased() == "swift",
        url.path.lowercased().contains("/test"),
        proofFile(url, matches: reference)
      else { continue }
      matches.append(relativePath(url, root: root))
    }
    return matches
  }

  private func proofFile(_ url: URL, matches reference: CUJDeclaredProofReference) -> Bool {
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { return false }
    let terms = [reference.testTypeName, reference.testMethodName]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    if terms.isEmpty {
      return url.pathExtension.lowercased() == "swift"
    }
    return terms.allSatisfy { text.contains($0) }
  }

  private func resolveEvidencePath(
    _ path: String,
    sourcePaths: [String],
    root: URL
  ) -> String? {
    guard !path.contains("://") else { return nil }
    let direct = resolveSubstratePath(path, root: root)
    if fileManager.fileExists(atPath: direct.path) {
      return relativePath(direct, root: root)
    }
    for sourcePath in sourcePaths {
      let sourceURL = resolveSubstratePath(sourcePath, root: root)
      let relative = sourceURL.deletingLastPathComponent().appendingPathComponent(path)
        .standardizedFileURL
      if fileManager.fileExists(atPath: relative.path) {
        return relativePath(relative, root: root)
      }
    }
    return nil
  }

  private func isGreenExecutionEvidence(at url: URL, relativePath: String) -> Bool {
    guard let data = try? Data(contentsOf: url),
      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return false }
    return isGreenExecutionEvidence(object, path: relativePath)
  }

  private func isGreenExecutionEvidence(_ object: [String: Any], path: String) -> Bool {
    let lowerPath = path.lowercased()
    guard lowerPath.contains("receipt") else { return false }

    let greenValues: Set<String> = ["green", "pass", "passed", "success", "succeeded"]
    let nonGreenValues: Set<String> = [
      "blocked", "error", "fail", "failed", "partial", "pending", "skipped",
    ]
    let outcomes = ["verdict", "status", "result", "overallStatus", "testResult"]
      .compactMap { string(object[$0])?.lowercased() }
    if outcomes.contains(where: nonGreenValues.contains) { return false }
    if outcomes.contains(where: greenValues.contains) { return true }
    if object["success"] as? Bool == true { return true }
    if integer(object["exitCode"]) == 0, object["exitCode"] != nil { return true }
    if integer(object["failedCheckCount"]) == 0,
      (integer(object["checkCount"]) ?? integer(object["totalCheckCount"]) ?? 0) > 0
    {
      return true
    }
    return false
  }

  private func resolveSubstratePath(_ path: String, root: URL) -> URL {
    if path.hasPrefix("/") { return URL(fileURLWithPath: path).standardizedFileURL }
    let substratePrefix = "private/universal/substrate/"
    if path == "private/universal/substrate" { return root.standardizedFileURL }
    if path.hasPrefix(substratePrefix) {
      return root.appendingPathComponent(String(path.dropFirst(substratePrefix.count)))
        .standardizedFileURL
    }
    return root.appendingPathComponent(path).standardizedFileURL
  }

  private func proofMatches(_ definitionID: String, proof: ProofSource) -> Bool {
    let needle = definitionID.lowercased()
    let path = proof.path.lowercased()
    let text = proof.searchableText.lowercased()
    if path.contains(needle) || text.contains(needle) { return true }
    let compactNeedle = needle.filter { $0.isLetter || $0.isNumber }
    guard compactNeedle.count >= 5 else { return false }
    return path.filter { $0.isLetter || $0.isNumber }.contains(compactNeedle)
      || text.filter { $0.isLetter || $0.isNumber }.contains(compactNeedle)
  }

  private func firstCUJSlug(in text: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: #"cuj-[a-z0-9][a-z0-9-]+"#) else {
      return nil
    }
    let range = NSRange(text.startIndex..<text.endIndex, in: text.lowercased())
    let lower = text.lowercased()
    guard let match = regex.firstMatch(in: lower, range: range),
      let swiftRange = Range(match.range, in: lower)
    else { return nil }
    return String(lower[swiftRange])
  }

  private func firstMarkdownHeading(in lines: [String]) -> String? {
    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      guard trimmed.hasPrefix("#") else { continue }
      let heading = trimmed.drop(while: { $0 == "#" || $0 == " " })
      if !heading.isEmpty { return String(heading) }
    }
    return nil
  }

  private func markdownDeclaredProofCount(_ text: String) -> Int {
    let lower = text.lowercased()
    var count = 0
    for marker in ["automated proof", "test coverage", "scenario receipt", "proof command"] {
      if lower.contains(marker) { count += 1 }
    }
    return count
  }

  private func statusOrdinal(from value: String?) -> Int? {
    switch value?.lowercased() {
    case "modeled": return 1
    case "in-construction": return 2
    case "proven": return 3
    case "regressed": return 4
    case "deprecated": return 5
    default: return nil
    }
  }

  private func statusOrdinal(fromVerdict value: String?) -> Int? {
    switch value?.lowercased() {
    case "pass": return 3
    case "fail": return 4
    case "partial": return 2
    default: return 1
    }
  }

  private func string(_ value: Any?) -> String? {
    guard let value = value as? String else { return nil }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  private func integer(_ value: Any?) -> Int? {
    if let value = value as? Int { return value }
    if let value = value as? NSNumber { return value.intValue }
    return nil
  }

  private func inferOwner(from components: [String]) -> String? {
    for root in ["collectives", "clients", "operators", "collaborators", "maintainers"] {
      if let index = components.firstIndex(of: root), index + 1 < components.count {
        return root == "collectives" ? components[index + 1] : "\(root)/\(components[index + 1])"
      }
    }
    return nil
  }

  private func relativePath(_ url: URL, root: URL) -> String {
    relativePath(url.standardizedFileURL.path, root: root)
  }

  private func relativePath(_ path: String, root: URL) -> String {
    let rootPath = root.standardizedFileURL.path
    if path == rootPath { return "." }
    if path.hasPrefix(rootPath + "/") {
      return String(path.dropFirst(rootPath.count + 1))
    }
    return path
  }

  private func pathContains(_ lhs: String, _ rhs: String) -> Bool {
    lhs == rhs || lhs.hasPrefix(rhs + "/") || rhs.hasPrefix(lhs + "/")
  }

  private func normalizeProjectName(_ value: String) -> String {
    let base = value.split(separator: "@", maxSplits: 1).first.map(String.init) ?? value
    return slugify(base.replacingOccurrences(of: ".demo", with: ""))
  }

  private func projectPreference(_ project: ProjectIdentity) -> String {
    let scopeRank: Int
    switch project.scope {
    case .canonicalProductLine: scopeRank = 0
    case .client: scopeRank = 1
    case .harnessForm: scopeRank = 2
    case .role: scopeRank = 3
    case .implementationProject: scopeRank = project.homePath.contains("/apps/") ? 4 : 5
    case .workflow: scopeRank = 6
    case .operatorJourneySpace: scopeRank = 7
    case .other: scopeRank = 8
    }
    return String(format: "%02d-%@", scopeRank, project.homePath)
  }

  private func slugify(_ value: String) -> String {
    let scalars = value.lowercased().unicodeScalars.map { scalar -> Character in
      CharacterSet.alphanumerics.contains(scalar) ? Character(String(scalar)) : "-"
    }
    let collapsed = String(scalars).split(separator: "-", omittingEmptySubsequences: true)
    return collapsed.joined(separator: "-")
  }

  private func localizedLessThan(_ lhs: String, _ rhs: String) -> Bool {
    lhs.localizedStandardCompare(rhs) == .orderedAscending
  }

  private enum JSONInspectionError: Error {
    case notObject
  }

  private static let skippedDirectoryNames: Set<String> = [
    ".build",
    ".derived-data",
    ".git",
    ".swiftpm",
    "Carthage",
    "DerivedData",
    "Pods",
    "SourcePackages",
    "Vendor",
    "_recovered",
    "build",
    "dependency-checkout",
    "dependency-checkouts",
    "node_modules",
    "retired-agent-homes",
    "target",
    "vendor",
  ]
}

enum CUJPortfolioAuditRenderer {
  static func renderJSON(
    _ result: CUJPortfolioAuditResult,
    vaporizeVersion: String,
    scannedAt: Date = Date()
  ) throws -> Data {
    let receipt = CUJPortfolioAuditScanner().receipt(
      from: result,
      vaporizeVersion: vaporizeVersion,
      scannedAt: scannedAt
    )
    return try VaporInventoryRenderer.makeJSONEncoder().encode(receipt)
  }

  static func renderMarkdown(_ result: CUJPortfolioAuditResult) -> String {
    let summary = result.summary
    let zeroProductHomes = result.projects.filter {
      $0.scope == .canonicalProductLine && $0.definitionIDs.isEmpty
    }
    let linkedOnlyProductHomes = result.projects.filter {
      $0.scope == .canonicalProductLine && $0.directDefinitionIDs.isEmpty
        && !$0.linkedDefinitionIDs.isEmpty
    }
    let unbound = result.definitions.filter { !$0.proofBound }
    let invalid = result.definitions.filter { !$0.structuralIssues.isEmpty }

    var lines: [String] = []
    lines.append("# Substrate CUJ Portfolio Audit")
    lines.append("")
    lines.append("Scanned: `\(result.scannedPath)`")
    lines.append("")
    lines.append("## Portfolio Summary")
    lines.append("")
    lines.append("| Measure | Count |")
    lines.append("| --- | ---: |")
    lines.append("| CUJ artifacts, kept in separate semantic classes | \(summary.artifactCount) |")
    lines.append("| Unique journey definitions | \(summary.uniqueDefinitionCount) |")
    lines.append("| Standalone typed definitions | \(summary.standaloneTypedDefinitionCount) |")
    lines.append("| Matrix-defined journeys | \(summary.matrixDefinitionCount) |")
    lines.append(
      "| Legacy JSON, Markdown, or DocC definitions | \(summary.legacyDefinitionCount) |")
    lines.append(
      "| Definitions with any declared or matched proof binding | \(summary.proofBoundDefinitionCount) |"
    )
    lines.append(
      "| Definitions with a resolved executable proof | \(summary.executableBoundDefinitionCount) |"
    )
    lines.append(
      "| Definitions with saved execution evidence | \(summary.evidenceBackedDefinitionCount) |")
    lines.append("| Definitions without a proof binding | \(summary.unboundDefinitionCount) |")
    lines.append("| Strictly proven definitions | \(summary.provenDefinitionCount) |")
    lines.append("| Invalid proven claims | \(summary.invalidProvenClaimCount) |")
    lines.append(
      "| Structurally invalid definitions | \(summary.structurallyInvalidDefinitionCount) |")
    lines.append("")
    lines.append("## Canonical Product Homes")
    lines.append("")
    lines.append("- Homes discovered: \(summary.canonicalProductHomeCount)")
    lines.append(
      "- Homes with direct CUJ definitions: \(summary.canonicalProductHomesWithDirectDefinitions)")
    lines.append(
      "- Homes covered only by a unique owned-home link: \(summary.canonicalProductHomesWithLinkedOnlyDefinitions)"
    )
    lines.append(
      "- Homes with direct or linked definitions: \(summary.canonicalProductHomesWithDefinitions)")
    lines.append(
      "- Homes with no direct or linked definitions: \(summary.canonicalProductHomesWithoutDefinitions)"
    )
    lines.append("")
    if !linkedOnlyProductHomes.isEmpty {
      lines.append("### Linked-Only Product Homes")
      lines.append("")
      for project in linkedOnlyProductHomes {
        lines.append(
          "- `\(project.homePath)` -> \(project.linkedDefinitionIDs.count) definition(s)")
      }
      lines.append("")
    }
    if zeroProductHomes.isEmpty {
      lines.append("Every canonical product home has at least one CUJ definition.")
    } else {
      lines.append("### Uncovered Product Homes")
      lines.append("")
      for project in zeroProductHomes {
        lines.append("- `\(project.homePath)`")
      }
    }
    lines.append("")
    lines.append("## Active-Owned Implementation Coverage")
    lines.append("")
    lines.append("- Build surfaces: \(summary.activeOwnedSurfaceCount)")
    lines.append(
      "- Distinct implementation project directories: \(summary.activeOwnedImplementationProjectCount)"
    )
    lines.append(
      "- Projects with directly nested or uniquely name-mapped CUJs: \(summary.activeOwnedImplementationProjectsWithCUJs)"
    )
    lines.append(
      "- Projects without a mapped CUJ: \(summary.activeOwnedImplementationProjectsWithoutCUJs)")
    lines.append("")
    lines.append(
      "> Implementation coverage is a census, not a mandate that every schema package owns a founder-facing journey. Canonical product-home coverage is the product denominator; implementation coverage exposes unmapped code surfaces for triage."
    )
    lines.append("")
    lines.append("## Artifact Classes")
    lines.append("")
    lines.append("| Class | Files |")
    lines.append("| --- | ---: |")
    for entry in summary.byArtifactClass.sorted(by: { $0.key < $1.key }) {
      lines.append("| `\(entry.key)` | \(entry.value) |")
    }
    lines.append("")
    lines.append("## Definition Health")
    lines.append("")
    if invalid.isEmpty {
      lines.append("No recognized definition failed the audit's structural checks.")
    } else {
      lines.append("### Structural Issues")
      lines.append("")
      for definition in invalid.prefix(50) {
        lines.append(
          "- `\(definition.id)` in `\(definition.sourcePaths.first ?? "unknown")`: \(definition.structuralIssues.joined(separator: "; "))"
        )
      }
      if invalid.count > 50 { lines.append("- ... \(invalid.count - 50) more in the JSON receipt") }
    }
    lines.append("")
    if unbound.isEmpty {
      lines.append("Every definition has a declared or matched proof binding.")
    } else {
      lines.append("### Definitions Without Proof Bindings")
      lines.append("")
      for definition in unbound.prefix(60) {
        lines.append(
          "- `\(definition.id)` - \(definition.projectName) (`\(definition.sourcePaths.first ?? "unknown")`)"
        )
      }
      if unbound.count > 60 { lines.append("- ... \(unbound.count - 60) more in the JSON receipt") }
    }
    lines.append("")
    lines.append("## Method")
    lines.append("")
    lines.append(
      "The audit uses Vaporize's owned-surface scanner for active-owned build truth. It excludes generated, derived, dependency-checkout, and external-reference surfaces from the implementation denominator. It independently classifies standalone compact CUJ records, legacy JSON collections, Markdown and DocC definitions, coverage matrices, receipts, manifests, schema fixtures, journey trees, and Swift test proofs. These classes are not added together as if they were interchangeable proof."
    )
    return lines.joined(separator: "\n") + "\n"
  }
}
