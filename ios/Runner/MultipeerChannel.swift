import Flutter
import Foundation
import MultipeerConnectivity
import os.log

/// Platform channel handler for iOS Multipeer Connectivity.
///
/// Bridges Dart <-> MCSession / MCNearbyServiceAdvertiser / MCNearbyServiceBrowser using:
/// - FlutterMethodChannel "com.redgrid.link/multipeer" for RPC calls
/// - FlutterEventChannel  "com.redgrid.link/multipeer/events" for async events
///
/// Service type: "red-grid-link" (must be <= 15 chars, lowercase + hyphens).
class MultipeerChannel: NSObject {

    // MARK: - Constants

    private static let methodChannelName = "com.redgrid.link/multipeer"
    private static let eventChannelName = "com.redgrid.link/multipeer/events"
    private static let serviceType = "red-grid-link"

    private let log = OSLog(subsystem: "com.redgrid.link", category: "MultipeerChannel")

    // MARK: - Flutter channels

    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    // MARK: - Multipeer Connectivity

    private var localPeerID: MCPeerID?
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    /// Maps peer display name -> MCPeerID for lookup when Dart sends commands by ID string.
    private var discoveredPeers: [String: MCPeerID] = [:]

    /// Tracks which peers are connected.
    private var connectedPeers: [String: MCPeerID] = [:]

    /// Pending invitation handlers keyed by peer display name.
    private var pendingInvitations: [String: (Bool, MCSession?) -> Void] = [:]

    /// Current session ID from Dart.
    private var currentSessionId: String?

    // MARK: - Registration

    func register(with messenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(
            name: MultipeerChannel.methodChannelName,
            binaryMessenger: messenger
        )
        methodChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }

        eventChannel = FlutterEventChannel(
            name: MultipeerChannel.eventChannelName,
            binaryMessenger: messenger
        )
        eventChannel?.setStreamHandler(self)

