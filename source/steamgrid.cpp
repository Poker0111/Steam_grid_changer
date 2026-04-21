#include "steamgrid.h"
#include <fstream>
#include <filesystem>
#include <nlohmann/json.hpp>
#include <cpr/cpr.h>
#include <QDebug>
#include <QtConcurrent>
#include <QTimer>
#include <set>

namespace fs = std::filesystem;
using json = nlohmann::json;


static constexpr int MAX_BATCH = 5000;

QString SteamGrid::fileSuffix(const QString& type) {
    if (type == "Heroes") return "_hero";
    if (type == "Logos")  return "_logo";
    if (type == "Icons")  return "_icon";
    return "";
}

SteamGrid::SteamGrid(QObject *parent) : QObject(parent) {}

void SteamGrid::writeCache() {
    std::ofstream file(m_cacheFile.toStdString(), std::ios::trunc);
    if (!file.is_open()) return;
    file << "PATH="    << m_path.toStdString()   << "\n";
    file << "API_KEY=" << m_apiKey.toStdString() << "\n";
    for (const auto& item : m_gamesModel) {
        QVariantMap m = item.toMap();
        file << m["id"].toString().toStdString() << "-"
             << m["title"].toString().toStdString() << "\n";
    }
}

void SteamGrid::readCache() {
    std::ifstream file(m_cacheFile.toStdString());
    if (!file.is_open()) return;
    std::string line;
    m_gamesModel.clear();
    while (std::getline(file, line)) {
        if (line.empty()) continue;
        QString data = QString::fromStdString(line);
        if      (data.startsWith("PATH="))    m_path   = data.mid(5);
        else if (data.startsWith("API_KEY=")) m_apiKey = data.mid(8);
        else {
            int d = data.indexOf('-');
            if (d != -1)
                m_gamesModel.append(QVariantMap{{"id", data.left(d)}, {"title", data.mid(d+1)}});
        }
    }
    emit configChanged();
    emit gamesModelChanged();
}

void SteamGrid::init() {
    fs::exists(m_cacheFile.toStdString()) ? readCache() : emit cacheExistsChanged();
}

void SteamGrid::reload() {
    (void)QtConcurrent::run([this]() { this->createCache(); });
}

void SteamGrid::saveConfiguration(QString apiKey, QString steamPath) {
    bool pathChanged = (m_path != steamPath);
    m_apiKey = apiKey;
    m_path   = steamPath;
    emit configChanged();
    writeCache();
    if (pathChanged || m_gamesModel.isEmpty()) {
        (void)QtConcurrent::run([this]() { this->createCache(); });
    } else {
        emit cacheExistsChanged();
        QTimer::singleShot(100, [this](){ emit progressChanged(1.0); });
    }
}

void SteamGrid::setLanguage(const QString& langCode) {
    if (m_currentLanguage == langCode) return;
    m_currentLanguage = langCode;
    QSettings settings("SteamGridChanger", "SteamGridChanger");
    settings.setValue("language", langCode);
    settings.sync();
    emit languageChanged(langCode);
}

int SteamGrid::getNameBySteamId(std::string id, std::string* name) {
    if (m_apiKey.isEmpty()) return -2;
    auto r = cpr::Get(
        cpr::Url{"https://www.steamgriddb.com/api/v2/games/steam/" + id},
        cpr::Header{{"Authorization", "Bearer " + m_apiKey.toStdString()}}
    );
    if (r.status_code == 200) {
        try {
            auto data = json::parse(r.text);
            if (data["success"].get<bool>() && !data["data"].is_null()) {
                *name = data["data"]["name"].get<std::string>();
                return 0;
            }
        } catch (...) { return -1; }
    }
    return r.status_code;
}

int SteamGrid::getSgdbGameId(const std::string& steamAppId) {
    QString key = QString::fromStdString(steamAppId);
    if (m_sgdbIdCache.contains(key)) return m_sgdbIdCache[key];

    auto r = cpr::Get(
        cpr::Url{"https://www.steamgriddb.com/api/v2/games/steam/" + steamAppId},
        cpr::Header{{"Authorization", "Bearer " + m_apiKey.toStdString()}}
    );
    if (r.status_code != 200) return -1;
    try {
        auto data = json::parse(r.text);
        if (data["success"].get<bool>() && !data["data"].is_null()) {
            int id = data["data"]["id"].get<int>();
            m_sgdbIdCache[key] = id;
            return id;
        }
    } catch (...) {}
    return -1;
}

