import Foundation
import Logging

public enum GrapexModel: String, Sendable {  // TODO: Delete (deprecated)
    case transe
    case se
}

public struct GrapexTester: ModelTester {

    public static let platform = Platform.grapex

    public enum ModelType: String, Sendable {
        case transe
        case se
    }

    public typealias Metrics = MeagerMetricSet

    public let model: ModelType

    public let gpu: Bool
    public let differentGpus: Bool

    public let terminationDelay: Double?

    public let configRoot: URL
    public let env: String

    public let nWorkers: Int?

    public let logger: Logger

    public var initialArgs = ["run", "main.exs"]
    public var initialEnv = ["LC_ALL": "en_US.UTF-8"]

    public var path: URL {
        URL(fileURLWithPath: "/home/\(USER)/\(env)")
    }

    public var executable: URL {
        URL(fileURLWithPath: "/home/\(USER)/.asdf/shims/mix")
    }

    public init(
        model: ModelType, configRoot: URL, env: String, gpu: Bool = true, differentGpus: Bool = true, terminationDelay: Double? = nil, nWorkers: Int? = nil, logLevel: Logger.Level = .info
    ) {
        logger = Logger(level: logLevel, label: "grapex-tester")

        self.model = model

        self.gpu = gpu
        self.differentGpus = differentGpus

        self.terminationDelay = terminationDelay

        self.configRoot = configRoot
        self.env = env

        self.nWorkers = nWorkers
    }
}