        os_log("MultipeerChannel registered", log: log, type: .info)
    }

    func unregister() {
        methodChannel?.setMethodCallHandler(nil)
        methodChannel = nil
        eventChannel?.setStreamHandler(nil)
        eventChannel = nil
        eventSink = nil
        tearDown()
    }

    // MARK: - Method dispatch

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startAdvertising":
            startAdvertising(call, result: result)
        case "startBrowsing":
            startBrowsing(call, result: result)
        case "stopAdvertising":
            stopAdvertising(result: result)
        case "stopBrowsing":
            stopBrowsing(result: result)
        case "invitePeer":
            invitePeer(call, result: result)
        case "acceptInvite":
            acceptInvite(call, result: result)
        case "rejectInvite":
            rejectInvite(call, result: result)
        case "sendData":
            sendData(call, result: result)
        case "disconnect":
            disconnect(call, result: result)
        case "disconnectAll":
            disconnectAll(result: result)
        case "getConnectedPeers":
            getConnectedPeers(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Advertising

    private func startAdvertising(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Arguments must be a map", details: nil))
            return
        }

        let displayName = args["displayName"] as? String ?? UIDevice.current.name
        let sessionId = args["sessionId"] as? String
        currentSessionId = sessionId

        // Create peer ID and session if not already created
        ensureSession(displayName: displayName)

        guard let localPeerID = localPeerID else {
            result(FlutterError(code: "INTERNAL_ERROR", message: "Failed to create local peer ID", details: nil))
            return
        }

        // Build discovery info with session ID
        var discoveryInfo: [String: String]? = nil
        if let sessionId = sessionId {
            discoveryInfo = ["sessionId": sessionId]
        }

        advertiser = MCNearbyServiceAdvertiser(
            peer: localPeerID,
            discoveryInfo: discoveryInfo,
            serviceType: MultipeerChannel.serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()

        os_log("Advertising started (displayName=%{public}@)", log: log, type: .info, displayName)
        result(nil)
    }

    private func stopAdvertising(result: @escaping FlutterResult) {
        advertiser?.stopAdvertisingPeer()
        advertiser?.delegate = nil
        advertiser = nil
        os_log("Advertising stopped", log: log, type: .info)
        result(nil)
    }

    // MARK: - Browsing

    private func startBrowsing(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let displayName = UIDevice.current.name
        ensureSession(displayName: displayName)

        guard let localPeerID = localPeerID else {
            result(FlutterError(code: "INTERNAL_ERROR", message: "Failed to create local peer ID", details: nil))
            return
        }

        browser = MCNearbyServiceBrowser(
            peer: localPeerID,
            serviceType: MultipeerChannel.serviceType
        )
        browser?.delegate = self
        browser?.startBrowsingForPeers()

        os_log("Browsing started", log: log, type: .info)
        result(nil)
    }

    private func stopBrowsing(result: @escaping FlutterResult) {
        browser?.stopBrowsingForPeers()
        browser?.delegate = nil
        browser = nil
        discoveredPeers.removeAll()
        os_log("Browsing stopped", log: log, type: .info)
        result(nil)
    }

    // MARK: - Connection management

    private func invitePeer(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let peerId = args["peerId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "peerId is required", details: nil))
            return
        }

        guard let mcPeerID = discoveredPeers[peerId] else {
            result(FlutterError(code: "PEER_NOT_FOUND", message: "Peer \(peerId) not found in discovered peers", details: nil))
            return
        }

        guard let session = session else {
            result(FlutterError(code: "NO_SESSION", message: "Session not initialized", details: nil))
            return
        }

        // Invite with a 30 second timeout
        browser?.invitePeer(mcPeerID, to: session, withContext: nil, timeout: 30)

        os_log("Invitation sent to %{public}@", log: log, type: .info, peerId)
        result(nil)
    }

    private func acceptInvite(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let peerId = args["peerId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "peerId is required", details: nil))
            return
        }

        guard let handler = pendingInvitations.removeValue(forKey: peerId) else {
            result(FlutterError(code: "NO_INVITATION", message: "No pending invitation from \(peerId)", details: nil))
            return
        }

        handler(true, session)
        os_log("Invitation accepted from %{public}@", log: log, type: .info, peerId)
        result(nil)
    }

    private func rejectInvite(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let peerId = args["peerId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "peerId is required", details: nil))
            return
        }

        guard let handler = pendingInvitations.removeValue(forKey: peerId) else {
            result(FlutterError(code: "NO_INVITATION", message: "No pending invitation from \(peerId)", details: nil))
            return
        }

        handler(false, nil)
        os_log("Invitation rejected from %{public}@", log: log, type: .info, peerId)
        result(nil)
    }

    private func disconnect(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let peerId = args["peerId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "peerId is required", details: nil))
            return
        }

        // MCSession doesn't support disconnecting individual peers.
        // We can only track the removal on our side. The peer will see
        // a state change to .notConnected.
        connectedPeers.removeValue(forKey: peerId)
        os_log("Disconnected from %{public}@", log: log, type: .info, peerId)
        result(nil)
    }

    private func disconnectAll(result: @escaping FlutterResult) {
        session?.disconnect()
        connectedPeers.removeAll()
        os_log("Disconnected from all peers", log: log, type: .info)
        result(nil)
    }

    // MARK: - Data transfer

    private func sendData(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let peerId = args["peerId"] as? String,
              let data = args["data"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_ARGS", message: "peerId and data are required", details: nil))
            return
        }

        guard let mcPeerID = connectedPeers[peerId] else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Peer \(peerId) is not connected", details: nil))
            return
        }

        do {
            try session?.send(data.data, toPeers: [mcPeerID], with: .reliable)
            os_log("Data sent to %{public}@ (%d bytes)", log: log, type: .debug, peerId, data.data.count)
            result(nil)
        } catch {
            os_log("Failed to send data to %{public}@: %{public}@", log: log, type: .error, peerId, error.localizedDescription)
            result(FlutterError(
                code: "SEND_FAILED",
                message: "Failed to send data: \(error.localizedDescription)",
                details: nil
            ))
        }
    }

    private func getConnectedPeers(result: @escaping FlutterResult) {
        let peers = connectedPeers.map { (name, _) in
            ["peerId": name, "peerName": name]
        }
        result(peers)
    }

    // MARK: - Session management

    private func ensureSession(displayName: String) {
        if session != nil { return }

        let peerID = MCPeerID(displayName: displayName)
        localPeerID = peerID

        let newSession = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        newSession.delegate = self
        session = newSession

        os_log("Session created (displayName=%{public}@)", log: log, type: .info, displayName)
    }

    private func tearDown() {
        advertiser?.stopAdvertisingPeer()
        advertiser?.delegate = nil
        advertiser = nil

        browser?.stopBrowsingForPeers()
        browser?.delegate = nil
        browser = nil

        session?.disconnect()
        session?.delegate = nil
        session = nil

        localPeerID = nil
        discoveredPeers.removeAll()
        connectedPeers.removeAll()
        pendingInvitations.removeAll()
        currentSessionId = nil
    }

    // MARK: - Event helpers

    private func sendEvent(_ eventName: String, data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?([
                "event": eventName,
                "data": data,
            ])
        }
    }
}

