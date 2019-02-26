import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import "qrc:/network"
import "qrc:/network/requests.js" as Req

ApplicationWindow {
    id: root
    visible: true

    width: 640 * 2
    height: 480 * 1.5

    title: qsTr("Aquascope Data Browser")

    readonly property var defaultSettings: ({
                                                host: 'http://localhost',
                                                username: 'aq_user',
                                                password : 'hardpass'
                                            })

    readonly property var settingsFromFile:
        settingsPath ? Req.readJsonFromLocalFileSync(settingsPath) : null

    property var currentFilter: {}
    property string currentSas: ''
    property bool viewPopulated: false
    property real lastContentYPos: 0
    property var currentUser: getSettingVariable('username')

    function storeScrollLastPos() {
        lastContentYPos = imageViewAndControls.imageView.getContentY()
    }

    function restoreScrollLastPos(){
        imageViewAndControls.imageView.setContentY(lastContentYPos)
    }

    function getSettingVariable(key) {
        if(settingsFromFile) {
            if (settingsFromFile && settingsFromFile[key]) {
                return settingsFromFile[key]
            } else {
                console.log('No"' + key + '" field found in settings.')
            }
        } else {
            console.log('Settings file not found. Using default value for', key)
        }

        if (defaultSettings[key]) {
            return defaultSettings[key]
        } else {
            console.log('key ' + key
                        + ' not found in dafaults array. Returning null')
            return null
        }
    }

    function getCurrentFilter() {
        if (currentFilter) {
            return JSON.parse(JSON.stringify(currentFilter))
        }
        return {}
    }

    property alias address : uploadDialog.address
    property alias token : uploadDialog.token
    property bool uploadInProgress: false

    address: getSettingVariable('host')
    token: dataAccess.internal.access_token


    UploadDialog {
        id: uploadDialog
        onSuccess: {
            uploadButton.background.color = 'lightgreen'
            uploadInProgress = false
        }
        onError: {
            uploadButton.background.color = 'lightcoral'
            uploadInProgress = false
        }
        onUploadStarted: {
            uploadButton.background.color = 'lightgray'
            uploadInProgress = true
        }
    }

    ExportDialog {
           id: exportDialog
           onAccepted: exportItems.call(exportDialog.exportCriteria)
    }

    PageLoader {
        id: pageLoader

        appendDataToModel: imageViewAndControls.imageView.appendData
        restoreModelViewLastPos: restoreScrollLastPos

        currentSas: root.currentSas
    }

    ColumnLayout {

        anchors.fill: parent

        Rectangle{
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            border.color: 'lightgray'

            RowLayout {
                anchors.fill: parent

                Item {
                    Layout.fillWidth: true
                }

                Label {
                    text: qsTr("You are signed in as: ")
                }

                Label {
                    text: getSettingVariable('username')
                    font.bold: true
                    rightPadding: 10
                }

                ToolButton {
                    text: qsTr("Export")
                    Layout.rightMargin: 5
                    onClicked: exportDialog.open()
                }

                DelayButton {
                    id: uploadButton
                    Layout.rightMargin: 5

                    text: 'Upload data'
                    delay: 0
                    progress: uploadDialog.uploadProgress

                    onClicked: {
                        if(!uploadInProgress) uploadButton.background.color = 'lightgray'
                        uploadDialog.open()
                    }
                }

                ToolButton {
                    text: qsTr("⋮")
                    Layout.rightMargin: 5
                    onClicked: { console.log("Settings not yet implemented") }
                }

                ToolButton {
                    text: qsTr("Log out")
                    Layout.rightMargin: 15
                    onClicked: { console.log("Logout not yet implemented") }
                }
            }
        }

        RowLayout {
            Layout.fillHeight: true

            FilteringPane {

                Layout.preferredWidth: 300
                Layout.fillHeight: true

                onApplyClicked: {
                    currentFilter = filter
                    imageViewAndControls.imageView.clearData()
                    storeScrollLastPos()
                    pageLoader.resetPagesStatus()
                    pageLoader.loadNextPage(getCurrentFilter())
                }

            }

            ImageViewAndControls {
                id: imageViewAndControls

                Layout.fillWidth: true
                Layout.fillHeight: true

                filter: ((criteria) => {
                             return (item) => {
                                 for (let c in criteria) {
                                     if (item.metadata[c] !== criteria[c])
                                     return false
                                 }
                                 return true
                             }

                         })(annotationPane.criteria)

                onAtPageBottom: {
                    if(pageLoader.internal.pageLoadingInProgress || pageLoader.internal.lastPageLoaded) return
                    storeScrollLastPos()
                    pageLoader.loadNextPage(getCurrentFilter())
                }
            }

            AnnotationPane {
                id: annotationPane
                Layout.preferredWidth: 300
                Layout.fillHeight: true

                onApplyClicked: {
                    storeScrollLastPos()

                    const model = imageViewAndControls.imageView.model

                    const toUpdate = []

                    function makeCopy(obj) {
                        return JSON.parse(JSON.stringify(obj))
                    }

                    let now = new Date().toISOString()

                    for(let i = 0; i < model.count; i++) {

                        const item = model.get(i)

                        if(!imageViewAndControls.filter(item) && item.selected) {

                            let annotation_update = makeCopy(criteria)
                            for (let field in criteria) {
                                annotation_update[field + '_modification_time'] = now
                                annotation_update[field + '_modified_by'] = currentUser
                            }

                            const current = makeCopy(item.metadata)
                            const update = Object.assign(makeCopy(item.metadata),
                                                         annotation_update)

                            const updateItem = {
                                current: current,
                                update: update
                            }

                            toUpdate.push(updateItem)
                        }

                        // remove selection
                        item.selected = false
                    }
                    if (toUpdate.length > 0) {
                        updateItems.call(toUpdate)
                    }
                }
            }
        }
    }

    property var dataAccess: DataAccess {}

    Request {
        id: login

        handler: dataAccess.login

        onSuccess: sas.call('processed')
        onError: console.log('Login failed. Details: ' + details)
    }

    Request {
        id: sas

        handler: dataAccess.sas

        onSuccess: {
            currentSas = res.token
            if (!viewPopulated) {
                pageLoader.resetPagesStatus()
                pageLoader.loadNextPage({})
            }
        }

        onError: {
            console.log('sas failed. Details: ' + details)
        }
    }

    Timer {
        interval: 1000 * 60 * 30 // 30 min
        running: true
        repeat: true

        onTriggered: {
            sas.call('processed')
        }
    }

    Request {
        id: filterItems

        handler: dataAccess.filterItems

        onSuccess: {
            const params = currentSas.length > 0 ? '?' + currentSas : ''

            function makeItem(item) {
                return {
                    image: res.urls[item._id] + params,
                    selected: false,
                    metadata: item
                }
            }

            let data = res.items.map(makeItem)

            viewPopulated = true
            imageViewAndControls.imageView.setData(data)
        }

        onError: {
            console.log('error in retrieving data items. Error: '+ details.text)
        }
    }

    Request {
        id: updateItems

        handler: dataAccess.updateItems

        onSuccess: {
            console.log("Update items")
            imageViewAndControls.imageView.clearData()
            pageLoader.loadPages(getCurrentFilter(), pageLoader.getNumberOfLoadedPages())
        }

        onError: {
            // TODO
            console.log("Updating annotations failed!")
            console.log(JSON.stringify(details, null, "  "))
        }
    }

    Request {
        id: exportItems
        handler: dataAccess.exportItems

        onSuccess: exportDialog.processExportResponse(true, res)
        onError: exportDialog.processExportResponse(false, details)
    }

    Component.onCompleted: {
        const serverAddress = getSettingVariable('host')
        console.log('using server:', serverAddress)
        dataAccess.server = new Req.Server(serverAddress)
        const username = getSettingVariable('username')
        const password = getSettingVariable('password')
        login.call(username, password)
    }
}

