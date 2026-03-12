#pragma once

#include <QObject>
#include <QVariantList>
#include <qqml.h>

class ProductConfig : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList products READ products NOTIFY productsChanged)
    QML_ELEMENT

public:
    explicit ProductConfig(QObject *parent = nullptr);

    QVariantList products() const { return m_products; }

signals:
    void productsChanged();

private:
    void load();
    QVariantList m_products;
};
