package com.example.daily_hope

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    
    private val CHANNEL = "daily_hope/api_keys"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getGroqKeys" -> {
                    result.success(getAllKeys())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    /**
     * Retorna las API keys de Groq ofuscadas.
     * Las keys están divididas y encriptadas con XOR.
     */
    private fun getAllKeys(): List<String> {
        val xorKey = 42
        
        // 🔑 KEY 1 - Reemplaza estos números con los de tu script Python
        val key1 = decrypt(intArrayOf(77, 89, 65, 117, 65, 18, 93, 31, 90, 29, 88, 111, 94, 29, 24, 93, 110, 108, 105, 122, 114, 100, 98, 126, 125, 109, 78, 83, 72, 25, 108, 115, 104, 112, 105, 29, 97, 27, 122, 102, 122, 121, 112, 73, 100, 69, 107, 112, 29, 66, 70, 120, 122, 67, 29, 69), xorKey)
        
        // 🔑 KEY 2 - Reemplaza estos números con los de tu script Python
        val key2 = decrypt(intArrayOf(77, 89, 65, 117, 66, 69, 101, 97, 101, 124, 64, 103, 73, 127, 115, 64, 18, 24, 115, 125, 18, 110, 93, 69, 125, 109, 78, 83, 72, 25, 108, 115, 92, 29, 127, 103, 95, 100, 107, 80, 125, 126, 73, 121, 70, 77, 25, 126, 27, 27, 107, 79, 110, 123, 28, 77), xorKey)
        
        return listOf(key1, key2)
    }
    
    /**
     * Desencripta un array de enteros usando XOR
     */
    private fun decrypt(encoded: IntArray, key: Int): String {
        return encoded.map { (it xor key).toChar() }.joinToString("")
    }
}