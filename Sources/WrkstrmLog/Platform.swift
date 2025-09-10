#if canImport(Foundation) && !os(WASI)
import Foundation
public let WRK_HAS_FOUNDATION = true
#else
public let WRK_HAS_FOUNDATION = false
#endif

@inline(__always)
internal func wrk_hostname() -> String {
  #if canImport(Foundation) && !os(WASI)
  return ProcessInfo.processInfo.hostName
  #else
  return "wasm"
  #endif
}
