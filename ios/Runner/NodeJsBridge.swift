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

            // 1. 准备参数：要执行的 JS 文件路径
            let scriptPath = nodePath + "/server.js"
            let args = [scriptPath]
            
            // 2. 调用 C 函数 node_start
            //    根据官方示例，node_start 需要参数数量和参数数组
            let argv = args.map { strdup($0) }
            node_start(Int32(args.count), argv)
            for ptr in argv { free(ptr) }

            // 3. 启动成功（node_start 是阻塞调用，会一直运行，直到服务结束）
            //    因此，此处的 result 回调实际上不会被执行，除非 node_start 立即返回。
            //    但为了符合 Flutter 的异步调用模式，我们还是保留它。
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
