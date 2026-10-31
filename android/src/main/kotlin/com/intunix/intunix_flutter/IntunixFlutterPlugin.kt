package com.intunix.intunix_flutter

import android.app.Activity
import android.content.Context
import android.view.View
import com.intunix.sdk.Intunix
import com.intunix.sdk.IntunixFormView
import com.intunix.sdk.IntunixOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** Bridges the `intunix` channel to the native Intunix Android SDK. */
class IntunixFlutterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "intunix").also { it.setMethodCallHandler(this) }
        binding.platformViewRegistry.registerViewFactory("intunix/form", FormFactory(binding.binaryMessenger))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) = channel.setMethodCallHandler(null)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val o = call.argument<Map<String, Any?>>("options").orEmpty()
                val options = IntunixOptions(
                    apiHost = o["apiHost"] as? String ?: "https://api.intunix.com",
                    register = (o["register"] as? List<*>)?.filterIsInstance<String>() ?: emptyList(),
                    registerAll = o["registerAll"] as? Boolean ?: false,
                    flushIntervalMs = (o["flushIntervalMs"] as? Number)?.toLong() ?: 5_000,
                    maxQueueSize = (o["maxQueueSize"] as? Number)?.toInt() ?: 100,
                    screenTriggerDelayMs = (o["screenTriggerDelayMs"] as? Number)?.toLong() ?: 600,
                    disableEventApi = o["disableEventApi"] as? Boolean ?: false,
                    debug = o["debug"] as? Boolean ?: false,
                )
                Intunix.init(activity ?: appContext, call.argument<String>("apiKey").orEmpty(), options)
            }
            "identify" -> Intunix.identify(call.argument<String>("userId").orEmpty(), call.map("traits").orEmpty())
            "reset" -> Intunix.reset()
            "track" -> Intunix.track(call.argument<String>("event").orEmpty(), call.map("properties").orEmpty())
            "screen" -> Intunix.screen(call.argument<String>("name").orEmpty())
            "setContext" -> Intunix.setContext(call.map("context"))
            "showForm" -> Intunix.showForm(call.argument<String>("form").orEmpty(), call.map("context"))
            "register" -> Intunix.register(call.argument<String>("form").orEmpty())
            "unregister" -> Intunix.unregister(call.argument<String>("form").orEmpty())
            else -> return result.notImplemented()
        }
        result.success(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        Intunix.attach(binding.activity)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)
    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onDetachedFromActivity() { activity = null }
}

@Suppress("UNCHECKED_CAST")
private fun MethodCall.map(key: String): Map<String, Any?>? =
    (argument<Map<Any?, Any?>>(key))?.entries?.associate { (k, v) -> k.toString() to v }

private class FormFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView = FormPlatformView(context, viewId, args as? Map<*, *>, messenger)
}

/** The inline form; reports its height (logical pixels) and completion to Dart. */
private class FormPlatformView(context: Context, id: Int, args: Map<*, *>?, messenger: BinaryMessenger) : PlatformView {
    private val events = MethodChannel(messenger, "intunix/form_$id")
    private val density = context.resources.displayMetrics.density
    private val view = IntunixFormView(context).apply {
        onHeightChanged = { px -> events.invokeMethod("height", (px / density).toDouble().coerceAtLeast(1.0)) }
        onFinished = { events.invokeMethod("finished", null) }
        @Suppress("UNCHECKED_CAST")
        setForm(args?.get("form") as? String, (args?.get("context") as? Map<Any?, Any?>)?.entries?.associate { (k, v) -> k.toString() to v })
    }

    override fun getView(): View = view
    override fun dispose() {}
}
