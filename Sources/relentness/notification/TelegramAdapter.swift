import Foundation
import TelegramBotSDK

public protocol ProgressTracker {
    var status: String { get async }
}

public actor ModelComparisonProgressTracker: ProgressTracker {
    let nModels: Int
    var nHyperParameterSets: Int
    
    var nProcessedModels: Int
    var nProcessedHyperParameterSets: Int
   
    public init(nModels: Int, nHyperParameterSets: Int) {
        self.nModels = nModels
        self.nHyperParameterSets = nHyperParameterSets

        self.nProcessedModels = 0
        self.nProcessedHyperParameterSets = 0
    } 
    
    public func nextHyperParameterSet() {
       self.nProcessedHyperParameterSets += 1
    } 

    public func nextModel() { // nHyperParameterSets: Int
       self.nProcessedModels += 1
       // self.nHyperParameterSets = nHyperParameterSets
       // self.nProcessedHyperParameterSets = 0
    }

    // public func getNmodels() -> Int {
    //     self.nModels
    // }

    public func getNhyperParameterSets() -> Int {
        self.nHyperParameterSets
    }

    public func getNprocessedModels() -> Int {
        self.nProcessedModels
    }

    public func getNprocessedHyperParameterSets() -> Int {
        self.nProcessedHyperParameterSets
    }

    public func setNhyperParameterSets(_ value: Int) {
        nHyperParameterSets = value
        self.nProcessedHyperParameterSets = 0
    }

    public var status: String {
        get async {
            "\(self.getNprocessedModels()) / \(self.nModels) models and " +
            "\(self.getNprocessedHyperParameterSets()) / \(self.getNhyperParameterSets()) hyperparameters sets for the current model are handled"
        }
    }
}

public actor DatasetComparisonProgressTracker: ProgressTracker {
    let nDatasets: Int
    var nPatterns: Int
    
    var nProcessedDatasets: Int
    var nProcessedPatterns: Int
   
    public init(nDatasets: Int, nPatterns: Int) {
        self.nDatasets = nDatasets
        self.nPatterns = nPatterns

        self.nProcessedDatasets = 0
        self.nProcessedPatterns = 0
    } 
    
    public func nextPattern() {
       self.nProcessedPatterns += 1
    } 

    public func nextDataset() { // nPatterns: Int
       self.nProcessedDatasets += 1
       // self.nPatterns = nPatterns
       // self.nProcessedPatterns = 0
    }

    // public func getNmodels() -> Int {
    //     self.nModels
    // }

    public func getNpatterns() -> Int {
        self.nPatterns
    }

    public func getNprocessedDatasets() -> Int {
        self.nProcessedDatasets
    }

    public func getNprocessedPatterns() -> Int {
        self.nProcessedPatterns
    }

    public func resetNprocessedPatterns() -> Int {
        let nProcessedPatternsCache = nProcessedPatterns
        nProcessedPatterns = 0
        return nProcessedPatternsCache
    }

    // public func setNpatterns(_ value: Int) {
    //     nPatterns = value
    //     self.nProcessedPatterns = 0
    // }

    public var status: String {
        get async {
            "\(self.getNprocessedDatasets()) / \(self.nDatasets) datasets and " +
            "\(self.getNprocessedPatterns()) / \(self.getNpatterns()) patterns for the current dataset are handled"
        }
    }
}

public class TelegramAdapter {
    private let token: String
    private let bot: TelegramBot
    private let router: Router
    private var keepFetchingUpdates: Bool
    private var handledFirstStop: Bool
    private var tracker: ProgressTracker

    private var linkedChatIds: Set<Int64>

    private var nMaxStartAttempts: Int
    private var nWastedStartAttempts: [Int64: Int]
    private let secret: String?

    public init(token: String? = nil, tracker: ProgressTracker, nMaxStartAttempts: Int = 3, secret: String? = nil) throws {
        keepFetchingUpdates = true
        handledFirstStop = false

        let token_ = token ?? readToken(from: "EMBEDDABOT_TOKEN")
        self.token = token_
        let bot_ = TelegramBot(token: token_)
        self.bot = bot_
        self.tracker = tracker

        self.nWastedStartAttempts = [Int64: Int]()
        self.nMaxStartAttempts = nMaxStartAttempts
        // print(secret)
        self.secret = secret

        linkedChatIds = Set<Int64>()

        router = Router(bot: bot_)
       
        if let mainChatId = ProcessInfo.processInfo.environment["EMBEDDABOT_MAIN_CHAT_ID"] {
            linkedChatIds.insert(Int64(mainChatId)!)
        }

        router["start"] = start
        router["exit"] = exit
        router["status"] = status
        router["stop"] = stop
    }

