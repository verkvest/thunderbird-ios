// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import NIOCore
@testable import SMTP
import Testing

struct SMTPStepperTests {
    @Test func implicitTLSAuthLogin() throws {
        var stepper: SMTPStepper = sample(.tls, .login)
        let lines: [String] = try commands(&stepper)
        #expect(
            lines == [
                "EHLO smtp.example.com\r\n",
                "AUTH LOGIN\r\n",
                "dXNlckBleGFtcGxlLmNvbQ==\r\n",
                "c2VjcmV0\r\n",
                "MAIL FROM:<sender@example.com>\r\n",
                "RCPT TO:<recipient@example.com>\r\n",
                "DATA\r\n",
                "DATA-BODY",
                "QUIT\r\n"
            ]
        )
    }

    @Test func startTLSAuthPlain() throws {
        var stepper: SMTPStepper = sample(.startTLS, .plain)
        let lines: [String] = try commands(&stepper)
        #expect(lines.first == "EHLO smtp.example.com\r\n")
        #expect(lines.dropFirst().first == "STARTTLS\r\n")
        #expect(lines.filter { $0.hasPrefix("EHLO") }.count == 2)
        #expect(lines.contains("AUTH PLAIN AHVzZXJAZXhhbXBsZS5jb20Ac2VjcmV0\r\n"))
        #expect(lines.contains("MAIL FROM:<sender@example.com>\r\n"))
        #expect(lines.last == "QUIT\r\n")
        #expect(!lines.contains("AUTH LOGIN\r\n"))
    }

    @Test func implicitTLSAuthXOAuth2() throws {
        var stepper: SMTPStepper = sample(.tls, .xoauth2, secret: "ya29.a0example")
        let lines: [String] = try commands(&stepper)
        #expect(lines.contains("AUTH XOAUTH2 dXNlcj11c2VyQGV4YW1wbGUuY29tAWF1dGg9QmVhcmVyIHlhMjkuYTBleGFtcGxlAQE=\r\n"))
        #expect(!lines.contains("STARTTLS\r\n"))
        #expect(lines.contains("DATA\r\n"))
    }

    @Test func messageDataMatchesEncoder() throws {
        let email: Email = sampleEmail()
        var buffer: ByteBuffer = ByteBuffer()
        try RequestEncoder().encode(data: .transferData(email), out: &buffer)
        let encoded: String = buffer.readString(length: buffer.readableBytes) ?? ""
        let saved: String = String(decoding: email.messageData, as: UTF8.self)
        #expect(encoded.hasSuffix("\r\n.\r\n"))
        #expect(encoded.hasPrefix(saved))
    }
}

private func sample(_ security: ConnectionSecurity, _ authentication: Server.Authentication, secret: String = "secret") -> SMTPStepper {
    SMTPStepper(
        security: security,
        authentication: authentication,
        hostname: "smtp.example.com",
        username: "user@example.com",
        secret: secret,
        email: sampleEmail(),
        recipient: "recipient@example.com"
    )
}

private func sampleEmail() -> Email {
    Email(sender: "sender@example.com", recipients: ["recipient@example.com"], subject: "Hello", body: .empty, id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!)
}

private func commands(_ stepper: inout SMTPStepper) throws -> [String] {
    try stepper.script().map { action in
        guard case .send(let request) = action else { return "TLS" }
        if case .transferData = request { return "DATA-BODY" }
        var buffer: ByteBuffer = ByteBuffer()
        try RequestEncoder().encode(data: request, out: &buffer)
        return buffer.readString(length: buffer.readableBytes) ?? ""
    }
}
