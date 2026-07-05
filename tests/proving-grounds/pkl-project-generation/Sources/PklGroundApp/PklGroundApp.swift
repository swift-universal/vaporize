import SwiftUI
import PklGroundCore

@main
struct PklGroundApp: App {
  var body: some Scene {
    WindowGroup {
      Text("Pkl proving ground \(PklGroundCore.proofValue)")
    }
  }
}
