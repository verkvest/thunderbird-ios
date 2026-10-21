// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import AuthenticationServices

/// Globally manage shared, persistent accounts from the SwiftUI environment.
@MainActor
@Observable
public final class AccountManager {
    public private(set) var allAccounts: [Account] = []
    public var error: AccountError?

    public func account(for id: UUID) -> Account? {
        allAccounts.filter({ $0.id == id }).first
    }

    public func set(_ account: Account, at index: Int? = nil) {
        error = nil
        do {
            var accounts: [Account] = allAccounts
            let currentIndex: Int? = accounts.firstIndex { account.id == $0.id }
            if let currentIndex {
                accounts.remove(at: currentIndex)
            }
            let index: Int? = index ?? currentIndex  // New index OR current index OR nil (append to end)
            if let index, index < accounts.count {
                accounts.insert(account, at: index)  // Insert at new or current target index
            } else {
                accounts.append(account)  // Append to end of array
            }
            allAccounts = accounts
            try FileManager.default.write(accounts, to: .accounts)
            allAccounts = try FileManager.default.readAccounts(from: .accounts)
        } catch {
            self.error = .fileManager(error)
        }
    }

    public func hasLoggedInAccount() -> Bool {
        for account in allAccounts {
            if account.authorization.isExpired == false {
                return true
            }
        }
        return false
    }

    public func delete(_ account: Account) {
        error = nil
        do {
            account.deleteAuthorization()
            let updatedAccounts = allAccounts.filter { $0.id != account.id }
            try FileManager.default.write(updatedAccounts, to: .accounts)
            allAccounts = updatedAccounts
            allAccounts = try FileManager.default.readAccounts(from: .accounts)
        } catch {
            self.error = .fileManager(error)
        }
    }

    public func deleteAccounts() {
        error = nil
        do {
            URLCredentialStorage.shared.deleteAuthorizations()
            try FileManager.default.write([], to: .accounts)
            allAccounts = []
        } catch {
            self.error = .fileManager(error)
        }
    }

    public func checkAndRenewExpirations() async {
        for account in allAccounts {
            guard account.authenticationType == .oAuth2, account.authorization.isExpired,
                let refreshToken: String = account.authorization.refreshToken,
                let user: String = account.incomingServer?.username
            else {
                continue
            }
            do {
                var account: Account = account
                guard let authConfig: OAuth2.Configuration = try await account.authConfig else {
                    throw URLError(.unsupportedURL)
                }
                account.authorization = try await renewExpiredToken(
                    authConfig: authConfig,
                    refreshToken: refreshToken,
                    user: user
                )
            } catch {
                self.error = .authorization(error)
            }
        }
    }

    private func renewExpiredToken(authConfig: OAuth2.Configuration, refreshToken: String, user: String, retry attempts: Int = 2) async throws -> Authorization {
        do {
            let tokenRequest: URLRequest = try .refreshToken(
                authConfig,
                refreshToken: refreshToken
            )
            let data: Data = try await URLSession.shared.data(for: tokenRequest).0
            let response: RefreshTokenResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
            let token: Token = .bearer(
                response.accessToken,
                Date(timeIntervalSinceNow: TimeInterval(response.expiresIn))
            )
            return .oauth(user: user, token: token, refresh: .refresh(refreshToken))
        } catch {
            guard attempts > 0 else {
                throw error  // Retry attempts exhausted, exit
            }
            // Retry request, decrementing remaining attempts
            return try await renewExpiredToken(
                authConfig: authConfig,
                refreshToken: refreshToken,
                user: user,
                retry: attempts - 1
            )
        }
    }

    public init() {
        do {
            guard try FileManager.default.fileExists(at: .accounts) else { return }
            allAccounts = try FileManager.default.readAccounts(from: .accounts)
        } catch {
            self.error = .fileManager(error)
        }
    }
}
