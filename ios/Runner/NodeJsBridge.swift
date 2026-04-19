import Foundation
import Flutter
import NodeMobile

public class NodeJsBridge: NSObject {
    private static var eventSink: FlutterEventSink?
    
    @objc public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "com.example.my_tvbox/nodejs", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "com.example.my_tvbox/nodejs_events", binaryMessenger: registrar.messenger())
        
        let instance = NodeJsBridge()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    private func startEngine(result: @escaping FlutterResult) {
        DispatchQueue.global().async {
            guard let nodePath = Bundle.main.path(forResource: "nodejs-project", ofType: nil) else {
                DispatchQueue.main.async { result(FlutterError(code: "NO_PROJECT", message: "nodejs-project not found", details: nil)) }
                return
            }

            NodeMobile.startEngine(nodePath, arguments: [nodePath + "/main.js"])

            NodeMobile.setSendHandler { (channel, message) in
                DispatchQueue.main.async {
                    NodeJsBridge.eventSink?(["channel": channel ?? "", "message": message ?? ""])
                }
            }
            
            DispatchQueue.main.async { result(true) }
        }
    }

    private func sendMessage(channel: String, message: String) {
        DispatchQueue.global().async {
            NodeMobile.sendMessage(channel, message: message)
        }
    }
}

extension NodeJsBridge: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        NodeJsBridge.eventSink = events
        return nil
    }
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NodeJsBridge.eventSink = nil
        return nil
    }
}
extension NodeJsBridge: FlutterPlugin {
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start": startEngine(result: result)
        case "sendMessage":
            guard let args = call.arguments as? [String: Any],
                  let channel = args["channel"] as? String,
                  let message = args["message"] as? String else {
                result(FlutterError(code: "INVALID_ARG", message: "Invalid arguments", details: nil))
                return
            }
            sendMessage(channel: channel, message: message)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
