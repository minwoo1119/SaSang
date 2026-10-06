package com.sasang.app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.media.MediaMuxer
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.math.max
import kotlin.math.min

class MainActivity : FlutterActivity() {
    private val timelineChannel = "com.sasang.app/timeline"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, timelineChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "encodeTimeline") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                Thread {
                    try {
                        encodeTimeline(call)
                        runOnUiThread { result.success(true) }
                    } catch (error: Throwable) {
                        runOnUiThread {
                            result.error("timeline_encode_failed", error.message, null)
                        }
                    }
                }.start()
            }
    }

    private fun encodeTimeline(call: MethodCall) {
        val paths = call.argument<List<String>>("framePaths")
            ?: error("Missing timeline frame paths")
        val repeats = call.argument<List<Int>>("repeats")
            ?: error("Missing timeline frame repeats")
        val outputPath = call.argument<String>("outputPath")
            ?: error("Missing timeline output path")
        val width = call.argument<Int>("width") ?: 720
        val height = call.argument<Int>("height") ?: 1280
        val fps = call.argument<Int>("fps") ?: 12
        val bitrate = call.argument<Int>("bitrate") ?: 5_000_000
        require(paths.isNotEmpty() && paths.size == repeats.size)

        val mime = MediaFormat.MIMETYPE_VIDEO_AVC
        val codecInfo = MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos
            .firstOrNull { info ->
                info.isEncoder && info.supportedTypes.any { it.equals(mime, ignoreCase = true) }
            } ?: error("No H.264 encoder is available")
        val capabilities = codecInfo.getCapabilitiesForType(mime)
        val colorFormat = listOf(
            MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible,
        ).firstOrNull { capabilities.colorFormats.contains(it) }
            ?: error("No supported YUV420 encoder format")

        val format = MediaFormat.createVideoFormat(mime, width, height).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, colorFormat)
            setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }
        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()
        if (outputFile.exists()) outputFile.delete()

        val codec = MediaCodec.createByCodecName(codecInfo.name)
        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        val info = MediaCodec.BufferInfo()
        var trackIndex = -1
        var muxerStarted = false
        var presentationTimeUs = 0L
        val frameDurationUs = 1_000_000L / fps

        fun drain(endOfStream: Boolean) {
            while (true) {
                val index = codec.dequeueOutputBuffer(info, if (endOfStream) 10_000 else 0)
                when {
                    index == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                        if (!endOfStream) return
                    }
                    index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        check(!muxerStarted)
                        trackIndex = muxer.addTrack(codec.outputFormat)
                        muxer.start()
                        muxerStarted = true
                    }
                    index >= 0 -> {
                        val buffer = codec.getOutputBuffer(index)
                            ?: error("Encoder returned an empty output buffer")
                        if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                            info.size = 0
                        }
                        if (info.size > 0) {
                            check(muxerStarted)
                            buffer.position(info.offset)
                            buffer.limit(info.offset + info.size)
                            muxer.writeSampleData(trackIndex, buffer, info)
                        }
                        val finished = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                        codec.releaseOutputBuffer(index, false)
                        if (finished) return
                    }
                }
            }
        }

        try {
            codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            codec.start()
            for (frameIndex in paths.indices) {
                val source = BitmapFactory.decodeFile(paths[frameIndex])
                    ?: error("Cannot decode timeline frame ${paths[frameIndex]}")
                val bitmap = if (source.width == width && source.height == height) {
                    source
                } else {
                    Bitmap.createScaledBitmap(source, width, height, true).also { source.recycle() }
                }
                val frame = bitmapToYuv420(bitmap, width, height, colorFormat)
                bitmap.recycle()
                repeat(max(1, repeats[frameIndex])) {
                    var queued = false
                    while (!queued) {
                        val inputIndex = codec.dequeueInputBuffer(10_000)
                        if (inputIndex >= 0) {
                            val input = codec.getInputBuffer(inputIndex)
                                ?: error("Encoder returned an empty input buffer")
                            input.clear()
                            input.put(frame)
                            codec.queueInputBuffer(
                                inputIndex,
                                0,
                                frame.size,
                                presentationTimeUs,
                                0,
                            )
                            presentationTimeUs += frameDurationUs
                            queued = true
                        }
                        drain(false)
                    }
                }
            }

            var eosQueued = false
            while (!eosQueued) {
                val inputIndex = codec.dequeueInputBuffer(10_000)
                if (inputIndex >= 0) {
                    codec.queueInputBuffer(
                        inputIndex,
                        0,
                        0,
                        presentationTimeUs,
                        MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                    )
                    eosQueued = true
                }
                drain(false)
            }
            drain(true)
        } finally {
            try {
                codec.stop()
            } catch (_: Throwable) {
            }
            codec.release()
            if (muxerStarted) {
                try {
                    muxer.stop()
                } catch (_: Throwable) {
                }
            }
            muxer.release()
        }
    }

    private fun bitmapToYuv420(
        bitmap: Bitmap,
        width: Int,
        height: Int,
        colorFormat: Int,
    ): ByteArray {
        val pixels = IntArray(width * height)
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
        val ySize = width * height
        val result = ByteArray(ySize + ySize / 2)
        val planar = colorFormat == MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar
        var yIndex = 0
        var uIndex = ySize
        var vIndex = if (planar) ySize + ySize / 4 else ySize + 1
        for (row in 0 until height) {
            for (column in 0 until width) {
                val color = pixels[row * width + column]
                val red = color shr 16 and 0xff
                val green = color shr 8 and 0xff
                val blue = color and 0xff
                val y = ((66 * red + 129 * green + 25 * blue + 128) shr 8) + 16
                val u = ((-38 * red - 74 * green + 112 * blue + 128) shr 8) + 128
                val v = ((112 * red - 94 * green - 18 * blue + 128) shr 8) + 128
                result[yIndex++] = min(255, max(0, y)).toByte()
                if (row % 2 == 0 && column % 2 == 0) {
                    result[uIndex] = min(255, max(0, u)).toByte()
                    result[vIndex] = min(255, max(0, v)).toByte()
                    if (planar) {
                        uIndex++
                        vIndex++
                    } else {
                        uIndex += 2
                        vIndex += 2
                    }
                }
            }
        }
        return result
    }
}
