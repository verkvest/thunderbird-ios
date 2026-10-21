// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation
import MIME

/// Scripted SMTP client dialogue. `SendHandler` follows it on the wire, and tests
/// drive it with a server that answers every command with a positive completion.
struct SMTPStepper {
    let security: ConnectionSecurity
    let authentication: Server.Authentication
    let hostname: String
    let username: String
    let secret: String
    let email: Email
    let recipient: EmailAddress

    private(set) var phase: Phase = .greeting

    enum Phase: Equatable {
        case greeting
        case ehlo
        case startTLS
        case tlsInstalled
        case ehloSecure
        case authLogin
        case authUser
        case authSecret
        case mailFrom
        case rcpt
        case data
        case body
        case quit
        case done
    }

    enum Action {
        case send(Request)
        case installTLS
        case finished
    }

    /// A positive SMTP reply arrived. Returns the next client action.
    mutating func receiveOK() -> Action {
        switch phase {
        case .greeting:
            phase = .ehlo
            return .send(.hello(hostname))
        case .ehlo:
            if security == .startTLS {
                phase = .startTLS
                return .send(.startTLS)
            }
            return beginAuth()
        case .startTLS:
            phase = .tlsInstalled
            return .installTLS
        case .tlsInstalled:
            return afterTLSInstalled()
        case .ehloSecure:
            return beginAuth()
        case .authLogin:
            phase = .authUser
            return .send(.authUser(username))
        case .authUser:
            phase = .authSecret
            return .send(.authPassword(secret))
        case .authSecret:
            phase = .mailFrom
            return .send(.mailFrom(email.sender))
        case .mailFrom:
            phase = .rcpt
            return .send(.recipient(recipient))
        case .rcpt:
            phase = .data
            return .send(.data)
        case .data:
            phase = .body
            return .send(.transferData(email))
        case .body:
            phase = .quit
            return .send(.quit)
        case .quit:
            phase = .done
            return .finished
        case .done:
            return .finished
        }
    }

    /// Called after the TLS handler is in the pipeline. RFC 3207 requires a new EHLO.
    mutating func afterTLSInstalled() -> Action {
        phase = .ehloSecure
        return .send(.hello(hostname))
    }

    /// Every client command a cooperative server would see, including the EHLO after STARTTLS.
    mutating func script() -> [Action] {
        var actions: [Action] = []
        var action: Action = receiveOK()
        while true {
            switch action {
            case .finished:
                return actions
            case .installTLS:
                actions.append(action)
                action = afterTLSInstalled()
            case .send:
                actions.append(action)
                action = receiveOK()
            }
        }
    }

    private mutating func beginAuth() -> Action {
        switch authentication {
        case .login:
            phase = .authLogin
            return .send(.authLogin)
        case .plain:
            phase = .authSecret
            return .send(.authPlain(SASLPlain.base64(username: username, password: secret)))
        case .xoauth2:
            phase = .authSecret
            return .send(.authXOAuth2(XOAuth2.saslBase64(username: username, accessToken: secret)))
        }
    }
}
