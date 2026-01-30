#ifndef AUDIO_PLUGIN_H
#define AUDIO_PLUGIN_H

#include <QObject>
#include <QVariantList>
#include <qqml.h>
#include <atomic>
#include <vector>

class AudioPlugin : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList levels READ levels NOTIFY levelsChanged)
    Q_PROPERTY(double m_volume READ volume NOTIFY volumeChanged)
    QML_ELEMENT

public:
    explicit AudioPlugin(QObject *parent = nullptr);
    ~AudioPlugin();

    QVariantList levels() const { return m_levels; }
    double volume() const { return m_volume; }
    void updateVolumeProperty(double val);

signals:
    void levelsChanged();
    void volumeChanged();

private:
    void startAudioThread();
    
    std::atomic<bool> m_running{false};
    QVariantList m_levels; 
    
    double m_volume = 0.0;
    std::vector<double> m_binMax;         
    std::vector<double> m_smoothedLevels; 
};

#endif