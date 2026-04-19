import Foundation
import Flutter
import NodeMobile

public class NodeJsBridge: NSObject {
    private static var eventSink: FlutterEventSink?
    
    @objc public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "com.example.iosTvboxParser/nodejs", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "com.example.iosTvboxParser/nodejs_events", binaryMessenger: registrar.messenger())
        
        let instance = NodeJsBridge()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    private func startEngine(result: @escaping FlutterResult) {
        // 使用最高优先级的后台队列
        DispatchQueue.global(qos: .userInitiated).async {
            guard let nodePath = Bundle.main.path(forResource: "nodejs-project", ofType: nil) else {
                DispatchQueue.main.async { result(FlutterError(code: "NO_PROJECT", message: "nodejs-project not found", details: nil)) }
                return
            }

            let scriptPath = nodePath + "/server.js"
            
            // 设置通道监听器，用于接收 Node.js 发送的消息
            NodeMobile.setChannelListener { (channel, message) in
                DispatchQueue.main.async {
                    NodeJsBridge.eventSink?(["channel": channel ?? "", "message": message ?? ""])
                }
            }
            
            // 构造参数
            let argv: [UnsafeMutablePointer<CChar>?] = [
                strdup(scriptPath),
                nil
            ]
            
            // 调用 node_start (此调用会阻塞当前线程，直到 Node.js 退出)
            node_start(Int32(argv.count - 1), UnsafeMutablePointer(mutating: argv))
            
            // 释放内存
            for ptr in argv {
                if let ptr = ptr {
                    free(ptr)
                }
            }
            
            // 理论上不会执行到这里，除非 Node.js 主动退出
            DispatchQueue.main.async { result(true) }
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
        if call.method == "start" {
            startEngine(result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}
