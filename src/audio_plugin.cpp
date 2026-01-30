#include "audio_plugin.h"
#include <pulse/simple.h>
#include <pulse/pulseaudio.h>
#include <pulse/error.h>
#include <fftw3.h>
#include <cmath>
#include <algorithm>
#include <thread>
#include <vector>
#include <numeric>

// --- PulseAudio Callback Helpers ---
void sink_info_cb(pa_context *c, const pa_sink_info *i, int eol, void *userdata) {
    if (c){};
    if (eol > 0 || !i) return;
    AudioPlugin *self = static_cast<AudioPlugin*>(userdata);
    
    // Convert PulseAudio volume to 0.0 - 1.0 range
    double vol = (double)pa_cvolume_avg(&(i->volume)) / PA_VOLUME_NORM;
    self->updateVolumeProperty(vol);
}

void subscribe_cb(pa_context *c, pa_subscription_event_type_t t, uint32_t idx, void *userdata) {
    if ((t & PA_SUBSCRIPTION_EVENT_FACILITY_MASK) == PA_SUBSCRIPTION_EVENT_SINK) {
        pa_context_get_sink_info_by_index(c, idx, sink_info_cb, userdata);
    }
}

void context_state_cb(pa_context *c, void *userdata) {
    if (pa_context_get_state(c) == PA_CONTEXT_READY) {
        pa_context_get_sink_info_by_name(c, "@DEFAULT_SINK@", sink_info_cb, userdata);
        pa_context_set_subscribe_callback(c, subscribe_cb, userdata);
        pa_context_subscribe(c, PA_SUBSCRIPTION_MASK_SINK, nullptr, nullptr);
    }
}

AudioPlugin::AudioPlugin(QObject *parent) : QObject(parent), m_running(false), m_volume(0.0) {
    for(int i = 0; i < 8; ++i) {
        m_levels.append(0.0);
        m_binMax.push_back(0.1);
        m_smoothedLevels.push_back(0.0);
    }
    startAudioThread();
}

AudioPlugin::~AudioPlugin() {
    m_running = false;
}

void AudioPlugin::updateVolumeProperty(double val) {
    m_volume = std::clamp(val, 0.0, 1.0);
    QMetaObject::invokeMethod(this, &AudioPlugin::volumeChanged, Qt::QueuedConnection);
}

void AudioPlugin::startAudioThread() {
    if (m_running) return;
    m_running = true;

    std::thread([this]() {
        // === 1. Setup Async Context for Volume Tracking ===
        pa_mainloop *ml = pa_mainloop_new();
        pa_context *ctx = pa_context_new(pa_mainloop_get_api(ml), "PlasmaVizControl");
        pa_context_set_state_callback(ctx, context_state_cb, this);
        pa_context_connect(ctx, nullptr, PA_CONTEXT_NOFLAGS, nullptr);

        // === 2. Setup Simple API for Audio Capture ===
        pa_sample_spec ss;
        ss.format = PA_SAMPLE_S16LE;
        ss.channels = 1;
        ss.rate = 44100;

        pa_buffer_attr attr;
        attr.maxlength = (uint32_t)-1;
        attr.tlength = 512;
        attr.fragsize = 512;

        pa_simple *s = pa_simple_new(nullptr, "PlasmaViz", PA_STREAM_RECORD, 
                                     "@DEFAULT_SINK@.monitor", "Viz", 
                                     &ss, nullptr, &attr, nullptr);
        if (!s) {
            m_running = false;
            return;
        }

        // === 3. FFT Setup ===
        constexpr int n = 1024;
        int16_t buf[n];
        double *in = (double*)fftw_malloc(sizeof(double) * n);
        fftw_complex *out = (fftw_complex*)fftw_malloc(sizeof(fftw_complex) * (n/2 + 1));
        fftw_plan plan = fftw_plan_dft_r2c_1d(n, in, out, FFTW_ESTIMATE);

        double vibrationTime = 0.0;

        while (m_running) {
            // Pump the mainloop to process volume change events
            pa_mainloop_iterate(ml, 0, nullptr);

            // Read audio data
            if (pa_simple_read(s, buf, sizeof(buf), nullptr) < 0) break;

            // Fill FFT input (RMS calculation removed from m_volume since it now follows system slider)
            for (int i = 0; i < n; ++i) {
                in[i] = buf[i] / 32768.0;
            }

            // --- FFT Execution & Binning ---
            fftw_execute(plan);
            QVariantList newLevels;
            int n_half = n / 2;
            vibrationTime += 0.3;
            int binIndices[] = {2, 5, 12, 24, 58, 138, 300, 511};

            for (int b = 0; b < 8; ++b) {
                int start = (b == 0) ? 0 : binIndices[b-1];
                int end   = binIndices[b];
                double avg = 0.0;
                int count = 0;
                for (int i = start; i <= end && i < n_half; ++i) {
                    avg += std::sqrt(out[i][0]*out[i][0] + out[i][1]*out[i][1]);
                    ++count;
                }
                avg = (count > 0) ? (avg / count) : 0.0;

                if (avg > m_binMax[b]) m_binMax[b] = avg;
                else m_binMax[b] *= 0.985;
                
                double normalized = (m_binMax[b] > 0.001) ? (avg / m_binMax[b]) : 0.0;
                double baseWeights[] = {0.7, 0.85, 1.0, 1.1, 1.1, 1.0, 0.9, 0.8};
                normalized *= baseWeights[b] + (0.1 * std::sin(vibrationTime * 0.5));
                
                double jitter = std::sin(vibrationTime * (1.0 + b * 0.15) + b) * (0.02 + (b % 3) * 0.01);
                normalized = std::clamp(normalized + jitter, 0.0, 1.0);

                double lerpFactor = (normalized > m_smoothedLevels[b]) ? 0.7 : 0.3;
                m_smoothedLevels[b] += (normalized - m_smoothedLevels[b]) * lerpFactor;
                newLevels.append(std::clamp(std::pow(m_smoothedLevels[b], 1.2), 0.0, 1.0));
            }

            m_levels = newLevels;
            QMetaObject::invokeMethod(this, &AudioPlugin::levelsChanged, Qt::QueuedConnection);
        }

        // === Cleanup ===
        fftw_destroy_plan(plan);
        fftw_free(in);
        fftw_free(out);
        pa_simple_free(s);
        pa_context_disconnect(ctx);
        pa_context_unref(ctx);
        pa_mainloop_free(ml);
    }).detach();
}