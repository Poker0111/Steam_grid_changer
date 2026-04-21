#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTranslator>
#include <QSettings>
#include <QtQuickControls2/QQuickStyle>
#include <QDebug>
#include "steamgrid.h"

int main(int argc, char *argv[]) {
    qputenv("QML_XHR_ALLOW_FILE_READ", "1");

    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle("Basic");

    QSettings settings("SteamGridChanger", "SteamGridChanger");
    QString lang = settings.value("language", "en").toString();
    static QTranslator* translator = new QTranslator(&app);
        app.installTranslator(translator);

    SteamGrid sg;
    sg.setCurrentLanguage(lang);
    sg.init();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("steamGrid", &sg);

    const QUrl url(QStringLiteral("qrc:/SteamApp/ui/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject* obj, const QUrl& objUrl) {
            if (!obj && url == objUrl) {
                qCritical() << "BLAD: Nie mozna zaladować pliku Main.qml!";
                QCoreApplication::exit(-1);
            }
        }, Qt::QueuedConnection);

    engine.load(url);

    QObject::connect(&sg, &SteamGrid::languageChanged, [&](const QString& newLang) {
        app.removeTranslator(translator);

        if (translator->load(":/i18n/app_" + newLang + ".qm")) {
            app.installTranslator(translator);
        } 
        settings.setValue("language", newLang);

        engine.retranslate(); 
    });

    return app.exec();
}