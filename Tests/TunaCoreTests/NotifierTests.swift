import TunaCore
import XCTest

final class NotifierTests: XCTestCase {
    func testPostRunsOnMainActor() async {
        let exp = expectation(description: "main")
        await Notifier.post(Notification.Name("dummy"))
        XCTAssert(Thread.isMainThread)
        exp.fulfill()
        await fulfillment(of: [exp], timeout: 0.1)
    }
}
