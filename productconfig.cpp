#include "productconfig.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

ProductConfig::ProductConfig(QObject *parent) : QObject(parent)
{
    load();
}

void ProductConfig::load()
{
    const QString localPath = QDir(QCoreApplication::applicationDirPath())
                              .filePath(QStringLiteral("products.json"));

    QFile file(localPath);
    if (!file.open(QIODevice::ReadOnly)) {
        const QString candidates[] = {
            QStringLiteral(":/products.json"),
            QStringLiteral("qrc:/products.json"),
            QStringLiteral("assets:/products.json"),
            QStringLiteral("assets/products.json"),
            QStringLiteral("products.json")
        };
        bool opened = false;
        for (const QString &candidate : candidates) {
            qInfo("ProductConfig: candidate exists %s => %d", qPrintable(candidate), QFile::exists(candidate));
            file.setFileName(candidate);
            if (file.open(QIODevice::ReadOnly)) {
                qInfo("ProductConfig: opened candidate %s", qPrintable(candidate));
                opened = true;
                break;
            }
        }
        if (!opened) {
            qWarning("ProductConfig: could not open %s or any candidate", qPrintable(localPath));
            return;
        }
    }

    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &err);
    if (err.error != QJsonParseError::NoError) {
        qWarning("ProductConfig: JSON parse error: %s", qPrintable(err.errorString()));
        return;
    }

    const QJsonArray arr = doc.object().value(QStringLiteral("products")).toArray();
    for (const QJsonValue &v : arr) {
        const QJsonObject obj = v.toObject();
        m_products.append(QVariantMap{
            { QStringLiteral("name"),  obj[QStringLiteral("name")].toString()  },
            { QStringLiteral("price"), obj[QStringLiteral("price")].toDouble() }
        });
    }

    qInfo("ProductConfig: loaded %d products from %s", m_products.count(), qPrintable(file.fileName()));
    emit productsChanged();
}