// MARK: - FlutterStreamHandler

extension MultipeerChannel: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        os_log("EventChannel listener attached", log: log, type: .debug)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        os_log("EventChannel listener detached", log: log, type: .debug)
        return nil
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerChannel: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        let peerName = peerID.displayName
        os_log("Invitation received from %{public}@", log: log, type: .info, peerName)

        // Store the handler so Dart can accept/reject
        pendingInvitations[peerName] = invitationHandler

        sendEvent("onInviteReceived", data: [
            "peerId": peerName,
            "peerName": peerName,
        ])
    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        os_log("Advertising failed: %{public}@", log: log, type: .error, error.localizedDescription)
        sendEvent("onError", data: [
            "source": "advertiser",
            "message": error.localizedDescription,
        ])
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerChannel: MCNearbyServiceBrowserDelegate {
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        let peerName = peerID.displayName
        os_log("Peer found: %{public}@", log: log, type: .info, peerName)

        discoveredPeers[peerName] = peerID

        sendEvent("onPeerFound", data: [
            "peerId": peerName,
            "peerName": peerName,
            "discoveryInfo": info ?? [:],
        ])
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        let peerName = peerID.displayName
        os_log("Peer lost: %{public}@", log: log, type: .info, peerName)

        discoveredPeers.removeValue(forKey: peerName)

        sendEvent("onPeerLost", data: [
            "peerId": peerName,
            "peerName": peerName,
        ])
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        os_log("Browsing failed: %{public}@", log: log, type: .error, error.localizedDescription)
        sendEvent("onError", data: [
            "source": "browser",
            "message": error.localizedDescription,
        ])
    }
}

// MARK: - MCSessionDelegate

extension MultipeerChannel: MCSessionDelegate {
    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        let peerName = peerID.displayName
        let stateString: String

        switch state {
        case .notConnected:
            stateString = "notConnected"
            connectedPeers.removeValue(forKey: peerName)
            os_log("Peer %{public}@ → notConnected", log: log, type: .info, peerName)

        case .connecting:
            stateString = "connecting"
            os_log("Peer %{public}@ → connecting", log: log, type: .info, peerName)

        case .connected:
            stateString = "connected"
            connectedPeers[peerName] = peerID
            os_log("Peer %{public}@ → connected", log: log, type: .info, peerName)

        @unknown default:
            stateString = "unknown"
            os_log("Peer %{public}@ → unknown state", log: log, type: .error, peerName)
        }

        sendEvent("onSessionStateChanged", data: [
            "peerId": peerName,
            "peerName": peerName,
            "state": stateString,
        ])
    }

    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        let peerName = peerID.displayName
        os_log("Data received from %{public}@ (%d bytes)", log: log, type: .debug, peerName, data.count)

        sendEvent("onDataReceived", data: [
            "peerId": peerName,
            "peerName": peerName,
            "data": FlutterStandardTypedData(bytes: data),
        ])
    }

    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        // Stream-based transfers not used by Field Link.
        os_log("Stream received from %{public}@ (ignored)", log: log, type: .debug, peerID.displayName)
    }

    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        // Resource transfers not used by Field Link.
        os_log("Resource transfer started from %{public}@ (ignored)", log: log, type: .debug, peerID.displayName)
    }

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {
        // Resource transfers not used by Field Link.
        os_log("Resource transfer finished from %{public}@ (ignored)", log: log, type: .debug, peerID.displayName)
    }
}
