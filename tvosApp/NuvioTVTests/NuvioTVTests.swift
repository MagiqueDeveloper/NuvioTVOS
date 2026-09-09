import XCTest
import NuvioDomain

final class NuvioTVTests: XCTestCase {
    func testRewriteDomainScenarioPlaceholder() {
        let url = URL(string: "nuvio-tv://title?id=sample-1&type=movie")!
        XCTAssertEqual(DeepLink(url: url)?.url?.scheme, "nuvio-tv")
    }
}
