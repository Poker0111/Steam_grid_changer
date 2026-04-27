#ifndef STEAMGRID_H
#define STEAMGRID_H

#include <QObject>
#include <QVariantList>
#include <QSettings>
#include <QtConcurrent>
#include <QString>
#include <filesystem>

class SteamGrid : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList gamesModel READ gamesModel NOTIFY gamesModelChanged)
    Q_PROPERTY(bool cacheExists READ cacheExistsNOTIFY cacheExistsChanged)
    Q_PROPERTY(QString apiKey READ apiKey NOTIFY configChanged)
    Q_PROPERTY(QString path READ path NOTIFY configChanged)
    Q_PROPERTY(QVariantList imagesModel READ imagesModel NOTIFY imagesModelChanged)
    Q_PROPERTY(bool isLoadingImages READ isLoadingImages NOTIFY isLoadingImagesChanged)
    Q_PROPERTY(bool hasMoreImages READ hasMoreImages NOTIFY hasMoreImagesChanged)
    Q_PROPERTY(QString downloadStatus READ downloadStatus NOTIFY downloadStatusChanged)
    Q_PROPERTY(QString currentLanguage READ currentLanguage NOTIFY languageChanged)

public:
    explicit SteamGrid(QObject* parent = nullptr);

    Q_INVOKABLE void init();
    Q_INVOKABLE void saveConfiguration(const QString& apiKey, const QString& steamPath);
    Q_INVOKABLE void createCache() { (void)QtConcurrent::run([this]() { buildCache(); }); }
    Q_INVOKABLE void reload() { (void)QtConcurrent::run([this]() { buildCache(); }); }
    Q_INVOKABLE void setLanguage(const QString& langCode);
    Q_INVOKABLE void searchImages(const QString& steamAppId, const QString& type);
    Q_INVOKABLE void loadMoreImages(const QString&, const QString&) {}
    Q_INVOKABLE void downloadAndReplace(const QString& url, const QString& steamAppId, const QString& type);

    void setCurrentLanguage(const QString& lang) { m_currentLanguage = lang; }

    QVariantList gamesModel() const { return m_gamesModel; }
    QVariantList imagesModel() const { return m_imagesModel; }
    bool isLoadingImages() const { return m_isLoadingImages; }
    bool hasMoreImages() const { return m_hasMoreImages; }
    bool cacheExists() const { return std::filesystem::exists(m_cacheFile.toStdString()); }
    QString apiKey() const { return m_apiKey; }
    QString path() const { return m_path; }
    QString downloadStatus() const { return m_downloadStatus; }
    QString currentLanguage() const { return m_currentLanguage; }

signals:
    void gamesModelChanged();
    void cacheExistsChanged();
    void configChanged();
    void progressChanged(double percent);
    void cacheStarted();
    void imagesModelChanged();
    void isLoadingImagesChanged();
    void hasMoreImagesChanged();
    void downloadStatusChanged();
    void languageChanged(const QString& langCode);

private:
    void writeCache();
    void readCache();
    void buildCache();
    QString fetchGameName(const std::string& appId);
    static QString fileSuffix(const QString& type);

    QVariantList m_gamesModel;
    QVariantList m_imagesModel;
    bool m_isLoadingImages=false;
    bool m_hasMoreImages=false;
    QString m_downloadStatus;
    QString m_currentLanguage="en";
    QString m_cacheFile="steamgrid.cache";
    QString m_apiKey;
    QString m_path;
};

#endif