    private func IfStarted(_ context: Context, run: () -> Bool) -> Bool {
        if linkedChatIds.contains(context.chatId!) {
            return run()
        } else {
            context.respondAsync("Only authenticated users are allowed to do this")
            return true
        }
    }

    private func start(context: Context) -> Bool {
        if !handledFirstStop {
            handledFirstStop = true
        }

        if linkedChatIds.contains(context.message!.from!.id) {
            context.respondAsync("Already started")
        } else {
            if let _ = secret {
                context.respondAsync("Ok, to start send me the secret")
                nWastedStartAttempts[context.message!.from!.id] = 0
            } else {
                context.respondAsync("Welcome back, \(context.message!.from!.firstName)!")
                linkedChatIds.insert(context.message!.from!.id)
            }
        }

        // for i in 0..<N_MAX_START_ATTEMPTS {
        //     if let message = update.message, let text = message.text, let from = message.from, text == "secret" {
        //     } else {
        //         bot.sendMessageAsync(
        //             chatId: .chat(from.id),
        //             text: "No, that wasn't correct. Please, try again"
        //         )
        //     }
        //     if let update = bot.nextUpdateSync() {
        //     }
        // }

        return true
    }

    public func stop(context: Context) -> Bool {
        IfStarted(context) {
            linkedChatIds.remove(context.chatId!)
            context.respondAsync("Successfully signed out")
            return true
        }
    }

    private func status(context: Context) -> Bool {
        IfStarted(context) {
            Task {
                context.respondAsync("\(context.update.message!.from!.firstName), \(await self.tracker.status)")
            }

            if !handledFirstStop {
                handledFirstStop = true
            }

            return true
        }
    }

    private func exit(context: Context) -> Bool {
        IfStarted(context) {
            if handledFirstStop {
                context.respondSync("Bye!")
                keepFetchingUpdates = false
            } else {
                handledFirstStop = true
            }

            return true
        }
    }

    public func broadcast(_ message: String) {
        _ = linkedChatIds.map { chatId in
            bot.sendMessageAsync(
                chatId: .chat(chatId),
                text: message,
                parseMode: .markdown
            )
        }
    }

    public func run() async throws {
        while keepFetchingUpdates {
            if let update = bot.nextUpdateSync() {
                if let message = update.message, let from = message.from, let nWastedAttempts = nWastedStartAttempts[from.id] {
                    if let message = update.message, let text = message.text, text == secret {
                        bot.sendMessageAsync(
                            chatId: .chat(from.id),
                            text: "Yes, you are right. Welcome"
                        )
                        nWastedStartAttempts.removeValue(forKey: from.id)
                        linkedChatIds.insert(from.id)
                    } else {
                        let nWastedAttemptsUpdated = nWastedAttempts + 1
                        if nWastedAttemptsUpdated < nMaxStartAttempts {
                            bot.sendMessageAsync(
                                chatId: .chat(from.id),
                                text: "No, that wasn't correct. Please, try again. You've got \(nMaxStartAttempts - nWastedAttemptsUpdated) more attempts"
                            )
                            nWastedStartAttempts[from.id] = nWastedAttemptsUpdated
                        } else {
                            bot.sendMessageAsync(
                                chatId: .chat(from.id),
                                text: "Unfortunately, you ran out of start attempts. Please, try again"
                            )
                            nWastedStartAttempts.removeValue(forKey: from.id)
                        }
                    }
                } else {
                    try router.process(update: update)
                }
            }
            // if !keepFetchingUpdates {
            //     break
            // }
            // if let message = update.message, let from = message.from, let text = message.text {
            //     bot.sendMessageAsync(
            //         chatId: .chat(from.id),
            //         text: "Hi \(from.firstName)! You said: \(text).\n"
            //     )
            // }
        }
    }
}

