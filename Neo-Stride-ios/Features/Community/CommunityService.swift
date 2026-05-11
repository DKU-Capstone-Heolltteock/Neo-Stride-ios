import Foundation

protocol CommunityServiceProtocol {
    func uploadFeed(_ request: CommunityFeedUploadRequest) async throws -> CommunityFeedUploadResponse
    func fetchFeeds() async throws -> [CommunityFeedUploadResponse]
    func fetchFriendList(status: CommunityFriendStatus) async throws -> [CommunityFriendResponse]
    func updateRelationship(_ request: CommunityFriendActionRequest) async throws
    func fetchMyProfile() async throws -> CommunityUserProfileResponse
    func updateStatusMessage(_ statusMessage: String) async throws
    func updateProfileImage(data: Data, fileName: String, mimeType: String) async throws
    func fetchMyFeeds() async throws -> [CommunityContentResponse]
    func fetchTaggedFeeds() async throws -> [CommunityContentResponse]
    func fetchCommentedFeeds() async throws -> [CommunityContentResponse]
    func fetchLikedFeeds() async throws -> [CommunityContentResponse]
    func fetchBookmarkedFeeds() async throws -> [CommunityContentResponse]
    func fetchBadgeDetail() async throws -> CommunityBadgeDetailResponse
}

final class CommunityService: CommunityServiceProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func uploadFeed(_ request: CommunityFeedUploadRequest) async throws -> CommunityFeedUploadResponse {
        try await apiClient.send(APIEndpoint(method: "POST", path: "/feeds"), body: request)
    }

    func fetchFeeds() async throws -> [CommunityFeedUploadResponse] {
        try await apiClient.send(APIEndpoint(method: "GET", path: "/feeds"))
    }

    func fetchFriendList(status: CommunityFriendStatus) async throws -> [CommunityFriendResponse] {
        try await apiClient.send(APIEndpoint(
            method: "GET",
            path: "community/friends",
            queryItems: [URLQueryItem(name: "status", value: status.rawValue)]
        ))
    }

    func updateRelationship(_ request: CommunityFriendActionRequest) async throws {
        let _: EmptyResponse = try await apiClient.send(
            APIEndpoint(method: "POST", path: "community/friends/action"),
            body: request
        )
    }

    func fetchMyProfile() async throws -> CommunityUserProfileResponse {
        try await apiClient.send(APIEndpoint(method: "GET", path: "users/me/profile"))
    }

    func updateStatusMessage(_ statusMessage: String) async throws {
        let _: EmptyResponse = try await apiClient.send(
            APIEndpoint(method: "PATCH", path: "users/me/status"),
            body: ["status_message": statusMessage]
        )
    }

    func updateProfileImage(data: Data, fileName: String, mimeType: String) async throws {
        let _: EmptyResponse = try await apiClient.sendMultipart(
            APIEndpoint(method: "PATCH", path: "users/me/profile-image"),
            fieldName: "image",
            fileName: fileName,
            mimeType: mimeType,
            data: data
        )
    }

    func fetchMyFeeds() async throws -> [CommunityContentResponse] {
        try await apiClient.send(APIEndpoint(method: "GET", path: "community/contents/me"))
    }

    func fetchTaggedFeeds() async throws -> [CommunityContentResponse] {
        try await apiClient.send(APIEndpoint(method: "GET", path: "community/contents/tagged"))
    }

    func fetchCommentedFeeds() async throws -> [CommunityContentResponse] {
        try await apiClient.send(APIEndpoint(method: "GET", path: "community/contents/comments"))
    }

    func fetchLikedFeeds() async throws -> [CommunityContentResponse] {
        try await apiClient.send(APIEndpoint(method: "GET", path: "community/contents/likes"))
    }

    func fetchBookmarkedFeeds() async throws -> [CommunityContentResponse] {
        try await apiClient.send(APIEndpoint(method: "GET", path: "community/contents/bookmarks"))
    }

    func fetchBadgeDetail() async throws -> CommunityBadgeDetailResponse {
        try await apiClient.send(APIEndpoint(method: "GET", path: "users/me/badge"))
    }
}
