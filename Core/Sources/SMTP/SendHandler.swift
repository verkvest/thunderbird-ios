// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import NIOCore
import NIOSSL

final class SendHandler: ChannelInboundHandler, @unchecked Sendable {
    let email: Email
    let recipient: EmailAddress
    let server: Server

    init(_ email: Email, recipient: EmailAddress?, server: Server, done: EventLoopPromise<Void>) {
        self.email = email
        self.recipient = recipient ?? email.recipients.first ?? ""
        self.server = server
        self.done = done
        stepper = SMTPStepper(
            security: server.connectionSecurity,
            authentication: server.authentication,
            hostname: server.hostname,
            username: server.username,
            secret: server.password,
            email: email,
            recipient: self.recipient
        )
        if self.recipient.value.isEmpty {
            fail(SMTPError.emailRecipientNotFound)
        }
    }

    private let done: EventLoopPromise<Void>
    private var stepper: SMTPStepper
    private var finished: Bool = false

    private func send(context: ChannelHandlerContext, command: Request) {
        context.writeAndFlush(wrapOutboundOut(command)).cascadeFailure(to: done)
    }

    private func fail(_ error: Error) {
        guard !finished else { return }
        finished = true
        done.fail(error)
    }

    private func perform(_ action: SMTPStepper.Action, context: ChannelHandlerContext) {
        switch action {
        case .send(let request):
            send(context: context, command: request)
        case .installTLS:
            context.channel.eventLoop.makeCompletedFuture {
                try context.channel.pipeline.syncOperations.addHandler(
                    try NIOSSLClientHandler(context: .ssl, serverHostname: server.hostname),
                    position: .first
                )
            }.whenComplete { result in
                switch result {
                case .failure(let error):
                    self.fail(error)
                case .success:
                    self.perform(self.stepper.afterTLSInstalled(), context: context)
                }
            }
        case .finished:
            finished = true
            done.succeed()
            context.close(promise: nil)
        }
    }

    // MARK: ChannelInboundHandler
    typealias OutboundIn = Email
    typealias OutboundOut = Request
    typealias InboundIn = Response

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        switch unwrapInboundIn(data) {
        case .error(let error):
            fail(SMTPError.response(error))
        case .ok:
            guard !finished else { return }
            perform(stepper.receiveOK(), context: context)
        }
    }

    func channelInactive(context: ChannelHandlerContext) {
        fail(SMTPError.remoteConnectionClosed)
    }

    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        fail(error)
        context.close(promise: nil)
    }
}

private extension NIOSSLContext {
    static var ssl: Self { try! Self(configuration: .makeClientConfiguration()) }
}
