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
        assignClientToBankClerk()
        closeBank(totalProcessingTime: Date().timeIntervalSince(taskStartedTime))
    }
    
    private func assignClientToBankClerk() {
        let group = DispatchGroup()
        
        bankers.filter { $0.service == .deposit }.forEach { banker in
            assignWorkToBankClerk(
                group: group,
                queue: customersQueue[.deposit] ?? Queue<Customer>(),
                banker: banker
            )
        }
        
        bankers.filter { $0.service == .loan }.forEach { banker in
            assignWorkToBankClerk(
                group: group,
                queue: customersQueue[.loan] ?? Queue<Customer>(),
                banker: banker
            )
        }
        
        group.wait()
    }
    
    private func assignWorkToBankClerk(
        group: DispatchGroup,
        queue: Queue<Customer>,
        banker: Banker
    ) {
        DispatchQueue.global().async(group: group) {
            while let customer = queue.dequeue() {
                banker.taskProcess(customer: customer)
            }
        }
    }
 
    // MARK: - 기존 리펙토링 한 코드
//    private func processingTasks() {
//        for banker in bankers {
//            group.enter()
//            DispatchQueue.global().async { [weak self] in
//                switch banker.service {
//                case .deposit:
//                    self?.depositTask(banker: banker)
//                case .loan:
//                    self?.loanTask(banker: banker)
//                }
//                self?.group.leave()
//            }
//        }
//        group.wait()
//    }
//    
//    private func depositTask(banker: Banker) {
//        depositSemaphore.wait()
//        if let depositQueue = customersQueue[.deposit] {
//            banker.taskProcess(queue: depositQueue)
//        }
//        depositSemaphore.signal()
//    }
//    
//    private func loanTask(banker: Banker) {
//        if let loanQueue = customersQueue[.loan] {
//            banker.taskProcess(queue: loanQueue)
//        }
//    }
    
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
