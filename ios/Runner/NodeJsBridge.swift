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

            // 准备参数：要执行的 JS 文件路径
            let scriptPath = nodePath + "/server.js"
            let args = [scriptPath]
            
            // 调用 C 函数 node_start
            let argv = args.map { strdup($0) }
            node_start(Int32(args.count), argv)
            for ptr in argv { free(ptr) }

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
