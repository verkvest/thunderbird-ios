// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MIME
import NIOCore
import NIOIMAP

/// `AUTHENTICATE XOAUTH2` with a SASL initial response (SASL-IR, RFC 4959).
struct AuthenticateCommand: IMAPCommand {
    let username: String
    let accessToken: String

    // MARK: IMAPCommand
    typealias Result = [Capability]
    typealias Handler = CapabilityHandler

    var name: String { "authenticate XOAUTH2" }

    func tagged(_ tag: String) -> NIOIMAPCore.TaggedCommand {
        var buffer: ByteBuffer = ByteBuffer()
        buffer.writeBytes(XOAuth2.saslBytes(username: username, accessToken: accessToken))
        let mechanism: AuthenticationMechanism = AuthenticationMechanism("XOAUTH2")!
        return TaggedCommand(tag: tag, command: .authenticate(mechanism: mechanism, initialResponse: InitialResponse(buffer)))
    }
}
