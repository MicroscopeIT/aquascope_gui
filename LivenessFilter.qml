import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

GroupBox {
    id: gb
    property alias checkBoxChecked: livenessCkbx.checked

    label: CheckBox {
        id: livenessCkbx
        checked: true
        text: qsTr("Liveness")
    }

    ColumnLayout {
        anchors.fill: parent
        enabled: livenessCkbx.checked
        CheckBox { text: qsTr("Alive") }
        CheckBox { text: qsTr("Dead") }
        CheckBox { text: qsTr("Not specified") }
    }
}
