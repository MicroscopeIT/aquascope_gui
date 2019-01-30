import QtQuick 2.12
import QtQuick.Controls 2.12

GridView {

    property var filter: function(item) {
        return false
    }

    ScrollBar.vertical: ScrollBar {}

    delegate: Item {

        width: cellWidth
        height: cellWidth

        Rectangle {

            id: rect

            anchors.centerIn: parent
            width: parent.width - 10
            height: parent.height - 10

            states: [
                State {
                    when: filter(model)
                    name: "grayout"

                    PropertyChanges {
                        target: img
                        opacity: 0.4
                    }
                    PropertyChanges {
                        target: rect
                        border.color: 'darkblue'
                    }
                },
                State {
                    when: !model.selected
                    name: "basic"
                    PropertyChanges {
                        target: rect

                        border.color: 'darkblue'
                        border.width: 2
                        color: 'lightgray'
                    }
                },
                State {
                    when: model.selected
                    name: "selected"
                    PropertyChanges {
                        target: rect

                        border.color: 'red'
                        border.width: 4
                        color: 'lightblue'
                    }
                }
            ]

            Image {
                id: img
                width: parent.width - 10
                height: parent.height - 10

                fillMode: Image.PreserveAspectFit

                anchors.centerIn: parent

                source: image
                clip: true
            }

            MouseArea {
                anchors.fill: parent

                onClicked: model.selected = !model.selected
            }
        }
    }
}
