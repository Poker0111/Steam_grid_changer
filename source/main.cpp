#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTranslator>
#include <QSettings>
#include <QQuickWindow>
#include <QtQuickControls2/QQuickStyle>
#include "steamgrid.h"

int main(int argc, char *argv[]) {
    qputenv("QML_XHR_ALLOW_FILE_READ", "1");

    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle("Basic");
    app.setWindowIcon(QIcon(":/SteamApp/resources/placeholder.ico"));

    QSettings settings("SteamGridChanger", "SteamGridChanger");
    QString lang = settings.value("language", "en").toString();
    QTranslator* translator = new QTranslator(&app);
    if (translator->load(":/translations/app_" + lang + ".qm"))
        app.installTranslator(translator);

    SteamGrid sg;
    sg.setCurrentLanguage(lang);
    sg.init();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("steamGrid", &sg);

    const QUrl url(QStringLiteral("qrc:/SteamApp/ui/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject* obj, const QUrl& objUrl) {
            if (!obj && url == objUrl) QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);

    engine.load(url);

    QObject::connect(&sg, &SteamGrid::languageChanged, [&, translator]() mutable {
        QString newLang = settings.value("language", "en").toString();

        app.removeTranslator(translator);
        delete translator;

        translator = new QTranslator(&app);
        if (translator->load(":/translations/app_" + newLang + ".qm"))
            app.installTranslator(translator);

        engine.clearComponentCache();
        engine.load(url);
    });

    return app.exec();
}
