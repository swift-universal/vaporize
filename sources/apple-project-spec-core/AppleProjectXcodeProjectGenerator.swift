import Foundation

public enum AppleProjectXcodeProjectGenerationError: Error, CustomStringConvertible {
  case noApplicationTargets
  case unsupportedTargetType(targetName: String, type: String?)
  case missingSourcePath(targetName: String, path: String)

  public var description: String {
    switch self {
    case .noApplicationTargets:
      return "AppleProjectSpec does not contain any application targets."
    case .unsupportedTargetType(let targetName, let type):
      return "Target \(targetName) has unsupported type \(type ?? "<nil>")."
    case .missingSourcePath(let targetName, let path):
      return "Target \(targetName) source path does not exist: \(path)"
    }
  }
}

public enum AppleProjectXcodeProjectGenerator {
  public static func generate(
    pklURL: URL,
    outputURL: URL,
    requestId: String
  ) async throws -> PklXcodeProjectGenerationReceipt {
    let spec = try await AppleProjectPklLoader.load(url: pklURL)
    return try generate(
      spec: spec,
      sourcePath: pklURL.path,
      sourceDirectory: pklURL.deletingLastPathComponent(),
      outputURL: outputURL,
      requestId: requestId
    )
  }

  public static func generate(
    spec: AppleProjectSpec,
    sourcePath: String,
    sourceDirectory: URL? = nil,
    outputURL: URL,
    requestId: String
  ) throws -> PklXcodeProjectGenerationReceipt {
    let projectURL = normalizedProjectURL(outputURL, projectName: spec.name)
    let projectDirectory = sourceDirectory?.standardizedFileURL
      ?? projectURL.deletingLastPathComponent().standardizedFileURL
    let rendered = try AppleProjectXcodeProjectRenderer.render(
      spec: spec,
      projectDirectory: projectDirectory
    )

    let fileManager = FileManager.default
    try fileManager.createDirectory(at: projectURL, withIntermediateDirectories: true)
    let workspaceURL = projectURL
      .appendingPathComponent("project.xcworkspace")
      .appendingPathComponent("contents.xcworkspacedata")
    try fileManager.createDirectory(
      at: workspaceURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    let pbxprojURL = projectURL.appendingPathComponent("project.pbxproj")
    let pbxprojData = Data(rendered.pbxproj.utf8)
    try pbxprojData.write(to: pbxprojURL)
    let workspaceData = Data(rendered.workspace.utf8)
    try workspaceData.write(to: workspaceURL)

    return PklXcodeProjectGenerationReceipt(
      pklPath: sourcePath,
      outputPath: projectURL.path,
      pbxprojPath: pbxprojURL.path,
      workspacePath: workspaceURL.path,
      requestId: requestId,
      projectName: spec.name,
      targetCount: rendered.targetNames.count,
      packageCount: spec.packages.count,
      schemeCount: spec.schemes.count,
      targetNames: rendered.targetNames,
      packageNames: spec.packages.keys.sorted(),
      sourceFileCount: rendered.sourceFileCount,
      resourceFileCount: rendered.resourceFileCount,
      generatedByteCount: pbxprojData.count + workspaceData.count,
      pklSignature: AppleProjectSpecParitySignature(spec: spec)
    )
  }

  private static func normalizedProjectURL(_ outputURL: URL, projectName: String) -> URL {
    let standardized = outputURL.standardizedFileURL
    if standardized.pathExtension == "xcodeproj" {
      return standardized
    }
    return standardized.appendingPathComponent("\(projectName).xcodeproj")
  }
}

public struct AppleRenderedXcodeProject: Equatable, Sendable {
  public var pbxproj: String
  public var workspace: String
  public var targetNames: [String]
  public var sourceFileCount: Int
  public var resourceFileCount: Int
}

public enum AppleProjectXcodeProjectRenderer {
  public static func render(
    spec: AppleProjectSpec,
    projectDirectory: URL
  ) throws -> AppleRenderedXcodeProject {
    let applicationTargets = spec.targets
      .filter { _, target in target.type == nil || target.type == "application" }
      .sorted { $0.key < $1.key }
    guard !applicationTargets.isEmpty else {
      if let first = spec.targets.sorted(by: { $0.key < $1.key }).first {
        throw AppleProjectXcodeProjectGenerationError.unsupportedTargetType(
          targetName: first.key,
          type: first.value.type
        )
      }
      throw AppleProjectXcodeProjectGenerationError.noApplicationTargets
    }

    let context = try RenderContext(
      spec: spec,
      applicationTargets: applicationTargets,
      projectDirectory: projectDirectory
    )
    return AppleRenderedXcodeProject(
      pbxproj: context.renderPBXProj(),
      workspace: context.renderWorkspace(),
      targetNames: context.targetRecords.map(\.name),
      sourceFileCount: context.fileRecords.filter(\.isSwiftSource).count,
      resourceFileCount: context.fileRecords.filter(\.isResource).count
    )
  }
}

private struct RenderContext {
  var spec: AppleProjectSpec
  var projectDirectory: URL
  var targetRecords: [TargetRecord]
  var fileRecords: [FileRecord]
  var packageRecords: [PackageRecord]
  var productRecords: [ProductRecord]
  var rootGroupID = stableID("root-group")
  var productsGroupID = stableID("products-group")
  var sourcesGroupID = stableID("sources-group")
  var packagesGroupID = stableID("packages-group")
  var projectID = stableID("project")
  var projectConfigListID = stableID("project-config-list")

