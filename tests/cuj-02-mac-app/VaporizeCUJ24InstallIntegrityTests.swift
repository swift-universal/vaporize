import Foundation
import Testing

@testable import SwiftAppInstaller

// CUJ-24 — Assistant trusts install integrity.
//
// An install that reports success must have ACTUALLY landed the artifact. These simulate
// SwiftAppInstaller.atomicInstall (the .app install path) proving: (1) a fresh install lands
// the bundle and leaves no staged `.installing-` residue; (2) a forced reinstall replaces the
// existing bundle atomically; (3) an unforced install over an existing bundle refuses loudly.
// This is the simulation backing BUG-VAPORIZE-CLI-INSTALL-NO-POST-INSTALL-PRESENCE-CHECK-2026-07-08
// and the tooling-silent-fallback-to-wrong-state-not-error-loud axiom (install fails loud or
// lands verifiably; it never reports a silent success with nothing installed).

private func cuj24TempDir() throws -> URL {
  let dir = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-cuj24-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
  return dir
}

private func cuj24MakeBundle(at url: URL, marker: String) throws {
  try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  try marker.write(
    to: url.appendingPathComponent("Contents.marker"), atomically: true, encoding: .utf8)
}

private func cuj24StagedResidue(in root: URL) throws -> [String] {
  try FileManager.default.contentsOfDirectory(atPath: root.path)
    .filter { $0.contains(".installing-") }
}

@Test("CUJ-24 atomic install lands the bundle and leaves no staged residue")
func cuj24AtomicInstallLandsBundle() throws {
  let root = try cuj24TempDir()
  defer { try? FileManager.default.removeItem(at: root) }
  let source = root.appendingPathComponent("Src.app")
  try cuj24MakeBundle(at: source, marker: "v1")
  let dest = root.appendingPathComponent("Dest.app")

  try SwiftAppInstaller.atomicInstall(from: source, to: dest, force: false)

  #expect(FileManager.default.fileExists(atPath: dest.path))
  let landed = try String(
    contentsOf: dest.appendingPathComponent("Contents.marker"), encoding: .utf8)
  #expect(landed == "v1")
  #expect(try cuj24StagedResidue(in: root).isEmpty)
}

@Test("CUJ-24 forced reinstall replaces the existing bundle atomically")
func cuj24AtomicInstallReplacesWithForce() throws {
  let root = try cuj24TempDir()
  defer { try? FileManager.default.removeItem(at: root) }
  let dest = root.appendingPathComponent("Dest.app")

  let v1 = root.appendingPathComponent("V1.app")
  try cuj24MakeBundle(at: v1, marker: "v1")
  try SwiftAppInstaller.atomicInstall(from: v1, to: dest, force: false)

  let v2 = root.appendingPathComponent("V2.app")
  try cuj24MakeBundle(at: v2, marker: "v2")
  try SwiftAppInstaller.atomicInstall(from: v2, to: dest, force: true)

  let landed = try String(
    contentsOf: dest.appendingPathComponent("Contents.marker"), encoding: .utf8)
  #expect(landed == "v2")
  #expect(try cuj24StagedResidue(in: root).isEmpty)
}

@Test("CUJ-24 unforced install over an existing bundle refuses loudly")
func cuj24AtomicInstallRefusesWithoutForce() throws {
  let root = try cuj24TempDir()
  defer { try? FileManager.default.removeItem(at: root) }
  let dest = root.appendingPathComponent("Dest.app")

  let v1 = root.appendingPathComponent("V1.app")
  try cuj24MakeBundle(at: v1, marker: "v1")
  try SwiftAppInstaller.atomicInstall(from: v1, to: dest, force: false)

  let v2 = root.appendingPathComponent("V2.app")
  try cuj24MakeBundle(at: v2, marker: "v2")
  #expect(throws: InstallerError.self) {
    try SwiftAppInstaller.atomicInstall(from: v2, to: dest, force: false)
  }
}
