import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    width: 800
    height: 520
    minimumWidth: 640
    minimumHeight: 420
    title: "LZ Software Studios - VKS"
    color: "white"

    palette {
        window:     "#ffffff"
        windowText: "#000000"
        button:     "#ffffff"
        buttonText: "#000000"
        base:       "#ffffff"
        text:       "#000000"
    }

    // ── Order data ──────────────────────────────────────────────────────────

    ListModel { id: orderModel }

    property string numInput: ""
    property real   orderTotal: 0.0

    // Products are loaded from products.json at startup via ProductConfig
    ProductConfig { id: config }

    // ── Business logic ──────────────────────────────────────────────────────

    function addProduct(name, price) {
        var qty = (numInput.length > 0 && parseInt(numInput) > 0)
                  ? parseInt(numInput) : 1
        for (var i = 0; i < orderModel.count; i++) {
            if (orderModel.get(i).itemName === name) {
                orderModel.setProperty(i, "itemQty",
                    orderModel.get(i).itemQty + qty)
                numInput = ""
                updateTotal()
                return
            }
        }
        orderModel.append({ itemName: name, itemQty: qty, itemPrice: price })
        numInput = ""
        updateTotal()
    }

    function updateTotal() {
        var t = 0.0
        for (var i = 0; i < orderModel.count; i++)
            t += orderModel.get(i).itemQty * orderModel.get(i).itemPrice
        orderTotal = t
    }

    function pressNum(digit) { numInput += digit }
    function pressDel()      { numInput = numInput.slice(0, -1) }
    function pressRdy()      { orderModel.clear(); numInput = ""; orderTotal = 0.0 }

    // ── Root layout ─────────────────────────────────────────────────────────

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // ════════════════════════════════════════════════
        //  LEFT  –  Product buttons
        // ════════════════════════════════════════════════
        GroupBox {
            title: "Artikel"
            Layout.fillHeight: true
            Layout.preferredWidth: Math.round(parent.width * 0.52)

            GridLayout {
                anchors.fill: parent
                columns: 3
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: config.products
                    Button {
                        text: modelData.name
                        Layout.fillWidth:  true
                        Layout.fillHeight: true
                        font.pixelSize: 17
                        font.bold: true
                        onClicked: root.addProduct(modelData.name, modelData.price)
                    }
                }
            }
        }

        // ════════════════════════════════════════════════
        //  RIGHT  –  Output + Numpad
        // ════════════════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            spacing: 12

            // ── Output ───────────────────────────────────
            GroupBox {
                title: "Kassenzettel"
                Layout.fillWidth:  true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    ListView {
                        id: orderList
                        Layout.fillWidth:  true
                        Layout.fillHeight: true
                        clip: true
                        model: orderModel

                        delegate: RowLayout {
                            width: orderList.width
                            spacing: 6

                            Label {
                                text: itemQty + "\u00D7"    // ×
                                font.pixelSize: 14
                                Layout.preferredWidth: 28
                            }
                            Label {
                                text: itemName
                                font.pixelSize: 14
                                Layout.fillWidth: true
                            }
                            Label {
                                text: "\u20AC " + (itemQty * itemPrice).toFixed(2)
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: 64
                            }
                        }
                    }

                    // Separator
                    Rectangle {
                        height: 1
                        color: "#aaaaaa"
                        Layout.fillWidth: true
                    }

                    // Total row
                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Total:"
                            font.bold: true
                            font.pixelSize: 15
                            Layout.fillWidth: true
                        }
                        Label {
                            text: "\u20AC " + root.orderTotal.toFixed(2)
                            font.bold: true
                            font.pixelSize: 15
                        }
                    }
                }
            }

            // ── Numpad ───────────────────────────────────
            GroupBox {
                title: "Manuelle Eingabe"
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 5

                    // -- Quantity display --
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        border.color: "#aaaaaa"
                        border.width: 1
                        radius: 4
                        color: "white"

                        Label {
                            anchors {
                                right: parent.right; rightMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            text: root.numInput.length > 0 ? root.numInput : "0"
                            font.pixelSize: 18
                        }
                    }

                    // -- Keys --
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        rowSpacing: 5
                        columnSpacing: 5

                        // ── Row 1: 7  8  9  DEL ──
                        Button {
                            text: "7"
                            Layout.fillWidth: true; Layout.preferredHeight: 44
                            font.pixelSize: 16
                            onClicked: root.pressNum("7")
                        }
                        Button {
                            text: "8"
                            Layout.fillWidth: true; Layout.preferredHeight: 44
                            font.pixelSize: 16
                            onClicked: root.pressNum("8")
                        }
                        Button {
                            text: "9"
                            Layout.fillWidth: true; Layout.preferredHeight: 44
                            font.pixelSize: 16
                            onClicked: root.pressNum("9")
                        }
                        Button {
                            text: "DEL"
                            Layout.fillWidth: true; Layout.preferredHeight: 44
                            font.pixelSize: 14
                            onClicked: root.pressDel()
                            background: Rectangle {
                                color: parent.pressed ? "#e57373" : "#ef9a9a"
                                radius: 4
                            }
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: "black"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // ── Row 2: 4  5  6  (empty) ──
                        Button {
                            text: "4"
                            Layout.fillWidth: true; Layout.preferredHeight: 44
                            font.pixelSize: 16
                            onClicked: root.pressNum("4")
                        }
                        Button {
                            text: "5"
                            Layout.fillWidth: true; Layout.preferredHeight: 44
                            font.pixelSize: 16
                            onClicked: root.pressNum("5")
                        }
                        Button {
                            text: "6"
                            Layout.fillWidth: true; Layout.preferredHeight: 44
                            font.pixelSize: 16
                            onClicked: root.pressNum("6")
                        }
                        Item { Layout.fillWidth: true; Layout.preferredHeight: 44 }

                        // ── Row 3: 1  2  3  (empty) ──
                        Button {
                            text: "1"
                            Layout.fillWidth: true; Layout.preferredHeight: 44
                            font.pixelSize: 16
                            onClicked: root.pressNum("1")
                        }
                        Button {
                            text: "2"
                            Layout.fillWidth: true; Layout.preferredHeight: 44
                            font.pixelSize: 16
                            onClicked: root.pressNum("2")
                        }
                        Button {
                            text: "3"
                            Layout.fillWidth: true; Layout.preferredHeight: 44
                            font.pixelSize: 16
                            onClicked: root.pressNum("3")
                        }
                        Item { Layout.fillWidth: true; Layout.preferredHeight: 44 }

                        // ── Row 4:  0 (spans 3 cols)  RDY ──
                        Button {
                            text: "0"
                            Layout.columnSpan: 3
                            Layout.fillWidth: true; Layout.preferredHeight: 44
                            font.pixelSize: 16
                            onClicked: root.pressNum("0")
                        }
                        Button {
                            text: "RDY"
                            Layout.fillWidth: true; Layout.preferredHeight: 44
                            font.pixelSize: 14
                            font.bold: true
                            onClicked: root.pressRdy()
                            background: Rectangle {
                                color: parent.pressed ? "#66bb6a" : "#a5d6a7"
                                radius: 4
                            }
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: "black"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
