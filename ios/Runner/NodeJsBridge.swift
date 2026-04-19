import Foundation
import Flutter
import NodeMobile

public class NodeJsBridge: NSObject {
    @objc public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "com.example.iosTvboxParser/nodejs", binaryMessenger: registrar.messenger())
        let instance = NodeJsBridge()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }

    private func startEngine(result: @escaping FlutterResult) {
        DispatchQueue.global().async {
            guard let nodePath = Bundle.main.path(forResource: "nodejs-project", ofType: nil) else {
                DispatchQueue.main.async { result(FlutterError(code: "NO_PROJECT", message: "nodejs-project not found", details: nil)) }
                return
            }

            let scriptPath = nodePath + "/server.js"
            
            var cStrings = [scriptPath].map { strdup($0) }
            cStrings.append(nil)
            
            cStrings.withUnsafeMutableBufferPointer { buffer in
                guard let baseAddress = buffer.baseAddress else { return }
                node_start(Int32(cStrings.count - 1), baseAddress)
            }
            
            for ptr in cStrings where ptr != nil { free(ptr) }
            
            DispatchQueue.main.async { result(true) }
        }
    }
}

extension NodeJsBridge: FlutterPlugin {
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "start" {
            startEngine(result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}
