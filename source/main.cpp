#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQuickControls2/QQuickStyle>
#include <QQmlContext>
#include <QQuickWindow>
#include "steamgrid.h"

int main(int argc, char *argv[]) {
    qputenv("QML_XHR_ALLOW_FILE_READ", "1");
   
    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle("Basic");

    SteamGrid sg;
    sg.init();

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("steamGrid", &sg);

    const QUrl url(QStringLiteral("qrc:/SteamApp/ui/Main.qml"));
    
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}