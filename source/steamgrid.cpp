#include "steamgrid.h"
#include <iostream>
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

SteamGrid::SteamGrid(QObject *parent) : QObject(parent) {}

void SteamGrid::reload() {
    // (void) ucisza ostrzeżenie kompilatora o ignorowaniu wyniku
    (void)QtConcurrent::run([this]() { 
        this->createCache(); 
    });
}

void SteamGrid::writeCache() {
    std::ofstream file(m_cacheFile.toStdString(), std::ios::trunc);
    if (!file.is_open()) return;

    file << "PATH=" << m_path.toStdString() << "\n";
    file << "API_KEY=" << m_apiKey.toStdString() << "\n";

     for (const auto& item : m_gamesModel) {
        QVariantMap m = item.toMap();
        file << m["id"].toString().toStdString() << "-" 
             << m["title"].toString().toStdString() << "\n";
    }
    file.close();
}

int SteamGrid::getNameBySteamId(std::string id, std::string *name) {
    if (m_apiKey.isEmpty()) return -2;
    auto r = cpr::Get(cpr::Url{"https://www.steamgriddb.com/api/v2/games/steam/" + id},
                      cpr::Header{{"Authorization", "Bearer " + m_apiKey.toStdString()}});
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

void SteamGrid::readCache() {
    std::ifstream file(m_cacheFile.toStdString());
    if (!file.is_open()) return;
    std::string line;
    m_gamesModel.clear();
    while (std::getline(file, line)) {
        if (line.empty()) continue;
        QString data = QString::fromStdString(line);
        if (data.startsWith("PATH=")) m_path = data.mid(5);
        else if (data.startsWith("API_KEY=")) m_apiKey = data.mid(8);
        else {
            int d = data.indexOf('-');
            if (d != -1) m_gamesModel.append(QVariantMap{{"id", data.left(d)}, {"title", data.mid(d+1)}});
        }
    }
    emit configChanged();
    emit gamesModelChanged();
}

void SteamGrid::createCache() {
    emit progressChanged(0.01);
    std::string ps = m_path.toStdString()+"\\librarycache";
    if (!fs::exists(ps)) { emit progressChanged(1.0); return;}

    QVariantList temp; std::set<std::string> ids; int total = 0;
    for (auto& e : fs::directory_iterator(ps)) if (e.is_regular_file()) total++;
    if (total == 0) { emit progressChanged(1.0); return; }

    int current = 0;
    for (auto& entry : fs::directory_iterator(ps)) {
        current++; emit progressChanged(static_cast<double>(current) / total);
        if (entry.is_regular_file()) {
            std::string fn = entry.path().filename().string(), id = "";
            for (char c : fn) { if (isdigit(c)) id += c; else break; }
            std::string gn;
            if (!id.empty() && ids.find(id) == ids.end() && getNameBySteamId(id, &gn) == 0) {
                ids.insert(id);
                temp.append(QVariantMap{{"id", QString::fromStdString(id)}, {"title", QString::fromStdString(gn)}});
            }
        }
    }
    m_gamesModel = temp;
    writeCache();
    emit gamesModelChanged(); emit cacheExistsChanged(); emit progressChanged(1.0);
}

void SteamGrid::init() {
    fs::exists(m_cacheFile.toStdString()) ? readCache() : emit cacheExistsChanged();
}

void SteamGrid::saveConfiguration(QString apiKey, QString steamPath) {
    bool pathChanged = (m_path != steamPath);
    m_apiKey = apiKey;
    m_path = steamPath;
    emit configChanged();
    writeCache();
    if (pathChanged || m_gamesModel.isEmpty()) {
        (void)QtConcurrent::run([this]() { this->createCache(); });
    } else {
        emit cacheExistsChanged();
        QTimer::singleShot(100, [this](){ emit progressChanged(1.0); });
    }
}