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

static constexpr int PAGE_SIZE = 50;

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
    auto r = cpr::Get(
        cpr::Url{"https://www.steamgriddb.com/api/v2/games/steam/" + steamAppId},
        cpr::Header{{"Authorization", "Bearer " + m_apiKey.toStdString()}}
    );
    if (r.status_code != 200) return -1;
    try {
        auto data = json::parse(r.text);
        if (data["success"].get<bool>() && !data["data"].is_null())
            return data["data"]["id"].get<int>();
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
    if (total == 0) { emit progressChanged(1.0); return; }

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
    m_gamesModel = temp;
    writeCache();
    emit gamesModelChanged();
    emit cacheExistsChanged();
    emit progressChanged(1.0);
}

void SteamGrid::fetchImages(const QString& steamAppId, const QString& type,
                             int page, bool append) {
    if (m_apiKey.isEmpty() || steamAppId.isEmpty()) return;

    m_isLoadingImages = true;
    emit isLoadingImagesChanged();

    if (!append) {
        m_imagesModel.clear();
        emit imagesModelChanged();
    }

    const QMap<QString, QString> endpointMap = {
        {"Grids",  "grids"},
        {"Heroes", "heroes"},
        {"Logos",  "logos"},
        {"Icons",  "icons"}
    };
    QString endpoint = endpointMap.value(type, "grids");
    int offset = (page - 1) * PAGE_SIZE;

    (void)QtConcurrent::run([this, steamAppId, endpoint, offset, append]() {
        int sgdbId = getSgdbGameId(steamAppId.toStdString());
        if (sgdbId == -1) {
            qDebug() << "fetchImages: brak SGDB ID dla AppID" << steamAppId;
            QMetaObject::invokeMethod(this, [this]() {
                m_isLoadingImages = false;
                emit isLoadingImagesChanged();
            }, Qt::QueuedConnection);
            return;
        }

        std::string url = "https://www.steamgriddb.com/api/v2/"
                        + endpoint.toStdString()
                        + "/game/" + std::to_string(sgdbId)
                        + "?limit=" + std::to_string(PAGE_SIZE)
                        + "&offset=" + std::to_string(offset);

        auto r = cpr::Get(
            cpr::Url{url},
            cpr::Header{{"Authorization", "Bearer " + m_apiKey.toStdString()}}
        );

        qDebug() << "fetchImages HTTP" << r.status_code
                 << "| sgdbId:" << sgdbId
                 << "| offset:" << offset
                 << "| endpoint:" << endpoint;

        QVariantList newItems;
        bool hasMore = false;

        if (r.status_code == 200) {
            try {
                auto data = json::parse(r.text);
                if (data["success"].get<bool>()) {
                    auto& arr = data["data"];
                    for (auto& item : arr) {
                        QString itemUrl   = QString::fromStdString(item["url"].get<std::string>());
                        QString itemThumb = (item.contains("thumb") && !item["thumb"].is_null())
                            ? QString::fromStdString(item["thumb"].get<std::string>())
                            : itemUrl;

                        newItems.append(QVariantMap{
                            {"url",    itemUrl},
                            {"thumb",  itemThumb},
                            {"width",  item.value("width",  0)},
                            {"height", item.value("height", 0)},
                            {"id",     item["id"].get<int>()}
                        });
                    }
                    hasMore = (static_cast<int>(arr.size()) == PAGE_SIZE);
                }
            } catch (const std::exception& e) {
                qDebug() << "fetchImages JSON error:" << e.what();
            }
        }

        QMetaObject::invokeMethod(this, [this, newItems, hasMore, append]() {
            if (append)
                m_imagesModel.append(newItems);
            else
                m_imagesModel = newItems;

            m_isLoadingImages = false;
            m_hasMoreImages   = hasMore;
            emit imagesModelChanged();
            emit isLoadingImagesChanged();
            emit hasMoreImagesChanged();
        }, Qt::QueuedConnection);
    });
}

void SteamGrid::searchImages(const QString& steamAppId, const QString& type) {
    m_currentPage = 1;
    fetchImages(steamAppId, type, 1, false);
}

void SteamGrid::loadMoreImages(const QString& steamAppId, const QString& type) {
    if (!m_hasMoreImages || m_isLoadingImages) return;
    m_currentPage++;
    fetchImages(steamAppId, type, m_currentPage, true);
}

void SteamGrid::downloadAndReplace(const QString& url,
                                   const QString& steamAppId,
                                   const QString& type)
{
    if (url.isEmpty() || steamAppId.isEmpty()) return;

    m_downloadStatus = "";
    emit downloadStatusChanged();

    (void)QtConcurrent::run([this, url, steamAppId, type]() {
        QString ext      = url.section('.', -1).toLower();
        if (ext.isEmpty() || ext.length() > 5) ext = "png";

        QString suffix   = SteamGrid::fileSuffix(type);
        QString baseName = steamAppId + (type == "Grids" ? suffix + "p" : suffix);

        std::string gridDir = m_path.toStdString() + "\\grid\\";
        fs::create_directories(gridDir);

        for (auto& old_ext : {"png", "jpg", "jpeg", "webp", "gif"}) {
            std::string old = gridDir + baseName.toStdString() + "." + old_ext;
            if (fs::exists(old)) {
                fs::remove(old);
                qDebug() << "Usunięto:" << QString::fromStdString(old);
            }
        }

        std::string newPath = gridDir + baseName.toStdString() + "." + ext.toStdString();

        auto r = cpr::Get(
            cpr::Url{url.toStdString()},
            cpr::Header{{"User-Agent", "Mozilla/5.0"}}
        );

        QString status;
        if (r.status_code == 200) {
            std::ofstream ofs(newPath, std::ios::binary);
            if (ofs.is_open()) {
                ofs.write(r.text.data(), static_cast<std::streamsize>(r.text.size()));
                ofs.close();
                status = "OK: zapisano " + QString::fromStdString(newPath);
            } else {
                status = "Błąd: brak uprawnień do zapisu";
            }
        } else {
            status = "Błąd HTTP: " + QString::number(r.status_code);
        }

        QMetaObject::invokeMethod(this, [this, status]() {
            m_downloadStatus = status;
            emit downloadStatusChanged();
        }, Qt::QueuedConnection);
    });
}

void SteamGrid::setLanguage(const QString& langCode) {
    QSettings settings("SteamGridChanger", "SteamGridChanger");
    settings.setValue("language", langCode);
    emit languageChanged();
}
