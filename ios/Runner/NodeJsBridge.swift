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
        DispatchQueue.global(qos: .userInitiated).async {
            guard let nodePath = Bundle.main.path(forResource: "nodejs-project", ofType: nil) else {
                DispatchQueue.main.async { result(FlutterError(code: "NO_PROJECT", message: "nodejs-project not found", details: nil)) }
                return
            }

            let scriptPath = nodePath + "/server.js"
            
            // 构造 char *argv[]
            let argv: [UnsafeMutablePointer<CChar>?] = [
                strdup(scriptPath),
                nil
            ]
            
            // 调用 node_start(int argc, char *argv[])
            node_start(Int32(argv.count - 1), UnsafeMutablePointer(mutating: argv))
            
            // 释放内存
            for ptr in argv {
                if let ptr = ptr {
                    free(ptr)
                }
            }
            
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
