package org.baytides.navigator

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register the On-Device AI plugin for Gemini Nano support
        flutterEngine.plugins.add(OnDeviceAIPlugin())
    }
}