  init(
    spec: AppleProjectSpec,
    applicationTargets: [(key: String, value: AppleProjectTarget)],
    projectDirectory: URL
  ) throws {
    self.spec = spec
    self.projectDirectory = projectDirectory.standardizedFileURL
    self.packageRecords = spec.packages.keys.sorted().compactMap { packageName in
      guard let package = spec.packages[packageName] else { return nil }
      return PackageRecord(
        name: packageName,
        package: package,
        id: stableID("package-\(packageName)"),
        groupFileID: stableID("package-group-file-\(packageName)")
      )
    }

    var targetRecords: [TargetRecord] = []
    var fileRecords: [FileRecord] = []
    var productRecords: [ProductRecord] = []

    for (targetName, target) in applicationTargets {
      let discoveredFiles = try Self.discoverFiles(
        targetName: targetName,
        target: target,
        projectDirectory: projectDirectory
      )
      let targetRecord = TargetRecord(
        name: targetName,
        target: target,
        productName: target.productName(defaultName: targetName),
        id: stableID("target-\(targetName)"),
        productFileID: stableID("product-file-\(targetName)"),
        sourcesPhaseID: stableID("sources-phase-\(targetName)"),
        resourcesPhaseID: discoveredFiles.contains(where: \.isResource) ? stableID("resources-phase-\(targetName)") : nil,
        frameworksPhaseID: (target.dependencies ?? []).contains(where: { $0.package != nil && $0.product != nil })
          ? stableID("frameworks-phase-\(targetName)")
          : nil,
        configListID: stableID("target-config-list-\(targetName)"),
        sourceGroupID: stableID("source-group-\(targetName)")
      )
      targetRecords.append(targetRecord)

      for file in discoveredFiles {
        fileRecords.append(
          FileRecord(
            targetName: targetName,
            sourceGroupID: targetRecord.sourceGroupID,
            relativePath: file.relativePath,
            displayName: URL(fileURLWithPath: file.relativePath).lastPathComponent,
            id: stableID("file-\(targetName)-\(file.relativePath)"),
            buildFileID: file.isBuildFile ? stableID("build-file-\(targetName)-\(file.relativePath)") : nil,
            kind: file.kind
          )
        )
      }

      for dependency in target.dependencies ?? [] {
        guard let package = dependency.package, let product = dependency.product else { continue }
        productRecords.append(
          ProductRecord(
            targetName: targetName,
            packageName: package,
            productName: product,
            id: stableID("package-product-\(targetName)-\(package)-\(product)"),
            buildFileID: stableID("package-product-build-file-\(targetName)-\(package)-\(product)")
          )
        )
      }
    }

    self.targetRecords = targetRecords
    self.fileRecords = fileRecords.sorted { lhs, rhs in
      if lhs.targetName != rhs.targetName { return lhs.targetName < rhs.targetName }
      return lhs.relativePath < rhs.relativePath
    }
    self.productRecords = productRecords.sorted { lhs, rhs in
      if lhs.targetName != rhs.targetName { return lhs.targetName < rhs.targetName }
      return lhs.productName < rhs.productName
    }
  }

  func renderPBXProj() -> String {
    var lines: [String] = [
      "// !$*UTF8*$!",
      "{",
      "\tarchiveVersion = 1;",
      "\tclasses = {",
      "\t};",
      "\tobjectVersion = 77;",
      "\tobjects = {",
      "",
    ]
    appendPBXBuildFiles(to: &lines)
    appendPBXFileReferences(to: &lines)
    appendPBXFrameworksBuildPhases(to: &lines)
    appendPBXGroups(to: &lines)
    appendPBXNativeTargets(to: &lines)
    appendPBXProject(to: &lines)
    appendPBXResourcesBuildPhases(to: &lines)
    appendPBXShellScriptBuildPhases(to: &lines)
    appendPBXSourcesBuildPhases(to: &lines)
    appendXCBuildConfigurations(to: &lines)
    appendXCConfigurationLists(to: &lines)
    appendXCLocalSwiftPackageReferences(to: &lines)
    appendXCSwiftPackageProductDependencies(to: &lines)
    lines.append("\t};")
    lines.append("\trootObject = \(projectID) /* Project object */;")
    lines.append("}")
    return lines.joined(separator: "\n") + "\n"
  }

