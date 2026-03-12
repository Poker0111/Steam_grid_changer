#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQuickControls2/QQuickStyle>
#include <QQmlContext>
#include <QQuickWindow>
#include "steamgrid.h"

int main(int argc, char *argv[]) {
    // 1. USTAWIANIE PARAMETRÓW EKRANU (MUSI BYĆ PRZED app!)
    // To zapobiega rozmyciu i szarpaniu krawędzi przy skalowaniu Windowsa
    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);
    
    // To mówi Qt, żeby brało ustawienia czcionek i wygładzania z systemu
    QGuiApplication::setDesktopSettingsAware(true);

    // 2. INICJALIZACJA APLIKACJI
    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle("Basic");

    // 3. WYMUSZENIE RENDEROWANIA (TUŻ PO app)
    QQuickWindow::setTextRenderType(QQuickWindow::NativeTextRendering);

    SteamGrid sg;
    sg.init();

    QQmlApplicationEngine engine;

    // Rejestrujemy obiekt dla QML
    engine.rootContext()->setContextProperty("steamGrid", &sg);

    const QUrl url(QStringLiteral("qrc:/SteamApp/ui/Main.qml"));
    
    // Sprawdzanie błędów ładowania (warto mieć dla debugowania)
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}