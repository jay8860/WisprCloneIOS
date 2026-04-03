package com.example.geminiime

import android.inputmethodservice.InputMethodService
import android.media.MediaRecorder
import android.os.Build
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.io.File

/**
 * Minimal Android IME skeleton:
 * - Hold mic button to record
 * - Release to transcribe with Gemini
 * - Commit text into current input field
 *
 * Wire this into a full Android Studio IME project and replace transcribeWithGemini().
 */
class GeminiImeService : InputMethodService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var recorder: MediaRecorder? = null
    private var recordingFile: File? = null

    override fun onCreateInputView(): View {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }

        val micButton = Button(this).apply {
            text = "Hold to Dictate"
            setOnTouchListener { _, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        startRecording()
                        true
                    }
                    MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                        stopAndTranscribe()
                        true
                    }
                    else -> false
                }
            }
        }

        layout.addView(micButton)
        return layout
    }

    private fun startRecording() {
        val output = File(cacheDir, "ime-dictation-${System.currentTimeMillis()}.m4a")
        recordingFile = output

        val mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

        mediaRecorder.apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setAudioChannels(1)
            setAudioSamplingRate(16000)
            setOutputFile(output.absolutePath)
            prepare()
            start()
        }

        recorder = mediaRecorder
    }

    private fun stopAndTranscribe() {
        val mediaRecorder = recorder ?: return
        recorder = null

        try {
            mediaRecorder.stop()
        } catch (_: Exception) {
            mediaRecorder.reset()
            mediaRecorder.release()
            return
        }
        mediaRecorder.reset()
        mediaRecorder.release()

        val file = recordingFile ?: return
        scope.launch {
            val text = transcribeWithGemini(file)
            if (text.isNotBlank()) {
                currentInputConnection?.commitText(text, 1)
            }
            file.delete()
        }
    }

    private fun transcribeWithGemini(audioFile: File): String {
        // TODO: Implement HTTP call to Gemini using your API key.
        // Endpoint pattern:
        // https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=<API_KEY>
        // Send inlineData with base64 audio and prompt for clean dictation text.
        return ""
    }
}
