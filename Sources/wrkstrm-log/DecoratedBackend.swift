import Logging

public struct DecoratedBackend<Base: LogBackend>: LogBackend, Sendable {
  public let base: Base
  public let decorator: any LogDecorator

  public init(base: Base, decorator: any LogDecorator) {
    self.base = base
    self.decorator = decorator
  }

  public func log(
    _ level: Logging.Logger.Level,
    message: @autoclosure () -> Any,
    logger: Log,
    file: String,
    function: String,
    line: UInt,
    context: any CommonLogContext
  ) {
    var overridden = logger
    overridden.decorator = decorator
    base.log(
      level,
      message: message(),
      logger: overridden,
      file: file,
      function: function,
      line: line,
      context: context
    )
  }
}

extension PrintLogBackend {
  public func decorated(with decorator: any LogDecorator) -> any LogBackend {
    DecoratedBackend(base: self, decorator: decorator)
  }
}

extension SwiftLogBackend {
  public func decorated(with decorator: any LogDecorator) -> any LogBackend {
    DecoratedBackend(base: self, decorator: decorator)
  }
}

#if canImport(os)
extension OSLogBackend {
  public func decorated(with decorator: any LogDecorator) -> any LogBackend {
    DecoratedBackend(base: self, decorator: decorator)
  }
}
#endif

extension DisabledLogBackend {
  public func decorated(with decorator: any LogDecorator) -> any LogBackend {
    DecoratedBackend(base: self, decorator: decorator)
  }
}

// Typealiases removed in 3.0.0: use LogGroup directly.
