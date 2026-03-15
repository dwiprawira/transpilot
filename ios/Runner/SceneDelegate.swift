import Flutter
import UIKit
import UniformTypeIdentifiers

class SceneDelegate: FlutterSceneDelegate {
  private var eventSink: FlutterEventSink?
  private var initialTorrent: [String: Any]?
  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    configureChannelsIfNeeded()

    if let url = connectionOptions.urlContexts.first?.url {
      handleIncomingTorrent(url, preferInitialStorage: true)
    }
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    configureChannelsIfNeeded()
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    guard let url = URLContexts.first?.url else {
      return
    }
    handleIncomingTorrent(url, preferInitialStorage: false)
  }

  private func configureChannelsIfNeeded() {
    guard methodChannel == nil, let flutterViewController = window?.rootViewController as? FlutterViewController else {
      return
    }

    let messenger = flutterViewController.binaryMessenger
    let methodChannel = FlutterMethodChannel(
      name: "com.transpilot.app/incoming_torrent_method",
      binaryMessenger: messenger
    )
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "takeInitialTorrent" else {
        result(FlutterMethodNotImplemented)
        return
      }

      result(self?.initialTorrent)
      self?.initialTorrent = nil
    }

    let eventChannel = FlutterEventChannel(
      name: "com.transpilot.app/incoming_torrent_events",
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(self)

    self.methodChannel = methodChannel
    self.eventChannel = eventChannel
  }

  private func handleIncomingTorrent(_ url: URL, preferInitialStorage: Bool) {
    if let scheme = url.scheme, scheme.caseInsensitiveCompare("magnet") == .orderedSame {
      let payload: [String: Any] = ["magnetLink": url.absoluteString]
      if !preferInitialStorage, let eventSink {
        eventSink(payload)
        return
      }

      initialTorrent = payload
      return
    }

    let hasScopedAccess = url.startAccessingSecurityScopedResource()
    defer {
      if hasScopedAccess {
        url.stopAccessingSecurityScopedResource()
      }
    }

    guard isTorrent(url: url), let data = try? Data(contentsOf: url), !data.isEmpty else {
      return
    }

    let payload: [String: Any] = [
      "fileName": url.lastPathComponent.isEmpty ? "shared.torrent" : url.lastPathComponent,
      "bytes": FlutterStandardTypedData(bytes: data),
    ]

    if !preferInitialStorage, let eventSink {
      eventSink(payload)
      return
    }

    initialTorrent = payload
  }

  private func isTorrent(url: URL) -> Bool {
    if url.pathExtension.caseInsensitiveCompare("torrent") == .orderedSame {
      return true
    }

    if #available(iOS 14.0, *) {
      let type = UTType(filenameExtension: url.pathExtension)
      return type?.preferredMIMEType == "application/x-bittorrent"
    }

    return false
  }
}

extension SceneDelegate: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
