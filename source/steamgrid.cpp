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

static const QMap<QString, QString> ENDPOINTS = {
    {"Grids", "grids"}, {"Heroes", "heroes"}, {"Logos", "logos"}, {"Icons", "icons"}
};

QString SteamGrid::fileSuffix(const QString& type) {
    if (type == "Heroes") return "_hero";
    if (type == "Logos")  return "_logo";
    if (type == "Icons")  return "_icon";
    return "";
}

SteamGrid::SteamGrid(QObject* parent) : QObject(parent) {}


void SteamGrid::writeCache() {
    std::ofstream file(m_cacheFile.toStdString(), std::ios::trunc);
    if (!file.is_open()) return;
    file << "PATH="    << m_path.toStdString()   << "\n";
    file << "API_KEY=" << m_apiKey.toStdString() << "\n";
    for (const auto& item : m_gamesModel) {
        auto m = item.toMap();
        file << m["id"].toString().toStdString() << "-"
             << m["title"].toString().toStdString() << "\n";
    }
}

void SteamGrid::readCache() {
    std::ifstream file(m_cacheFile.toStdString());
    if (!file.is_open()) return;
    m_gamesModel.clear();
    std::string line;
    while (std::getline(file, line)) {
        if (line.empty()) continue;
        QString row = QString::fromStdString(line);
        if      (row.startsWith("PATH="))    m_path   = row.mid(5);
        else if (row.startsWith("API_KEY=")) m_apiKey = row.mid(8);
        else {
            int sep = row.indexOf('-');
            if (sep != -1)
                m_gamesModel.append(QVariantMap{{"id", row.left(sep)}, {"title", row.mid(sep + 1)}});
        }
    }
    emit configChanged();
    emit gamesModelChanged();
}

void SteamGrid::init() {
    fs::exists(m_cacheFile.toStdString()) ? readCache() : emit cacheExistsChanged();
}


