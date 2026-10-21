// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// SASL XOAUTH2 initial client response (RFC 7628, as used by Google IMAP and SMTP).
///
/// The raw bytes are `user={user}\u{1}auth=Bearer {token}\u{1}\u{1}`. IMAP SASL-IR and SMTP
/// `AUTH XOAUTH2` then base64-encode those bytes. This type does not store or log the token.
public enum XOAuth2 {
    public static func saslString(username: String, accessToken: String) -> String {
        "user=\(username)\u{1}auth=Bearer \(accessToken)\u{1}\u{1}"
    }

    public static func saslBytes(username: String, accessToken: String) -> Data {
        Data(saslString(username: username, accessToken: accessToken).utf8)
    }

    public static func saslBase64(username: String, accessToken: String) -> String {
        saslBytes(username: username, accessToken: accessToken).base64EncodedString()
    }
}

/// SASL PLAIN initial response (RFC 4616): `\0username\0password`, then base64.
public enum SASLPlain {
    public static func bytes(username: String, password: String) -> Data {
        var data: Data = Data([0])
        data.append(Data(username.utf8))
        data.append(Data([0]))
        data.append(Data(password.utf8))
        return data
    }

    public static func base64(username: String, password: String) -> String {
        bytes(username: username, password: password).base64EncodedString()
    }
}
