#if canImport(Foundation) && !os(WASI)
import Foundation
public let wrkHasFoundation = true
#else
public let wrkHasFoundation = false
#endif

@inline(__always)
internal func wrkHostname() -> String {
  #if canImport(Foundation) && !os(WASI)
  return ProcessInfo.processInfo.hostName
  #else
  return "wasm"
  #endif
}
