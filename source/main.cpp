#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQuickControls2/QQuickStyle>
#include <QQmlContext>
#include "steamgrid.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle("Basic");

    SteamGrid sg;
    sg.init(); // Sprawdza cache przy starcie

    QQmlApplicationEngine engine;
    // Rejestrujemy obiekt, aby był dostępny w QML jako 'steamGrid'
    engine.rootContext()->setContextProperty("steamGrid", &sg);

    const QUrl url(QStringLiteral("qrc:/SteamApp/ui/Main.qml"));
    engine.load(url);

    return app.exec();
}