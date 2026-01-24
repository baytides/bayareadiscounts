package org.baytides.navigator

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*

/**
 * Flutter plugin for on-device AI using Gemini Nano via ML Kit GenAI APIs.
 *
 * Requirements:
 * - Android 14 (API 34) or higher
 * - Device with Gemini Nano support (Pixel 8+, Samsung Galaxy S24+, etc.)
 * - ML Kit GenAI dependency in build.gradle
 *
 * Add to app/build.gradle.kts:
 * ```
 * dependencies {
 *     implementation("com.google.android.gms:play-services-mlkit-genai:1.0.0")
 * }
 * ```
 */
class OnDeviceAIPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // Gemini Nano session (lazy initialized)
    private var inferenceSession: Any? = null
    private var isSessionInitialized = false

    companion object {
        private const val TAG = "OnDeviceAI"
        private const val CHANNEL_NAME = "org.baytides.navigator/ai"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
        releaseSession()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isGeminiNanoAvailable" -> checkAvailability(result)
            "getAICapabilities" -> getCapabilities(result)
            "processMessage" -> processMessage(call, result)
            "summarize" -> summarize(call, result)
            "detectIntent" -> detectIntent(call, result)
            else -> result.notImplemented()
        }
    }

    /**
     * Check if Gemini Nano is available on this device.
     * Requires:
     * - Android 14+
     * - Supported hardware (Pixel 8+, etc.)
     * - ML Kit GenAI installed
     */
    private fun checkAvailability(result: Result) {
        scope.launch {
            try {
                val isAvailable = withContext(Dispatchers.IO) {
                    checkGeminiNanoSupport()
                }
                result.success(isAvailable)
            } catch (e: Exception) {
                Log.e(TAG, "Error checking availability", e)
                result.success(false)
            }
        }
    }

    private suspend fun checkGeminiNanoSupport(): Boolean {
        // Check Android version (requires API 34+)
        if (android.os.Build.VERSION.SDK_INT < 34) {
            Log.d(TAG, "Android version too low for Gemini Nano")
            return false
        }

        // Try to load ML Kit GenAI class
        return try {
            // This will throw if ML Kit GenAI is not available
            Class.forName("com.google.android.gms.mlkit.genai.GenerativeModel")

            // Additional runtime check for model availability
            // Note: This is a simplified check. Real implementation would use:
            // GenerativeModel.isModelAvailable(context)
            true
        } catch (e: ClassNotFoundException) {
            Log.d(TAG, "ML Kit GenAI not found", e)
            false
        } catch (e: Exception) {
            Log.e(TAG, "Error checking Gemini Nano support", e)
            false
        }
    }

    /**
     * Get AI capabilities information
     */
    private fun getCapabilities(result: Result) {
        scope.launch {
            try {
                val capabilities = withContext(Dispatchers.IO) {
                    buildCapabilitiesMap()
                }
                result.success(capabilities)
            } catch (e: Exception) {
                Log.e(TAG, "Error getting capabilities", e)
                result.success(mapOf(
                    "isAvailable" to false,
                    "modelName" to null,
                    "supportsSummarization" to false,
                    "supportsPromptAPI" to false,
                    "supportsProofreading" to false
                ))
            }
        }
    }

    private suspend fun buildCapabilitiesMap(): Map<String, Any?> {
        val isAvailable = checkGeminiNanoSupport()

        return mapOf(
            "isAvailable" to isAvailable,
            "modelName" to if (isAvailable) "Gemini Nano" else null,
            "supportsSummarization" to isAvailable,
            "supportsPromptAPI" to isAvailable,
            "supportsProofreading" to isAvailable,
            "maxInputTokens" to if (isAvailable) 4096 else null,
            "maxOutputTokens" to if (isAvailable) 1024 else null
        )
    }

    /**
     * Process a message using Gemini Nano
     */
    private fun processMessage(call: MethodCall, result: Result) {
        val message = call.argument<String>("message") ?: run {
            result.error("INVALID_ARGUMENT", "Message is required", null)
            return
        }
        val systemPrompt = call.argument<String>("systemPrompt") ?: ""
        val conversationHistory = call.argument<List<Map<String, String>>>("conversationHistory")

        scope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    generateResponse(message, systemPrompt, conversationHistory)
                }
                result.success(response)
            } catch (e: Exception) {
                Log.e(TAG, "Error processing message", e)
                result.error("PROCESSING_ERROR", e.message, null)
            }
        }
    }

    private suspend fun generateResponse(
        message: String,
        systemPrompt: String,
        conversationHistory: List<Map<String, String>>?
    ): String? {
        if (!checkGeminiNanoSupport()) return null

        // Build prompt with conversation context
        val promptBuilder = StringBuilder()

        if (systemPrompt.isNotEmpty()) {
            promptBuilder.append(systemPrompt).append("\n\n")
        }

        // Add conversation history
        conversationHistory?.takeLast(6)?.forEach { entry ->
            val role = entry["role"] ?: return@forEach
            val content = entry["content"] ?: return@forEach
            when (role) {
                "user" -> promptBuilder.append("User: $content\n")
                "assistant" -> promptBuilder.append("Carl: $content\n")
            }
        }

        promptBuilder.append("User: $message\nCarl:")

        // In a real implementation, this would use:
        // val model = GenerativeModel.getModel(context, "gemini-nano")
        // return model.generateContent(promptBuilder.toString()).text

        // Placeholder for when ML Kit GenAI is available
        Log.d(TAG, "Would generate response for: ${promptBuilder.toString().take(100)}...")
        return null // Return null to fall back to cloud API
    }

    /**
     * Summarize text using Gemini Nano
     */
    private fun summarize(call: MethodCall, result: Result) {
        val text = call.argument<String>("text") ?: run {
            result.error("INVALID_ARGUMENT", "Text is required", null)
            return
        }
        val maxLength = call.argument<Int>("maxLength") ?: 150

        scope.launch {
            try {
                val summary = withContext(Dispatchers.IO) {
                    generateSummary(text, maxLength)
                }
                result.success(summary)
            } catch (e: Exception) {
                Log.e(TAG, "Error summarizing", e)
                result.error("SUMMARIZATION_ERROR", e.message, null)
            }
        }
    }

    private suspend fun generateSummary(text: String, maxLength: Int): String? {
        if (!checkGeminiNanoSupport()) return null

        // In a real implementation, this would use ML Kit Summarization API:
        // val summarizer = Summarizer.getClient(context)
        // return summarizer.summarize(text, SummarizationOptions.Builder()
        //     .setMaxLength(maxLength)
        //     .build())

        Log.d(TAG, "Would summarize text of length ${text.length} to max $maxLength chars")
        return null
    }

    /**
     * Detect user intent using local pattern matching
     * (On-device AI can enhance this with better NLU)
     */
    private fun detectIntent(call: MethodCall, result: Result) {
        val message = call.argument<String>("message") ?: run {
            result.error("INVALID_ARGUMENT", "Message is required", null)
            return
        }

        val intent = detectIntentLocally(message)
        result.success(mapOf(
            "type" to intent.type,
            "parameters" to intent.parameters,
            "confidence" to intent.confidence
        ))
    }

    private fun detectIntentLocally(message: String): DetectedIntent {
        val lowercased = message.lowercase()

        // Reminder detection
        if (lowercased.contains("remind") || lowercased.contains("reminder")) {
            return DetectedIntent(
                type = "setReminder",
                parameters = mapOf("title" to extractReminderTitle(message)),
                confidence = 0.7
            )
        }

        // Timer detection
        if (lowercased.contains("timer") || lowercased.contains("set a timer")) {
            extractTimerDuration(message)?.let { duration ->
                return DetectedIntent(
                    type = "setTimer",
                    parameters = mapOf("duration" to duration.toString()),
                    confidence = 0.8
                )
            }
        }

        // Phone call detection
        if (lowercased.contains("call ")) {
            extractPhoneNumber(message)?.let { number ->
                return DetectedIntent(
                    type = "makePhoneCall",
                    parameters = mapOf("number" to number),
                    confidence = 0.9
                )
            }
        }

        // Directions detection
        if (lowercased.contains("directions to") ||
            lowercased.contains("how to get to") ||
            lowercased.contains("navigate to")) {
            return DetectedIntent(
                type = "openMaps",
                parameters = mapOf("query" to extractLocationQuery(message)),
                confidence = 0.75
            )
        }

        return DetectedIntent(type = "none", parameters = emptyMap(), confidence = 1.0)
    }

    private fun extractReminderTitle(message: String): String {
        val patterns = listOf(
            "remind me to ",
            "reminder to ",
            "remind me about ",
            "set a reminder for "
        )

        var cleaned = message.lowercase()
        for (pattern in patterns) {
            if (cleaned.contains(pattern)) {
                cleaned = cleaned.substringAfter(pattern)
                val timePhrases = listOf(" at ", " on ", " tomorrow", " today")
                for (phrase in timePhrases) {
                    val idx = cleaned.indexOf(phrase)
                    if (idx != -1) {
                        cleaned = cleaned.substring(0, idx)
                        break
                    }
                }
                return cleaned.trim()
            }
        }

        return "Bay Navigator reminder"
    }

    private fun extractTimerDuration(message: String): Int? {
        val patterns = listOf(
            Regex("""(\d+)\s*second""") to 1,
            Regex("""(\d+)\s*minute""") to 60,
            Regex("""(\d+)\s*hour""") to 3600
        )

        val lowercased = message.lowercase()
        for ((pattern, multiplier) in patterns) {
            pattern.find(lowercased)?.let { match ->
                match.groupValues.getOrNull(1)?.toIntOrNull()?.let { value ->
                    return value * multiplier
                }
            }
        }

        return null
    }

    private fun extractPhoneNumber(message: String): String? {
        // Phone number pattern
        val pattern = Regex("""\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}""")
        pattern.find(message)?.let { return it.value }

        // Crisis numbers
        val crisisNumbers = mapOf(
            "911" to listOf("911", "emergency"),
            "988" to listOf("988", "suicide", "crisis"),
            "211" to listOf("211", "community")
        )

        val lowercased = message.lowercase()
        for ((number, keywords) in crisisNumbers) {
            if (keywords.any { lowercased.contains(it) }) {
                return number
            }
        }

        return null
    }

    private fun extractLocationQuery(message: String): String {
        val patterns = listOf(
            "directions to ",
            "how to get to ",
            "navigate to ",
            "find on map "
        )

        val lowercased = message.lowercase()
        for (pattern in patterns) {
            if (lowercased.contains(pattern)) {
                return lowercased.substringAfter(pattern).trim()
            }
        }

        return message
    }

    private fun releaseSession() {
        inferenceSession = null
        isSessionInitialized = false
    }

    private data class DetectedIntent(
        val type: String,
        val parameters: Map<String, String>,
        val confidence: Double
    )
}