void SteamGrid::saveConfiguration(const QString& apiKey, const QString& steamPath) {
    if (apiKey.trimmed().isEmpty() || steamPath.trimmed().isEmpty()) return;

    bool pathChanged = (m_path != steamPath.trimmed());
    m_apiKey = apiKey.trimmed();
    m_path   = steamPath.trimmed();
    emit configChanged();
    writeCache();

    if (pathChanged || m_gamesModel.isEmpty()) {
        emit cacheStarted();
        (void)QtConcurrent::run([this]() { buildCache(); });
    } else {
        emit cacheExistsChanged();
        QTimer::singleShot(100, this, [this] { emit progressChanged(1.0); });
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

QString SteamGrid::fetchGameName(const std::string& appId) {
    auto r = cpr::Get(
        cpr::Url{"https://www.steamgriddb.com/api/v2/games/steam/" + appId},
        cpr::Header{{"Authorization", "Bearer " + m_apiKey.toStdString()}}
    );
    if (r.status_code != 200) return {};
    try {
        auto data = json::parse(r.text);
        if (data["success"].get<bool>() && !data["data"].is_null())
            return QString::fromStdString(data["data"]["name"].get<std::string>());
    } catch (...) {}
    return {};
}

void SteamGrid::buildCache() {
    std::string libDir = m_path.toStdString() + "\\librarycache";

    auto emitProgress = [this](double p) {
        QMetaObject::invokeMethod(this, [this, p] { emit progressChanged(p); },
                                  Qt::QueuedConnection);
    };

    if (!fs::exists(libDir)) { emitProgress(1.0); return; }

    std::set<std::string> allIds;
    for (auto& entry : fs::directory_iterator(libDir)) {
        if (!entry.is_regular_file()) continue;
        std::string id;
        for (char c : entry.path().filename().string())
            if (isdigit(c)) id += c; else break;
        if (!id.empty()) allIds.insert(id);
    }

    int total = static_cast<int>(allIds.size());
    if (total == 0) { emitProgress(1.0); return; }

    emitProgress(0.01);

    int current = 0;
    QVariantList result;
    for (const auto& id : allIds) {
        double pct = static_cast<double>(++current) / total;
        emitProgress(pct);

        QString name = fetchGameName(id);
        if (name.isEmpty()) continue;
        result.append(QVariantMap{{"id", QString::fromStdString(id)}, {"title", name}});
    }

    QMetaObject::invokeMethod(this, [this, result]() {
        m_gamesModel = result;
        writeCache();
        emit gamesModelChanged();
        emit cacheExistsChanged();
        emit progressChanged(1.0);
    }, Qt::QueuedConnection);
}

void SteamGrid::searchImages(const QString& steamAppId, const QString& type) {
    if (m_apiKey.isEmpty() || steamAppId.isEmpty()) return;

    m_isLoadingImages = true;
    m_imagesModel.clear();
    emit isLoadingImagesChanged();
    emit imagesModelChanged();

    QString endpoint = ENDPOINTS.value(type, "grids");

    (void)QtConcurrent::run([this, steamAppId, endpoint]() {
        std::string url = "https://www.steamgriddb.com/api/v2/"
                        + endpoint.toStdString()
                        + "/steam/" + steamAppId.toStdString();

        auto r = cpr::Get(
            cpr::Url{url},
            cpr::Header{{"Authorization", "Bearer " + m_apiKey.toStdString()}}
        );


        QVariantList result;
        if (r.status_code == 200) {
            try {
                auto data = json::parse(r.text);
                if (data["success"].get<bool>()) {
                    for (auto& item : data["data"]) {
                        QString itemUrl   = QString::fromStdString(item["url"].get<std::string>());
                        QString itemThumb = (item.contains("thumb") && !item["thumb"].is_null())
                            ? QString::fromStdString(item["thumb"].get<std::string>()) : itemUrl;
                        result.append(QVariantMap{
                            {"url",    itemUrl},
                            {"thumb",  itemThumb},
                            {"width",  item.value("width",  0)},
                            {"height", item.value("height", 0)},
                            {"id",     item["id"].get<int>()}
                        });
                    }
                }
            } catch (const std::exception& e) {
                qDebug() << "searchImages JSON error:" << e.what();
            }
        }

        QMetaObject::invokeMethod(this, [this, result]() {
            m_imagesModel     = result;
            m_isLoadingImages = false;
            emit imagesModelChanged();
            emit isLoadingImagesChanged();
        }, Qt::QueuedConnection);
    });
}

void SteamGrid::downloadAndReplace(const QString& url, const QString& steamAppId, const QString& type) {
    if (url.isEmpty() || steamAppId.isEmpty()) return;
    m_downloadStatus = "";
    emit downloadStatusChanged();

    (void)QtConcurrent::run([this, url, steamAppId, type]() {
        QString ext      = url.section('.', -1).toLower();
        if (ext.isEmpty() || ext.length() > 5) ext = "png";
        QString suffix   = fileSuffix(type);
        QString baseName = steamAppId + (type == "Grids" ? suffix + "p" : suffix);

        std::string dir = m_path.toStdString() + "\\grid\\";
        fs::create_directories(dir);

        for (auto& oldExt : {"png", "jpg", "jpeg", "webp", "gif"}) {
            std::string old = dir + baseName.toStdString() + "." + oldExt;
            if (fs::exists(old)) fs::remove(old);
        }

        auto r = cpr::Get(
            cpr::Url{url.toStdString()},
            cpr::Header{{"User-Agent", "Mozilla/5.0"}}
        );

        QString status;
        if (r.status_code == 200) {
            std::ofstream ofs(dir + baseName.toStdString() + "." + ext.toStdString(),
                              std::ios::binary);
            if (ofs.is_open()) {
                ofs.write(r.text.data(), static_cast<std::streamsize>(r.text.size()));
                status = "OK";
            } else {
                status = "Error: no write permission";
            }
        } else {
            status = "HTTP " + QString::number(r.status_code);
        }

        QMetaObject::invokeMethod(this, [this, status]() {
            m_downloadStatus = status;
            emit downloadStatusChanged();
        }, Qt::QueuedConnection);
    });
}