  func renderWorkspace() -> String {
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <Workspace
       version = "1.0">
       <FileRef
          location = "self:">
       </FileRef>
    </Workspace>

    """
  }

  private func appendPBXBuildFiles(to lines: inout [String]) {
    let buildFiles = fileRecords.filter { $0.buildFileID != nil } + productRecords.map(FileRecord.product)
    guard !buildFiles.isEmpty else { return }
    lines.append("/* Begin PBXBuildFile section */")
    for file in buildFiles {
      guard let buildFileID = file.buildFileID else { continue }
      switch file.kind {
      case .packageProduct(let productID):
        lines.append("\t\t\(buildFileID) /* \(file.displayName) in Frameworks */ = {isa = PBXBuildFile; productRef = \(productID) /* \(file.displayName) */; };")
      case .swift:
        lines.append("\t\t\(buildFileID) /* \(file.displayName) in Sources */ = {isa = PBXBuildFile; fileRef = \(file.id) /* \(file.displayName) */; };")
      case .resource:
        lines.append("\t\t\(buildFileID) /* \(file.displayName) in Resources */ = {isa = PBXBuildFile; fileRef = \(file.id) /* \(file.displayName) */; };")
      case .infoPlist:
        break
      }
    }
    lines.append("/* End PBXBuildFile section */")
    lines.append("")
  }

  private func appendPBXFileReferences(to lines: inout [String]) {
    lines.append("/* Begin PBXFileReference section */")
    for target in targetRecords {
      lines.append("\t\t\(target.productFileID) /* \(target.productName).app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = \(pbxValue("\(target.productName).app")); sourceTree = BUILT_PRODUCTS_DIR; };")
    }
    for package in packageRecords {
      guard let path = package.package.path else { continue }
      lines.append("\t\t\(package.groupFileID) /* \(package.displayName) */ = {isa = PBXFileReference; lastKnownFileType = folder; name = \(pbxValue(package.displayName)); path = \(pbxValue(path)); sourceTree = SOURCE_ROOT; };")
    }
    for file in fileRecords {
      let fileType = file.kind.fileType.map { " lastKnownFileType = \($0);" } ?? ""
      lines.append("\t\t\(file.id) /* \(file.displayName) */ = {isa = PBXFileReference;\(fileType) path = \(pbxValue(file.relativePath)); sourceTree = \"<group>\"; };")
    }
    lines.append("/* End PBXFileReference section */")
    lines.append("")
  }

  private func appendPBXFrameworksBuildPhases(to lines: inout [String]) {
    let targets = targetRecords.filter { $0.frameworksPhaseID != nil }
    guard !targets.isEmpty else { return }
    lines.append("/* Begin PBXFrameworksBuildPhase section */")
    for target in targets {
      guard let frameworksPhaseID = target.frameworksPhaseID else { continue }
      lines.append("\t\t\(frameworksPhaseID) /* Frameworks */ = {")
      lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
      lines.append("\t\t\tbuildActionMask = 2147483647;")
      lines.append("\t\t\tfiles = (")
      for product in productRecords.filter({ $0.targetName == target.name }) {
        lines.append("\t\t\t\t\(product.buildFileID) /* \(product.productName) in Frameworks */,")
      }
      lines.append("\t\t\t);")
      lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
      lines.append("\t\t};")
    }
    lines.append("/* End PBXFrameworksBuildPhase section */")
    lines.append("")
  }

  private func appendPBXGroups(to lines: inout [String]) {
    lines.append("/* Begin PBXGroup section */")
    if !packageRecords.isEmpty {
      lines.append("\t\t\(packagesGroupID) /* Packages */ = {")
      lines.append("\t\t\tisa = PBXGroup;")
      lines.append("\t\t\tchildren = (")
      for package in packageRecords where package.package.path != nil {
        lines.append("\t\t\t\t\(package.groupFileID) /* \(package.displayName) */,")
      }
      lines.append("\t\t\t);")
      lines.append("\t\t\tname = Packages;")
      lines.append("\t\t\tsourceTree = \"<group>\";")
      lines.append("\t\t};")
    }
    lines.append("\t\t\(productsGroupID) /* Products */ = {")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    for target in targetRecords {
      lines.append("\t\t\t\t\(target.productFileID) /* \(target.productName).app */,")
    }
    lines.append("\t\t\t);")
    lines.append("\t\t\tname = Products;")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

    lines.append("\t\t\(rootGroupID) = {")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    if !packageRecords.isEmpty {
      lines.append("\t\t\t\t\(packagesGroupID) /* Packages */,")
    }
    lines.append("\t\t\t\t\(sourcesGroupID) /* Sources */,")
    lines.append("\t\t\t\t\(productsGroupID) /* Products */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

    lines.append("\t\t\(sourcesGroupID) /* Sources */ = {")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    for target in targetRecords {
      lines.append("\t\t\t\t\(target.sourceGroupID) /* \(target.name) */,")
    }
    lines.append("\t\t\t);")
    lines.append("\t\t\tpath = Sources;")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

    for target in targetRecords {
      lines.append("\t\t\(target.sourceGroupID) /* \(target.name) */ = {")
      lines.append("\t\t\tisa = PBXGroup;")
      lines.append("\t\t\tchildren = (")
      for file in fileRecords.filter({ $0.targetName == target.name }) {
        lines.append("\t\t\t\t\(file.id) /* \(file.displayName) */,")
      }
      lines.append("\t\t\t);")
      lines.append("\t\t\tpath = \(pbxValue(target.sourceGroupPath));")
      lines.append("\t\t\tsourceTree = \"<group>\";")
      lines.append("\t\t};")
    }
    lines.append("/* End PBXGroup section */")
    lines.append("")
  }

  private func appendPBXNativeTargets(to lines: inout [String]) {
    lines.append("/* Begin PBXNativeTarget section */")
    for target in targetRecords {
      lines.append("\t\t\(target.id) /* \(target.name) */ = {")
      lines.append("\t\t\tisa = PBXNativeTarget;")
      lines.append("\t\t\tbuildConfigurationList = \(target.configListID) /* Build configuration list for PBXNativeTarget \"\(target.name)\" */;")
      lines.append("\t\t\tbuildPhases = (")
      lines.append("\t\t\t\t\(target.sourcesPhaseID) /* Sources */,")
      if let resourcesPhaseID = target.resourcesPhaseID {
        lines.append("\t\t\t\t\(resourcesPhaseID) /* Resources */,")
      }
      if let frameworksPhaseID = target.frameworksPhaseID {
        lines.append("\t\t\t\t\(frameworksPhaseID) /* Frameworks */,")
      }
      for script in target.target.postBuildScripts ?? [] {
        lines.append("\t\t\t\t\(stableID("postbuild-\(target.name)-\(script.name ?? script.script)")) /* \(script.name ?? "Run Script") */,")
      }
      lines.append("\t\t\t);")
      lines.append("\t\t\tbuildRules = (")
      lines.append("\t\t\t);")
      lines.append("\t\t\tdependencies = (")
      lines.append("\t\t\t);")
      lines.append("\t\t\tname = \(pbxValue(target.name));")
      lines.append("\t\t\tpackageProductDependencies = (")
      for product in productRecords.filter({ $0.targetName == target.name }) {
        lines.append("\t\t\t\t\(product.id) /* \(product.productName) */,")
      }
      lines.append("\t\t\t);")
      lines.append("\t\t\tproductName = \(pbxValue(target.productName));")
      lines.append("\t\t\tproductReference = \(target.productFileID) /* \(target.productName).app */;")
      lines.append("\t\t\tproductType = \"com.apple.product-type.application\";")
      lines.append("\t\t};")
    }
    lines.append("/* End PBXNativeTarget section */")
    lines.append("")
  }

  private func appendPBXProject(to lines: inout [String]) {
    lines.append("/* Begin PBXProject section */")
    lines.append("\t\t\(projectID) /* Project object */ = {")
    lines.append("\t\t\tisa = PBXProject;")
    lines.append("\t\t\tattributes = {")
    lines.append("\t\t\t\tBuildIndependentTargetsInParallel = YES;")
    lines.append("\t\t\t\tLastUpgradeCheck = 1430;")
    lines.append("\t\t\t\tTargetAttributes = {")
    lines.append("\t\t\t\t};")
    lines.append("\t\t\t};")
    lines.append("\t\t\tbuildConfigurationList = \(projectConfigListID) /* Build configuration list for PBXProject \"\(spec.name)\" */;")
    lines.append("\t\t\tdevelopmentRegion = en;")
    lines.append("\t\t\thasScannedForEncodings = 0;")
    lines.append("\t\t\tknownRegions = (")
    lines.append("\t\t\t\tBase,")
    lines.append("\t\t\t\ten,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tmainGroup = \(rootGroupID);")
    lines.append("\t\t\tminimizedProjectReferenceProxies = 1;")
    if !packageRecords.isEmpty {
      lines.append("\t\t\tpackageReferences = (")
      for package in packageRecords where package.package.path != nil {
        lines.append("\t\t\t\t\(package.id) /* XCLocalSwiftPackageReference \(pbxComment(package.package.path ?? package.name)) */,")
      }
      lines.append("\t\t\t);")
    }
    lines.append("\t\t\tpreferredProjectObjectVersion = 77;")
    lines.append("\t\t\tproductRefGroup = \(productsGroupID) /* Products */;")
    lines.append("\t\t\tprojectDirPath = \"\";")
    lines.append("\t\t\tprojectRoot = \"\";")
    lines.append("\t\t\ttargets = (")
    for target in targetRecords {
      lines.append("\t\t\t\t\(target.id) /* \(target.name) */,")
    }
    lines.append("\t\t\t);")
    lines.append("\t\t};")
    lines.append("/* End PBXProject section */")
    lines.append("")
  }

  private func appendPBXResourcesBuildPhases(to lines: inout [String]) {
    let targets = targetRecords.filter { $0.resourcesPhaseID != nil }
    guard !targets.isEmpty else { return }
    lines.append("/* Begin PBXResourcesBuildPhase section */")
    for target in targets {
      guard let resourcesPhaseID = target.resourcesPhaseID else { continue }
      lines.append("\t\t\(resourcesPhaseID) /* Resources */ = {")
      lines.append("\t\t\tisa = PBXResourcesBuildPhase;")
      lines.append("\t\t\tbuildActionMask = 2147483647;")
      lines.append("\t\t\tfiles = (")
      for file in fileRecords.filter({ $0.targetName == target.name && $0.isResource }) {
        if let buildFileID = file.buildFileID {
          lines.append("\t\t\t\t\(buildFileID) /* \(file.displayName) in Resources */,")
        }
      }
      lines.append("\t\t\t);")
      lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
      lines.append("\t\t};")
    }
    lines.append("/* End PBXResourcesBuildPhase section */")
    lines.append("")
  }

  private func appendPBXShellScriptBuildPhases(to lines: inout [String]) {
    let scripts = targetRecords.flatMap { target in
      (target.target.postBuildScripts ?? []).map { (target, $0) }
    }
    guard !scripts.isEmpty else { return }
    lines.append("/* Begin PBXShellScriptBuildPhase section */")
    for (target, script) in scripts {
      let name = script.name ?? "Run Script"
      lines.append("\t\t\(stableID("postbuild-\(target.name)-\(script.name ?? script.script)")) /* \(name) */ = {")
      lines.append("\t\t\tisa = PBXShellScriptBuildPhase;")
      if script.basedOnDependencyAnalysis == false {
        lines.append("\t\t\talwaysOutOfDate = 1;")
      }
      lines.append("\t\t\tbuildActionMask = 2147483647;")
      lines.append("\t\t\tfiles = (")
      lines.append("\t\t\t);")
      lines.append("\t\t\tinputFileListPaths = (")
      lines.append("\t\t\t);")
      lines.append("\t\t\tinputPaths = (")
      lines.append("\t\t\t);")
      lines.append("\t\t\tname = \(pbxValue(name));")
      lines.append("\t\t\toutputFileListPaths = (")
      lines.append("\t\t\t);")
      lines.append("\t\t\toutputPaths = (")
      lines.append("\t\t\t);")
      lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
      lines.append("\t\t\tshellPath = /bin/sh;")
      lines.append("\t\t\tshellScript = \(pbxValue(script.script.hasSuffix("\n") ? script.script : "\(script.script)\n"));")
      lines.append("\t\t};")
    }
    lines.append("/* End PBXShellScriptBuildPhase section */")
    lines.append("")
  }

  private func appendPBXSourcesBuildPhases(to lines: inout [String]) {
    lines.append("/* Begin PBXSourcesBuildPhase section */")
    for target in targetRecords {
      lines.append("\t\t\(target.sourcesPhaseID) /* Sources */ = {")
      lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
      lines.append("\t\t\tbuildActionMask = 2147483647;")
      lines.append("\t\t\tfiles = (")
      for file in fileRecords.filter({ $0.targetName == target.name && $0.isSwiftSource }) {
        if let buildFileID = file.buildFileID {
          lines.append("\t\t\t\t\(buildFileID) /* \(file.displayName) in Sources */,")
        }
      }
      lines.append("\t\t\t);")
      lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
      lines.append("\t\t};")
    }
    lines.append("/* End PBXSourcesBuildPhase section */")
    lines.append("")
  }

  private func appendXCBuildConfigurations(to lines: inout [String]) {
    lines.append("/* Begin XCBuildConfiguration section */")
    for config in configurationNames {
      lines.append("\t\t\(stableID("project-config-\(config)")) /* \(config) */ = {")
      lines.append("\t\t\tisa = XCBuildConfiguration;")
      lines.append("\t\t\tbuildSettings = {")
      appendSettings(projectBuildSettings(configuration: config), to: &lines)
      lines.append("\t\t\t};")
      lines.append("\t\t\tname = \(pbxValue(config));")
      lines.append("\t\t};")
    }
    for target in targetRecords {
      for config in configurationNames {
        lines.append("\t\t\(stableID("target-config-\(target.name)-\(config)")) /* \(config) */ = {")
        lines.append("\t\t\tisa = XCBuildConfiguration;")
        lines.append("\t\t\tbuildSettings = {")
        appendSettings(targetBuildSettings(target: target, configuration: config), to: &lines)
        lines.append("\t\t\t};")
        lines.append("\t\t\tname = \(pbxValue(config));")
        lines.append("\t\t};")
      }
    }
    lines.append("/* End XCBuildConfiguration section */")
    lines.append("")
  }

  private func appendXCConfigurationLists(to lines: inout [String]) {
    lines.append("/* Begin XCConfigurationList section */")
    lines.append("\t\t\(projectConfigListID) /* Build configuration list for PBXProject \"\(spec.name)\" */ = {")
    lines.append("\t\t\tisa = XCConfigurationList;")
    lines.append("\t\t\tbuildConfigurations = (")
    for config in configurationNames {
      lines.append("\t\t\t\t\(stableID("project-config-\(config)")) /* \(config) */,")
    }
    lines.append("\t\t\t);")
    lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    lines.append("\t\t\tdefaultConfigurationName = \(pbxValue(defaultConfigurationName));")
    lines.append("\t\t};")

    for target in targetRecords {
      lines.append("\t\t\(target.configListID) /* Build configuration list for PBXNativeTarget \"\(target.name)\" */ = {")
      lines.append("\t\t\tisa = XCConfigurationList;")
      lines.append("\t\t\tbuildConfigurations = (")
      for config in configurationNames {
        lines.append("\t\t\t\t\(stableID("target-config-\(target.name)-\(config)")) /* \(config) */,")
      }
      lines.append("\t\t\t);")
      lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
      lines.append("\t\t\tdefaultConfigurationName = \(pbxValue(defaultConfigurationName));")
      lines.append("\t\t};")
    }
    lines.append("/* End XCConfigurationList section */")
    lines.append("")
  }

  private func appendXCLocalSwiftPackageReferences(to lines: inout [String]) {
    let localPackages = packageRecords.filter { $0.package.path != nil }
    guard !localPackages.isEmpty else { return }
    lines.append("/* Begin XCLocalSwiftPackageReference section */")
    for package in localPackages {
      lines.append("\t\t\(package.id) /* XCLocalSwiftPackageReference \(pbxComment(package.package.path ?? package.name)) */ = {")
      lines.append("\t\t\tisa = XCLocalSwiftPackageReference;")
      lines.append("\t\t\trelativePath = \(pbxValue(package.package.path ?? package.name));")
      lines.append("\t\t};")
    }
    lines.append("/* End XCLocalSwiftPackageReference section */")
    lines.append("")
  }

  private func appendXCSwiftPackageProductDependencies(to lines: inout [String]) {
    guard !productRecords.isEmpty else { return }
    lines.append("/* Begin XCSwiftPackageProductDependency section */")
    for product in productRecords {
      lines.append("\t\t\(product.id) /* \(product.productName) */ = {")
      lines.append("\t\t\tisa = XCSwiftPackageProductDependency;")
      if let packageID = packageRecords.first(where: { $0.name == product.packageName })?.id {
        lines.append("\t\t\tpackage = \(packageID) /* XCLocalSwiftPackageReference \(product.packageName) */;")
      }
      lines.append("\t\t\tproductName = \(pbxValue(product.productName));")
      lines.append("\t\t};")
    }
    lines.append("/* End XCSwiftPackageProductDependency section */")
    lines.append("")
  }

  private func appendSettings(_ settings: [String: PBXSettingValue], to lines: inout [String]) {
    for key in settings.keys.sorted() {
      guard let value = settings[key] else { continue }
      switch value {
      case .string(let string):
        lines.append("\t\t\t\t\(key) = \(pbxValue(string));")
      case .list(let values):
        lines.append("\t\t\t\t\(key) = (")
        for value in values {
          lines.append("\t\t\t\t\t\(pbxValue(value)),")
        }
        lines.append("\t\t\t\t);")
      }
    }
  }

  private var configurationNames: [String] {
    var names = Set(["Debug", "Release"])
    if let configs = spec.configs { names.formUnion(configs.keys) }
    if let configs = spec.settings?.configs { names.formUnion(configs.keys) }
    for target in targetRecords {
      if let configs = target.target.settings?.configs { names.formUnion(configs.keys) }
    }
    return names.sorted { lhs, rhs in
      let order = ["Debug": 0, "Release": 1]
      let lhsRank = order[lhs] ?? 100
      let rhsRank = order[rhs] ?? 100
      if lhsRank != rhsRank { return lhsRank < rhsRank }
      return lhs < rhs
    }
  }

  private var defaultConfigurationName: String {
    configurationNames.contains("Debug") ? "Debug" : configurationNames.first ?? "Release"
  }

  private func projectBuildSettings(configuration: String) -> [String: PBXSettingValue] {
    var settings = defaultProjectSettings(configuration: configuration)
    merge(spec.settings?.base, into: &settings)
    merge(configValues(in: spec.settings, configuration: configuration), into: &settings)
    return settings
  }

  private func targetBuildSettings(target: TargetRecord, configuration: String) -> [String: PBXSettingValue] {
    var settings = defaultTargetSettings(target: target, configuration: configuration)
    merge(spec.settings?.base, into: &settings)
    merge(configValues(in: spec.settings, configuration: configuration), into: &settings)
    merge(target.target.settings?.base, into: &settings)
    merge(configValues(in: target.target.settings, configuration: configuration), into: &settings)
    if let deploymentTarget = target.target.deploymentTarget?.stringValue {
      settings["MACOSX_DEPLOYMENT_TARGET"] = .string(deploymentTarget)
    }
    if let infoPath = target.target.infoPath {
      settings["INFOPLIST_FILE"] = .string(infoPath)
    }
    return settings
  }

  private func defaultProjectSettings(configuration: String) -> [String: PBXSettingValue] {
    var settings: [String: PBXSettingValue] = [
      "ALWAYS_SEARCH_USER_PATHS": .string("NO"),
      "CLANG_ANALYZER_NONNULL": .string("YES"),
      "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": .string("YES_AGGRESSIVE"),
      "CLANG_CXX_LANGUAGE_STANDARD": .string("gnu++14"),
      "CLANG_CXX_LIBRARY": .string("libc++"),
      "CLANG_ENABLE_MODULES": .string("YES"),
      "CLANG_ENABLE_OBJC_ARC": .string("YES"),
      "CLANG_ENABLE_OBJC_WEAK": .string("YES"),
      "CLANG_WARN_BOOL_CONVERSION": .string("YES"),
      "CLANG_WARN_CONSTANT_CONVERSION": .string("YES"),
      "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": .string("YES"),
      "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": .string("YES_ERROR"),
      "CLANG_WARN_DOCUMENTATION_COMMENTS": .string("YES"),
      "CLANG_WARN_EMPTY_BODY": .string("YES"),
      "CLANG_WARN_ENUM_CONVERSION": .string("YES"),
      "CLANG_WARN_INFINITE_RECURSION": .string("YES"),
      "CLANG_WARN_INT_CONVERSION": .string("YES"),
      "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": .string("YES"),
      "CLANG_WARN_OBJC_LITERAL_CONVERSION": .string("YES"),
      "CLANG_WARN_OBJC_ROOT_CLASS": .string("YES_ERROR"),
      "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": .string("YES"),
      "CLANG_WARN_RANGE_LOOP_ANALYSIS": .string("YES"),
      "CLANG_WARN_STRICT_PROTOTYPES": .string("YES"),
      "CLANG_WARN_SUSPICIOUS_MOVE": .string("YES"),
      "CLANG_WARN_UNGUARDED_AVAILABILITY": .string("YES_AGGRESSIVE"),
      "CLANG_WARN_UNREACHABLE_CODE": .string("YES"),
      "CLANG_WARN__DUPLICATE_METHOD_MATCH": .string("YES"),
      "COPY_PHASE_STRIP": .string("NO"),
      "ENABLE_STRICT_OBJC_MSGSEND": .string("YES"),
      "GCC_C_LANGUAGE_STANDARD": .string("gnu11"),
      "GCC_NO_COMMON_BLOCKS": .string("YES"),
      "GCC_WARN_64_TO_32_BIT_CONVERSION": .string("YES"),
      "GCC_WARN_ABOUT_RETURN_TYPE": .string("YES_ERROR"),
      "GCC_WARN_UNDECLARED_SELECTOR": .string("YES"),
      "GCC_WARN_UNINITIALIZED_AUTOS": .string("YES_AGGRESSIVE"),
      "GCC_WARN_UNUSED_FUNCTION": .string("YES"),
      "GCC_WARN_UNUSED_VARIABLE": .string("YES"),
      "MACOSX_DEPLOYMENT_TARGET": .string("26.0"),
      "MTL_FAST_MATH": .string("YES"),
      "PRODUCT_NAME": .string("$(TARGET_NAME)"),
      "SDKROOT": .string("macosx"),
      "SWIFT_VERSION": .string("6.4"),
    ]
    if configuration.caseInsensitiveCompare("Debug") == .orderedSame {
      settings["DEBUG_INFORMATION_FORMAT"] = .string("dwarf")
      settings["ENABLE_TESTABILITY"] = .string("YES")
      settings["GCC_DYNAMIC_NO_PIC"] = .string("NO")
      settings["GCC_OPTIMIZATION_LEVEL"] = .string("0")
      settings["GCC_PREPROCESSOR_DEFINITIONS"] = .list(["$(inherited)", "DEBUG=1"])
      settings["MTL_ENABLE_DEBUG_INFO"] = .string("INCLUDE_SOURCE")
      settings["ONLY_ACTIVE_ARCH"] = .string("YES")
      settings["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = .string("DEBUG")
      settings["SWIFT_OPTIMIZATION_LEVEL"] = .string("-Onone")
    } else {
      settings["DEBUG_INFORMATION_FORMAT"] = .string("dwarf-with-dsym")
      settings["ENABLE_NS_ASSERTIONS"] = .string("NO")
      settings["MTL_ENABLE_DEBUG_INFO"] = .string("NO")
      settings["SWIFT_COMPILATION_MODE"] = .string("wholemodule")
      settings["SWIFT_OPTIMIZATION_LEVEL"] = .string("-O")
    }
    return settings
  }

  private func defaultTargetSettings(target: TargetRecord, configuration _: String) -> [String: PBXSettingValue] {
    [
      "ASSETCATALOG_COMPILER_APPICON_NAME": .string("AppIcon"),
      "CODE_SIGNING_ALLOWED": .string("NO"),
      "CODE_SIGNING_REQUIRED": .string("NO"),
      "COMBINE_HIDPI_IMAGES": .string("YES"),
      "GENERATE_INFOPLIST_FILE": .string("NO"),
      "LD_RUNPATH_SEARCH_PATHS": .list(["$(inherited)", "@executable_path/../Frameworks"]),
      "MACOSX_DEPLOYMENT_TARGET": .string("26.0"),
      "PRODUCT_NAME": .string(target.productName),
      "SDKROOT": .string("macosx"),
    ]
  }

  private func configValues(
    in settings: AppleProjectSettings?,
    configuration: String
  ) -> [String: AppleProjectValue]? {
    guard let configs = settings?.configs else { return nil }
    if let exact = configs[configuration] {
      return exact
    }
    return configs.first { key, _ in
      key.caseInsensitiveCompare(configuration) == .orderedSame
    }?.value
  }

  private func merge(
    _ values: [String: AppleProjectValue]?,
    into settings: inout [String: PBXSettingValue]
  ) {
    guard let values else { return }
    for (key, value) in values {
      if let setting = PBXSettingValue(value: value) {
        settings[key] = setting
      }
    }
  }

  private static func discoverFiles(
    targetName: String,
    target: AppleProjectTarget,
    projectDirectory: URL
  ) throws -> [DiscoveredFile] {
    let fileManager = FileManager.default
    let infoPath = target.infoPath
    var discovered: [DiscoveredFile] = []
    var seen = Set<String>()

    for source in target.sources ?? [] {
      let sourceURL = projectDirectory.appendingPathComponent(source.path).standardizedFileURL
      var isDirectory: ObjCBool = false
      let exists = fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory)
      guard exists else {
        if source.optional == true { continue }
        throw AppleProjectXcodeProjectGenerationError.missingSourcePath(
          targetName: targetName,
          path: source.path
        )
      }
      let sourceRoot = isDirectory.boolValue ? sourceURL : sourceURL.deletingLastPathComponent()
      let fileURLs = try collectFileURLs(at: sourceURL)
      for fileURL in fileURLs {
        let relativePath = relativePath(from: sourceRoot, to: fileURL)
        let kind = FileKind(path: relativePath, sourcePath: source.path, infoPath: infoPath)
        let key = "\(source.path)/\(relativePath)"
        guard seen.insert(key).inserted else { continue }
        discovered.append(
          DiscoveredFile(
            relativePath: relativePath,
            kind: kind
          )
        )
      }
    }

    if let infoPath, !seen.contains(infoPath) {
      let infoURL = projectDirectory.appendingPathComponent(infoPath).standardizedFileURL
      if fileManager.fileExists(atPath: infoURL.path) {
        discovered.append(
          DiscoveredFile(
            relativePath: infoPath,
            kind: .infoPlist
          )
        )
      }
    }

    return discovered.sorted { $0.relativePath < $1.relativePath }
  }

  private static func collectFileURLs(at url: URL) throws -> [URL] {
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return [] }
    if !isDirectory.boolValue || specialDirectoryExtensions.contains(url.pathExtension.lowercased()) {
      return [url]
    }
    guard let enumerator = fileManager.enumerator(
      at: url,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }
    var files: [URL] = []
    for case let fileURL as URL in enumerator {
      if specialDirectoryExtensions.contains(fileURL.pathExtension.lowercased()) {
        files.append(fileURL)
        enumerator.skipDescendants()
        continue
      }
      let values = try fileURL.resourceValues(forKeys: [.isDirectoryKey])
      if values.isDirectory == false {
        files.append(fileURL)
      }
    }
    return files
  }

  private static var specialDirectoryExtensions: Set<String> {
    ["xcassets", "bundle"]
  }
}

private struct TargetRecord {
  var name: String
  var target: AppleProjectTarget
  var productName: String
  var id: String
  var productFileID: String
  var sourcesPhaseID: String
  var resourcesPhaseID: String?
  var frameworksPhaseID: String?
  var configListID: String
  var sourceGroupID: String

  var sourceGroupPath: String {
    let firstSource = target.sources?.first?.path ?? "Sources"
    let components = firstSource.split(separator: "/").map(String.init)
    if components.first == "Sources", components.count > 1 {
      return components.dropFirst().joined(separator: "/")
    }
    return firstSource
  }
}

private struct FileRecord {
  var targetName: String
  var sourceGroupID: String
  var relativePath: String
  var displayName: String
  var id: String
  var buildFileID: String?
  var kind: FileKind

  var isSwiftSource: Bool { kind == .swift }
  var isResource: Bool { kind == .resource }
  var isBuildFile: Bool { kind == .swift || kind == .resource }

  static func product(_ product: ProductRecord) -> FileRecord {
    FileRecord(
      targetName: product.targetName,
      sourceGroupID: "",
      relativePath: product.productName,
      displayName: product.productName,
      id: product.id,
      buildFileID: product.buildFileID,
      kind: .packageProduct(productID: product.id)
    )
  }
}

private struct PackageRecord {
  var name: String
  var package: AppleProjectPackage
  var id: String
  var groupFileID: String

  var displayName: String {
    if let path = package.path {
      return URL(fileURLWithPath: path).lastPathComponent
    }
    return name
  }
}

private struct ProductRecord {
  var targetName: String
  var packageName: String
  var productName: String
  var id: String
  var buildFileID: String
}

private struct DiscoveredFile {
  var relativePath: String
  var kind: FileKind

  var isSwiftSource: Bool { kind == .swift }
  var isResource: Bool { kind == .resource }
  var isBuildFile: Bool { isSwiftSource || isResource }
}

private enum FileKind: Equatable {
  case swift
  case resource
  case infoPlist
  case packageProduct(productID: String)

  init(path: String, sourcePath: String, infoPath: String?) {
    let fullPath = sourcePath.hasSuffix(path) ? sourcePath : "\(sourcePath)/\(path)"
    if fullPath == infoPath || path == infoPath {
      self = .infoPlist
    } else if path.hasSuffix(".swift") {
      self = .swift
    } else if path.hasSuffix(".plist") {
      self = .infoPlist
    } else {
      self = .resource
    }
  }

  var fileType: String? {
    switch self {
    case .swift:
      return "sourcecode.swift"
    case .resource:
      return nil
    case .infoPlist:
      return "text.plist"
    case .packageProduct:
      return nil
    }
  }
}

private enum PBXSettingValue: Equatable {
  case string(String)
  case list([String])

  init?(value: AppleProjectValue) {
    switch value {
    case .null:
      return nil
    case .bool(let value):
      self = .string(value ? "YES" : "NO")
    case .int(let value):
      self = .string(String(value))
    case .double(let value):
      self = .string(String(value))
    case .string(let value):
      self = .string(value)
    case .array(let values):
      self = .list(values.compactMap(\.stringValue))
    case .object:
      return nil
    }
  }
}

private extension AppleProjectTarget {
  var infoPath: String? {
    if let path = info?.path { return path }
    return settings?.base?["INFOPLIST_FILE"]?.stringValue
  }

  func productName(defaultName: String) -> String {
    settings?.base?["PRODUCT_NAME"]?.stringValue ?? defaultName
  }
}

private func stableID(_ key: String) -> String {
  func fnv(_ seed: UInt64, _ text: String) -> UInt64 {
    var hash = seed
    for byte in text.utf8 {
      hash ^= UInt64(byte)
      hash &*= 1_099_511_628_211
    }
    return hash
  }
  let a = fnv(14_695_981_039_346_656_037, key)
  let b = fnv(10_995_116_282_11, "\(key)#b")
  let c = fnv(7_809_847_782_461_553_095, "\(key)#c")
  return String(format: "%08X%08X%08X", UInt32(truncatingIfNeeded: a >> 16), UInt32(truncatingIfNeeded: b >> 16), UInt32(truncatingIfNeeded: c >> 16))
}

private func pbxValue(_ value: String) -> String {
  let barePattern = #"^[A-Za-z0-9_./$()+:-]+$"#
  if value.range(of: barePattern, options: .regularExpression) != nil,
    !value.isEmpty,
    !["YES", "NO"].contains(value)
  {
    return value
  }
  var rendered = "\""
  for scalar in value.unicodeScalars {
    switch scalar {
    case "\\":
      rendered += "\\\\"
    case "\"":
      rendered += "\\\""
    case "\n":
      rendered += "\\n"
    case "\r":
      rendered += "\\r"
    case "\t":
      rendered += "\\t"
    default:
      rendered.unicodeScalars.append(scalar)
    }
  }
  rendered += "\""
  return rendered
}

private func pbxComment(_ value: String) -> String {
  "\"\(value.replacingOccurrences(of: "\"", with: "\\\""))\""
}

private func relativePath(from base: URL, to target: URL) -> String {
  let baseComponents = base.standardizedFileURL.pathComponents
  let targetComponents = target.standardizedFileURL.pathComponents
  var commonPrefixCount = 0
  while commonPrefixCount < baseComponents.count,
    commonPrefixCount < targetComponents.count,
    baseComponents[commonPrefixCount] == targetComponents[commonPrefixCount]
  {
    commonPrefixCount += 1
  }
  let up = Array(repeating: "..", count: baseComponents.count - commonPrefixCount)
  let down = Array(targetComponents.dropFirst(commonPrefixCount))
  return (up + down).joined(separator: "/")
}

public struct PklXcodeProjectGenerationReceipt: Codable, Equatable, Sendable {
  public var schemaVersion = "0.1.0"
  public var schemaFamilySlug = VaporizeAppleProjectReceiptSchema.schemaFamilySlug
  public var schemaFamilyVersion = VaporizeAppleProjectReceiptSchema.schemaFamilyVersion
  public var schemaRef = VaporizeAppleProjectReceiptSchema.xcodeProjectGenerationSchemaRef
  public var receiptKind = "vaporize-pkl-xcodeproj-generation"
  public var generationPhase = "pkl-to-xcodeproj-world-state"
  public var generatorStatus = "xcodeproj-world-state-generated"
  public var pklPath: String
  public var outputPath: String
  public var pbxprojPath: String
  public var workspacePath: String
  public var requestId: String
  public var projectName: String
  public var targetCount: Int
  public var packageCount: Int
  public var schemeCount: Int
  public var targetNames: [String]
  public var packageNames: [String]
  public var sourceFileCount: Int
  public var resourceFileCount: Int
  public var generatedByteCount: Int
  public var buildableWorldStateGenerated = true
  public var xcodeProjectGenerated = true
  public var boundary = "Generates .xcodeproj world-state from evaluated AppleProjectSpec Pkl; first slice supports macOS application targets."
  public var pklSignature: AppleProjectSpecParitySignature
}
