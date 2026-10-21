// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MIME
import Testing

struct XOAuth2Tests {
    @Test func saslInitialResponse() {
        let username: String = "user@example.com"
        let token: String = "ya29.a0example"
        let raw: String = "user=\(username)\u{1}auth=Bearer \(token)\u{1}\u{1}"
        #expect(XOAuth2.saslString(username: username, accessToken: token) == raw)
        #expect(XOAuth2.saslBytes(username: username, accessToken: token) == Data(raw.utf8))
        #expect(XOAuth2.saslBase64(username: username, accessToken: token) == "dXNlcj11c2VyQGV4YW1wbGUuY29tAWF1dGg9QmVhcmVyIHlhMjkuYTBleGFtcGxlAQE=")
    }

    @Test func plainInitialResponse() {
        let bytes: Data = SASLPlain.bytes(username: "user@example.com", password: "secret")
        #expect(bytes == Data([0]) + Data("user@example.com".utf8) + Data([0]) + Data("secret".utf8))
        #expect(SASLPlain.base64(username: "user@example.com", password: "secret") == "AHVzZXJAZXhhbXBsZS5jb20Ac2VjcmV0")
    }
}