void SteamGrid::createCache() {
    emit progressChanged(0.01);
    std::string ps = m_path.toStdString() + "\\librarycache";
    if (!fs::exists(ps)) { emit progressChanged(1.0); return; }

    QVariantList temp;
    std::set<std::string> ids;
    int total = 0, current = 0;
    for (auto& e : fs::directory_iterator(ps)) if (e.is_regular_file()) total++;
    
    for (auto& entry : fs::directory_iterator(ps)) {
        current++;
        emit progressChanged(static_cast<double>(current) / total);
        if (!entry.is_regular_file()) continue;
        std::string fn = entry.path().filename().string(), id;
        for (char c : fn) { if (isdigit(c)) id += c; else break; }
        std::string gn;
        if (!id.empty() && ids.find(id) == ids.end() && getNameBySteamId(id, &gn) == 0) {
            ids.insert(id);
            temp.append(QVariantMap{{"id", QString::fromStdString(id)}, {"title", QString::fromStdString(gn)}});
        }
    }
    
    QMetaObject::invokeMethod(this, [this, temp]() {
        m_gamesModel = temp;
        writeCache();
        emit gamesModelChanged();
        emit cacheExistsChanged();
        emit progressChanged(1.0);
    }, Qt::QueuedConnection);
}

void SteamGrid::fetchImages(const QString& steamAppId, const QString& type, int page, bool append) {
    if (m_apiKey.isEmpty() || steamAppId.isEmpty()) return;

    m_isLoadingImages = true;
    emit isLoadingImagesChanged();

    const QMap<QString, QString> endpointMap = {
        {"Grids", "grids"}, {"Heroes", "heroes"}, {"Logos", "logos"}, {"Icons", "icons"}
    };
    QString endpoint = endpointMap.value(type, "grids");

    (void)QtConcurrent::run([this, steamAppId, endpoint, append]() {
        int sgdbId = getSgdbGameId(steamAppId.toStdString());
        QVariantList validNewItems;

        if (sgdbId != -1) {

            std::string url = "https://www.steamgriddb.com/api/v2/" + endpoint.toStdString() +
                              "/game/" + std::to_string(sgdbId) + "?limit=" + std::to_string(MAX_BATCH);

            auto r = cpr::Get(cpr::Url{url}, cpr::Header{{"Authorization", "Bearer " + m_apiKey.toStdString()}});

            if (r.status_code == 200) {
                try {
                    auto data = json::parse(r.text);
                    if (data["success"].get<bool>()) {
                        for (auto& item : data["data"]) {
                            QString itemUrl = QString::fromStdString(item["url"].get<std::string>());
                            QString itemThumb = (item.contains("thumb") && !item["thumb"].is_null())
                                ? QString::fromStdString(item["thumb"].get<std::string>()) : itemUrl;
                            
                            validNewItems.append(QVariantMap{
                                {"url", itemUrl}, {"thumb", itemThumb},
                                {"width", item.value("width", 0)}, {"height", item.value("height", 0)},
                                {"id", item["id"].get<int>()}
                            });
                        }
                    }
                } catch (...) {}
            }
        }

        QMetaObject::invokeMethod(this, [this, validNewItems, append]() {
            if (!append) m_imagesModel.clear();
            m_imagesModel += validNewItems;
            
            m_isLoadingImages = false;
            m_hasMoreImages = false; 

            emit imagesModelChanged();
            emit isLoadingImagesChanged();
            emit hasMoreImagesChanged();
        }, Qt::QueuedConnection);
    });
}

void SteamGrid::searchImages(const QString& steamAppId, const QString& type) {
    m_imagesModel.clear(); 
    emit imagesModelChanged();
    fetchImages(steamAppId, type, 1, false);
}

void SteamGrid::loadMoreImages(const QString& steamAppId, const QString& type) {
}

void SteamGrid::downloadAndReplace(const QString& url, const QString& steamAppId, const QString& type) {
    if (url.isEmpty() || steamAppId.isEmpty()) return;
    m_downloadStatus = "";
    emit downloadStatusChanged();

    (void)QtConcurrent::run([this, url, steamAppId, type]() {
        QString ext = url.section('.', -1).toLower();
        if (ext.isEmpty() || ext.length() > 5) ext = "png";
        QString suffix = SteamGrid::fileSuffix(type);
        QString baseName = steamAppId + (type == "Grids" ? suffix + "p" : suffix);

        std::string gridDir = m_path.toStdString() + "\\grid\\";
        fs::create_directories(gridDir);

        for (auto& old_ext : {"png", "jpg", "jpeg", "webp", "gif"}) {
            std::string old = gridDir + baseName.toStdString() + "." + old_ext;
            if (fs::exists(old)) fs::remove(old);
        }

        std::string newPath = gridDir + baseName.toStdString() + "." + ext.toStdString();
        auto r = cpr::Get(cpr::Url{url.toStdString()}, cpr::Header{{"User-Agent", "Mozilla/5.0"}});

        QString status;
        if (r.status_code == 200) {
            std::ofstream ofs(newPath, std::ios::binary);
            if (ofs.is_open()) {
                ofs.write(r.text.data(), static_cast<std::streamsize>(r.text.size()));
                ofs.close();
                status = "OK";
            } else status = "Error";
        } else status = "HTTP " + QString::number(r.status_code);

        QMetaObject::invokeMethod(this, [this, status]() {
            m_downloadStatus = status;
            emit downloadStatusChanged();
        });
    });
}