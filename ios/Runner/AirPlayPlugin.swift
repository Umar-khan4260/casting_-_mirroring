import Flutter
import UIKit
import AVKit
import AVFoundation

/// Handles Flutter ↔ native communication for AirPlay screen mirroring.
///
/// IMPORTANT: On iOS, third-party apps CANNOT programmatically initiate
/// full-device AirPlay mirroring. The user must manually go to
/// Control Center → Screen Mirroring to mirror the entire iPhone screen.
///
/// This plugin provides:
/// - AirPlay route detection and monitoring
/// - System AirPlay route picker presentation (AVRoutePickerView)
/// - Detection of active AirPlay/screen mirroring sessions
/// - Media routing via AVPlayer.externalPlayback
class AirPlayPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var channel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    private var routePickerView: AVRoutePickerView?
    private var routeObserver: NSObject?

    static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.casting_mirroring/airplay",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.casting_mirroring/airplay_events",
            binaryMessenger: registrar.messenger()
        )

        let instance = AirPlayPlugin()
        instance.channel = methodChannel
        instance.eventChannel = eventChannel
        eventChannel.setStreamHandler(instance)

        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getAirPlayAvailability":
            result(getAirPlayAvailability())

        case "getMirroringStatus":
            result(getMirroringStatus())

        case "showRoutePicker":
            showRoutePicker(result: result)

        case "startMonitoring":
            startMonitoring()
            result(nil)

        case "stopMonitoring":
            stopMonitoring()
            result(nil)

        case "openControlCenterMirror":
            // Cannot programmatically open Control Center's Screen Mirroring.
            // We can only guide the user.
            result([
                "success": false,
                "message": "Full-device screen mirroring must be started manually via Control Center → Screen Mirroring. This is an iOS platform restriction."
            ])

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - AirPlay Availability

    private func getAirPlayAvailability() -> [String: Any] {
        let routePickerView = AVRoutePickerView()
        let hasAirPlayRoutes = !routePickerView.airplayActive
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        let isAirPlayActive = currentRoute.outputs.contains { output in
            output.portType == .airPlay
                || output.portType == .airPlayAirPortExpress
                || output.portType == .airPlayBolt
        }

        return [
            "isAvailable": true, // AirPlay is always available on iOS
            "isAirPlayActive": isAirPlayActive,
            "currentRouteName": currentRoute.inputs.first?.portName ?? "iPhone",
            "routeDescription": currentRoute.description,
        ]
    }

    // MARK: - Mirroring Status

    private func getMirroringStatus() -> [String: Any] {
        let screen = UIScreen.main
        let isMirroring = screen.isMirrored
        let mirroredScreen = screen.mirroredScreen

        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        let isAirPlayConnected = currentRoute.outputs.contains { output in
            output.portType == .airPlay
        }

        return [
            "isSystemMirroringActive": isMirroring,
            "mirroredScreenName": mirroredScreen?.name ?? "",
            "isAirPlayConnected": isAirPlayConnected,
            "connectedDeviceName": getConnectedAirPlayDeviceName(),
        ]
    }

    private func getConnectedAirPlayDeviceName() -> String? {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs {
            if output.portType == .airPlay {
                return output.portName
            }
        }
        return nil
    }

    // MARK: - Route Picker

    private func showRoutePicker(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            // Create AVRoutePickerView - this is the system AirPlay picker
            let picker = AVRoutePickerView()
            picker.delegate = self
            picker.prioritizesVideoDevices = true

            // Store reference to prevent deallocation
            self?.routePickerView = picker

            // Add to a temporary view to present the picker
            let containerVC = UIViewController()
            containerVC.view.addSubview(picker)
            picker.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                picker.centerXAnchor.constraint(equalTo: containerVC.view.centerXAnchor),
                picker.centerYAnchor.constraint(equalTo: containerVC.view.centerYAnchor),
                picker.widthAnchor.constraint(equalToConstant: 44),
                picker.heightAnchor.constraint(equalToConstant: 44),
            ])

            // Find the root view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                result([
                    "success": false,
                    "message": "Could not present route picker"
                ])
                return
            }

            // Present the picker view controller
            containerVC.modalPresentationStyle = .popover
            if let popover = containerVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }

            rootVC.present(containerVC, animated: true) {
                // Programmatically trigger the picker button tap
                for subview in picker.subviews {
                    if let button = subview as? UIButton {
                        button.sendActions(for: .touchUpInside)
                        break
                    }
                }

                result([
                    "success": true,
                    "message": "AirPlay route picker shown. Select a device to route media."
                ])
            }

            // Auto-dismiss after 10 seconds if user doesn't interact
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if containerVC.isBeingPresented {
                    containerVC.dismiss(animated: true)
                }
            }
        }
    }

    // MARK: - Route Monitoring

    private func startMonitoring() {
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification: notification)
        }

        // Also monitor screen mirroring
        NotificationCenter.default.addObserver(
            forName: UIScreen.didConnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleScreenConnect(notification: notification)
        }

        NotificationCenter.default.addObserver(
            forName: UIScreen.didDisconnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleScreenDisconnect(notification: notification)
        }

        // Send initial state
        sendInitialState()
    }

    private func stopMonitoring() {
        if let observer = routeObserver {
            NotificationCenter.default.removeObserver(observer)
            routeObserver = nil
        }
        NotificationCenter.default.removeObserver(self)
    }

    private func handleRouteChange(notification: Notification) {
        let status = getMirroringStatus()
        eventSink?(["type": "routeChange", "data": status])
    }

    private func handleScreenConnect(notification: Notification) {
        eventSink?([
            "type": "systemMirroringStarted",
            "data": getMirroringStatus(),
        ])
    }

    private func handleScreenDisconnect(notification: Notification) {
        eventSink?([
            "type": "systemMirroringStopped",
            "data": getMirroringStatus(),
        ])
    }

    private func sendInitialState() {
        let status = getMirroringStatus()
        eventSink?(["type": "initialState", "data": status])
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        sendInitialState()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// MARK: - AVRoutePickerViewDelegate

extension AirPlayPlugin: AVRoutePickerViewDelegate {
    func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        eventSink?(["type": "routePickerOpened", "data": [:]])
    }

    func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        // Update state after user selects a route
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let status = self?.getMirroringStatus() ?? [:]
            self?.eventSink?(["type": "routePickerClosed", "data": status])
        }
    }
}
