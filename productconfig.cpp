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
    // Look for products.json next to the executable
    const QString path = QDir(QCoreApplication::applicationDirPath())
                             .filePath(QStringLiteral("products.json"));

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning("ProductConfig: could not open %s", qPrintable(path));
        return;
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

    emit productsChanged();
}
