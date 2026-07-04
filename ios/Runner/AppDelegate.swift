import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Obtener el controlador de Flutter
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "daily_hope/api_keys",
                binaryMessenger: controller.binaryMessenger
            )
            
            channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: FlutterResult) in
                if call.method == "getGroqKeys" {
                    result(self?.getAllKeys() ?? [])
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
    
    /**
     Retorna las API keys de Groq ofuscadas.
     */
    private func getAllKeys() -> [String] {
        let xorKey: UInt8 = 42
        
        // 🔑 KEY 1 - Reemplaza estos números con los de tu script Python
        let key1 = decrypt([77, 89, 65, 117, 65, 18, 93, 31, 90, 29, 88, 111, 94, 29, 24, 93, 110, 108, 105, 122, 114, 100, 98, 126, 125, 109, 78, 83, 72, 25, 108, 115, 104, 112, 105, 29, 97, 27, 122, 102, 122, 121, 112, 73, 100, 69, 107, 112, 29, 66, 70, 120, 122, 67, 29, 69], xorKey: xorKey)
        
        // 🔑 KEY 2 - Reemplaza estos números con los de tu script Python
        let key2 = decrypt([77, 89, 65, 117, 66, 69, 101, 97, 101, 124, 64, 103, 73, 127, 115, 64, 18, 24, 115, 125, 18, 110, 93, 69, 125, 109, 78, 83, 72, 25, 108, 115, 92, 29, 127, 103, 95, 100, 107, 80, 125, 126, 73, 121, 70, 77, 25, 126, 27, 27, 107, 79, 110, 123, 28, 77], xorKey: xorKey)
        
        return [key1, key2]
    }
    
    /**
     Desencripta un array de enteros usando XOR
     */
    private func decrypt(_ encoded: [Int], xorKey: UInt8) -> String {
        let chars = encoded.map { Character(UnicodeScalar(UInt8($0) ^ xorKey)!) }
        return String(chars)
    }
}