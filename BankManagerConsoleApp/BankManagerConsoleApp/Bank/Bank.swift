import Foundation

final class Bank: PrintableMessage {
    private var bankers: [Banker]
    private var customersQueue: [BankingService: Queue<Customer>] = [:]
    private let depositSemaphore: DispatchSemaphore
    private let group = DispatchGroup()
    
    init(bankers: [Banker], depositSemaphore: DispatchSemaphore, customersQueue: [BankingService: Queue<Customer>]) {
        self.bankers = bankers
        self.depositSemaphore = depositSemaphore
        self.customersQueue = customersQueue
    }
    
    func openBank() {
        let taskStartedTime: Date = Date()
        generateCustomerQueue()
        
        for banker in bankers {
            group.enter()
            
            DispatchQueue.global().async { [weak self] in
                switch banker.service {
                case .deposit:
                    self?.depositSemaphore.wait()
                    if let depositQueue = self?.customersQueue[.deposit] {
                        banker.taskProcess(queue: depositQueue)
                    }
                    self?.depositSemaphore.signal()
                case .loan:
                    if let loanQueue = self?.customersQueue[.loan] {
                        banker.taskProcess(queue: loanQueue)
                    }
                }
                self?.group.leave()
            }
        }
        group.wait()
        closeBank(totalProcessingTime: Date().timeIntervalSince(taskStartedTime))
    }
    
    private func generateCustomerQueue() {
        let waitingNumber = Int.random(in: 10...30)
        for num in 1...waitingNumber {
            let randomBankingService = BankingService.randomBankingService
            if let queue = customersQueue[randomBankingService] {
                queue.enqueue(value: Customer(waitingNumber: num, taskType: randomBankingService))
            }
        }
    }
    
    private func closeBank(totalProcessingTime: Double) {
        let totalCustomersCount = bankers.reduce(0) { $0 + $1.customersCount }
        printClosingMessage(customersCount: totalCustomersCount, totalProcessingTime: totalProcessingTime)
        resetBankers()
    }
    
    private func resetBankers() {
        for banker in bankers {
            banker.resetProcessingCount()
        }
    }
}
