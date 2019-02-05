import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Rectangle {
    border.color: 'lightgray'

    property var criteria: {
        if(taxonomyRbtn.checked)
            return taxonomyfltr.criteria

        if(livenessRbtn.checked)
            return livenessfltr.criteria

        return { dummyExclusive: true }
    }


    signal applyClicked()

    ScrollView {

        anchors.fill: parent
        contentWidth: width

        ColumnLayout {
            width: parent.width

            ButtonGroup { id: radioGroup }

            Label {
                Layout.fillWidth: true
                text: qsTr("Annotation")
                font.pixelSize: 25
                horizontalAlignment: Text.AlignHCenter
            }

            GroupBox {
                Layout.fillWidth: true

                label: RadioButton {
                    id: taxonomyRbtn
                    checked: false
                    text: qsTr("Taxonomy")
                    ButtonGroup.group: radioGroup
                }

                TaxonomyFilter {
                    id: taxonomyfltr
                    annotationMode: true
                    enabled: taxonomyRbtn.checked
                }
            }

            GroupBox {
                Layout.fillWidth: true

                label: RadioButton {
                    id: livenessRbtn
                    checked: false
                    text: qsTr("Liveness")
                    ButtonGroup.group: radioGroup
                }

                LivenessFilter {
                    id: livenessfltr
                    enabled: livenessRbtn.checked
                    annotationMode: true
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }


            Button {
                text: 'Apply to selected images'
                enabled: radioGroup.checkState !== Qt.Unchecked
                Layout.alignment: Qt.AlignCenter

                onClicked: applyClicked()
            }
        }
    }
}