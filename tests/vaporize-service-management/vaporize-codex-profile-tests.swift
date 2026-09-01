import Foundation
import Testing
import VaporizeProjectModel
import VaporizeServiceManagement

@Suite("Vaporize Codex profile projection")
struct VaporizeCodexProfileTests {
  @Test("Projects Codex metadata from a LinkRef-backed serving offering")
  func projectsProfileFromServingOffering() async throws {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent("vaporize-codex-profile-\(UUID().uuidString.lowercased())")
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let models = root.appendingPathComponent("models/bonsai")
    try FileManager.default.createDirectory(at: models, withIntermediateDirectories: true)

    let schemaURL = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Pkl/vaporize-project.pkl")
    let projectURL = root.appendingPathComponent("project.pkl")
    let project = """
      amends "\(schemaURL.absoluteString)"

      name = "bonsai"
      services = new {
        ["clia-bonsai-512k-codex"] = new {
          activation = "manual"
          executable = "compat.exe"
          healthCheck = new {
            kind = "http"
            url = "http://127.0.0.1:8006/health"
          }
          aiModelServingOfferingRef = new {
            tg = new {
              new {
                k = "rp"
                v = "models/bonsai/serving-offering.su.json"
              }
            }
          }
          codexProfile = new {
            slug = "clia-bonsai"
            provider = "clia_bonsai_local"
            baseInstructions = "Use tools precisely."
          }
        }
      }
      """
    try Data(project.utf8).write(to: projectURL)
    try Data(offeringJSON.utf8).write(
      to: models.appendingPathComponent("serving-offering.su.json"))
    try Data(loadoutJSON.utf8).write(
      to: models.appendingPathComponent("serving-loadout.su.json"))
    try Data(qualificationJSON.utf8).write(
      to: models.appendingPathComponent("serving-qualification.su.json"))

    let loaded = try await VaporizeProjectLoader.load(url: projectURL)
    let output = root.appendingPathComponent("codex")
    let plan = try VaporizeCodexProfileProjector.plan(
      serviceID: "clia-bonsai-512k-codex",
      project: loaded,
      projectURL: projectURL,
      outputDirectory: output
    )
    try VaporizeCodexProfileProjector.materialize(plan)

    #expect(plan.offeringID == "clia/bonsai-27b/512k")
    #expect(plan.modelAlias == "clia-bonsai-27b")
    #expect(plan.contextWindow == 524_288)
    let profile = try String(contentsOf: plan.profileURL, encoding: .utf8)
    #expect(profile.contains("model_context_window = 524288"))
    #expect(profile.contains("model_auto_compact_token_limit = 458752"))
    #expect(profile.contains("base_url = \"http://127.0.0.1:8006/v1\""))
    let catalog = try #require(
      JSONSerialization.jsonObject(with: Data(contentsOf: plan.catalogURL)) as? [String: Any]
    )
    let catalogModels = try #require(catalog["models"] as? [[String: Any]])
    #expect(catalogModels.first?["slug"] as? String == "clia-bonsai-27b")
    #expect(catalogModels.first?["context_window"] as? Int == 524_288)
  }

  @Test("Refuses an unqualified projection without replacing existing files")
  func refusesUnqualifiedProjectionWithoutReplacingExistingFiles() async throws {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent("vaporize-codex-profile-\(UUID().uuidString.lowercased())")
    defer { try? FileManager.default.removeItem(at: root) }
    let models = root.appendingPathComponent("models/bonsai")
    let output = root.appendingPathComponent("codex")
    try FileManager.default.createDirectory(at: models, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

    let schemaURL = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Pkl/vaporize-project.pkl")
    let projectURL = root.appendingPathComponent("project.pkl")
    let project = """
      amends "\(schemaURL.absoluteString)"
      name = "bonsai"
      services = new {
        ["clia-bonsai-512k-codex"] = new {
          activation = "manual"
          executable = "compat.exe"
          healthCheck = new { kind = "http"; url = "http://127.0.0.1:8006/health" }
          aiModelServingOfferingRef = new {
            tg = new { new { k = "rp"; v = "models/bonsai/serving-offering.su.json" } }
          }
          codexProfile = new {
            slug = "clia-bonsai"
            provider = "clia_bonsai_local"
            baseInstructions = "Use tools precisely."
          }
        }
      }
      """
    try Data(project.utf8).write(to: projectURL)
    try Data(offeringJSON.utf8).write(
      to: models.appendingPathComponent("serving-offering.su.json"))
    try Data(loadoutJSON.utf8).write(
      to: models.appendingPathComponent("serving-loadout.su.json"))
    try Data(pendingQualificationJSON.utf8).write(
      to: models.appendingPathComponent("serving-qualification.su.json"))
    let profileURL = output.appendingPathComponent("clia-bonsai.config.toml")
    let catalogURL = output.appendingPathComponent("clia-bonsai.models.json")
    try Data("existing-profile".utf8).write(to: profileURL)
    try Data("existing-catalog".utf8).write(to: catalogURL)

    let loaded = try await VaporizeProjectLoader.load(url: projectURL)
    #expect(throws: VaporizeCodexProfileProjectionError.qualificationRequired("capacity:prefill")) {
      _ = try VaporizeCodexProfileProjector.plan(
        serviceID: "clia-bonsai-512k-codex",
        project: loaded,
        projectURL: projectURL,
        outputDirectory: output
      )
    }
    #expect(try String(contentsOf: profileURL, encoding: .utf8) == "existing-profile")
    #expect(try String(contentsOf: catalogURL, encoding: .utf8) == "existing-catalog")
  }

  private var offeringJSON: String {
    """
    {
      "ai-model-serving-offering-model": "2.2609.01200",
      "id": "clia/bonsai-27b/512k",
      "displayName": "CLIA Bonsai 27B 512K",
      "releaseRef": { "link-ref-model": "0.0.5", "tg": [{ "k": "ss", "v": "ai-model-release://ternary-bonsai/27b" }] },
      "artifactRef": { "link-ref-model": "0.0.5", "tg": [{ "k": "ss", "v": "ai-model-artifact://bonsai/q1" }] },
      "adapterRefs": [],
      "providerRef": { "link-ref-model": "0.0.5", "tg": [{ "k": "ss", "v": "ai-serving-provider://takumi-local" }] },
      "serviceRef": { "link-ref-model": "0.0.5", "tg": [{ "k": "ss", "v": "service://vaporize/clia-bonsai-27b-512k" }] },
      "route": {
        "strategy": "http-client-server",
        "ingressProtocol": "responses",
        "transport": "http",
        "placement": "local-host",
        "engineRef": { "link-ref-model": "0.0.5", "tg": [{ "k": "ss", "v": "ai-inference-engine://llama-cpp" }] }
      },
      "loadoutRef": { "link-ref-model": "0.0.5", "tg": [{ "k": "rp", "v": "serving-loadout.su.json" }] },
      "capacityPolicyRef": { "link-ref-model": "0.0.5", "tg": [{ "k": "ss", "v": "capacity://3090" }] },
      "qualificationRefs": [
        { "link-ref-model": "0.0.5", "tg": [{ "k": "rp", "v": "serving-qualification.su.json" }] }
      ],
      "lifecycle": "preview",
      "admissionReceiptRefs": [
        { "link-ref-model": "0.0.5", "tg": [{ "k": "ss", "v": "admission-receipt://bonsai/512k/001" }] }
      ],
      "aliases": ["clia-bonsai-27b"]
    }
    """
  }

  private var loadoutJSON: String {
    """
    {
      "ai-model-serving-loadout-model": "2.2609.01200",
      "id": "clia-bonsai-27b-512k-gpu-only",
      "artifactRef": { "link-ref-model": "0.0.5", "tg": [{ "k": "ss", "v": "artifact://bonsai/q1" }] },
      "adapterRefs": [],
      "engineBuildRef": { "link-ref-model": "0.0.5", "tg": [{ "k": "ss", "v": "engine://llama-cpp" }] },
      "context": {
        "slotCount": 1,
        "allocatedTokensPerSlot": 524288,
        "nativeContextTokens": 262144,
        "maximumOutputTokens": 32768,
        "extrapolation": { "method": "linear-rope", "scale": 2.0, "originalContextTokens": 262144 }
      },
      "kvCache": { "keyType": "q4-0", "valueType": "q4-0", "placement": "accelerator-only" },
      "layerPlacement": { "totalLayers": 64, "acceleratorLayers": 64, "placement": "accelerator-only" },
      "batch": { "batchTokens": 512, "microBatchTokens": 128 },
      "capacityPolicyRef": { "link-ref-model": "0.0.5", "tg": [{ "k": "ss", "v": "capacity://3090" }] },
      "configurationReceiptRefs": []
    }
    """
  }

  private var qualificationJSON: String {
    qualificationJSON(prefillStatus: "qualified", prefillReceipts: receiptRefs)
  }

  private var pendingQualificationJSON: String {
    qualificationJSON(prefillStatus: "pending", prefillReceipts: "[]")
  }

  private var receiptRefs: String {
    #"[{ "link-ref-model": "0.0.5", "tg": [{ "k": "ss", "v": "lab-report://bonsai/512k/001" }] }]"#
  }

  private func qualificationJSON(prefillStatus: String, prefillReceipts: String) -> String {
    """
    {
      "ai-model-serving-qualification-model": "2.2609.01200",
      "id": "clia-bonsai-27b-512k-qualification-001",
      "offeringRef": { "link-ref-model": "0.0.5", "tg": [{ "k": "rp", "v": "serving-offering.su.json" }] },
      "recordedAt": "2026-09-01T00:00:00Z",
      "dimensions": [
        { "dimension": "capacity", "measurementPhase": "idle", "status": "qualified", "receiptRefs": \(receiptRefs) },
        { "dimension": "capacity", "measurementPhase": "prefill", "status": "\(prefillStatus)", "receiptRefs": \(prefillReceipts) },
        { "dimension": "capacity", "measurementPhase": "decode", "status": "qualified", "receiptRefs": \(receiptRefs) },
        { "dimension": "placement", "status": "qualified", "receiptRefs": \(receiptRefs) },
        { "dimension": "protocol", "status": "qualified", "receiptRefs": \(receiptRefs) },
        { "dimension": "tool-loop", "status": "qualified", "receiptRefs": \(receiptRefs) },
        { "dimension": "semantic", "contextBand": "native", "status": "qualified", "receiptRefs": \(receiptRefs) },
        { "dimension": "semantic", "contextBand": "extrapolated", "status": "qualified", "receiptRefs": \(receiptRefs) }
      ]
    }
    """
  }
}
