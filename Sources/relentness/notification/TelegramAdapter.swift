import Foundation
import TelegramBotSDK

public actor ProgressTracker {
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
}

public class TelegramAdapter {
    private let token: String
    private let bot: TelegramBot
    private let router: Router
    private var keepFetchingUpdates: Bool
    private var handledFirstStop: Bool
    private var tracker: ProgressTracker

    public init(token: String? = nil, tracker: ProgressTracker) throws {
        keepFetchingUpdates = true
        handledFirstStop = false

        let token_ = token ?? readToken(from: "EMBEDDABOT_TOKEN")
        self.token = token_
        let bot_ = TelegramBot(token: token_)
        self.bot = bot_
        self.tracker = tracker

        router = Router(bot: bot_)

        router["start"] = start
        router["stop"] = stop
        router["status"] = status
        

        // router = router_
    }

    private func start(context: Context) -> Bool {
        context.respondAsync("Ok, let's start")
        if !handledFirstStop {
            handledFirstStop = true
        }

        return true
    }

    private func status(context: Context) -> Bool {
        Task {
            context.respondAsync("\(context.update.message!.from!.firstName), \(await self.tracker.getNprocessedModels()) / \(self.tracker.nModels) models and " +
                                 "\(await self.tracker.getNprocessedHyperParameterSets()) / \(await self.tracker.getNhyperParameterSets()) hyperparameters sets for the " +
                                 "\((await self.tracker.getNprocessedModels()) + 1) model handled"
            )
        }

        if !handledFirstStop {
            handledFirstStop = true
        }

        return true
    }

    private func stop(context: Context) -> Bool {
        if handledFirstStop {
            context.respondSync("Bye!")
            keepFetchingUpdates = false
        } else {
            handledFirstStop = true
        }

        return true
    }

    public func run() async throws {
        while keepFetchingUpdates {
            if let update = bot.nextUpdateSync() {
                try router.process(update: update)
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

