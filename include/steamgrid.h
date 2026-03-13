#ifndef STEAMGRID_H
#define STEAMGRID_H

#include <QObject>
#include <QVariantList>
#include <QtConcurrent>
#include <QString>
#include <filesystem>

class SteamGrid : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList gamesModel READ gamesModel NOTIFY gamesModelChanged)
    Q_PROPERTY(bool cacheExists READ cacheExists NOTIFY cacheExistsChanged)
    Q_PROPERTY(QString apiKey READ apiKey NOTIFY configChanged)
    Q_PROPERTY(QString path READ path NOTIFY configChanged)

public:
    explicit SteamGrid(QObject *parent = nullptr);

    Q_INVOKABLE void init();
    Q_INVOKABLE void saveConfiguration(QString apiKey, QString steamPath);
    Q_INVOKABLE void createCache();
    Q_INVOKABLE void reload(); // Tylko deklaracja tutaj

    QVariantList gamesModel() const { return m_gamesModel; }
    bool cacheExists() const { return std::filesystem::exists(m_cacheFile.toStdString()); }
    QString apiKey() const { return m_apiKey; }
    QString path() const { return m_path; }

signals:
    void gamesModelChanged();
    void cacheExistsChanged();
    void configChanged();
    void progressChanged(double percent);

private:
    void writeCache();
    void readCache();
    int getNameBySteamId(std::string id, std::string *name);

    QVariantList m_gamesModel;
    QString m_cacheFile = "steamgrid.cache";
    QString m_apiKey;
    QString m_path;
};

#endif