import Foundation
import Testing
@testable import Neo_Stride_ios

struct AppConfigTests {
    @Test func defaultBaseURLPointsToConfiguredDevelopmentServer() throws {
        let config = AppConfig.default

        #expect(config.baseURL.scheme == "http" || config.baseURL.scheme == "https")
        #expect(config.baseURL.absoluteString == "http://yuni2.iptime.org:8080/")
    }

    @Test func customBaseURLStringNormalizesTrailingSlash() throws {
        let config = try AppConfig(baseURLString: "https://api.example.com")

        #expect(config.baseURL.absoluteString == "https://api.example.com/")
    }
}
