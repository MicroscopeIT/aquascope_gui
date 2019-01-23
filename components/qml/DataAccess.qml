import QtQuick 2.9

QtObject {

    property var server: null

    property QtObject internal: QtObject {

        readonly property int tokenRefreshInterval: 1000 * 60 * 10 // 10 min

        property string access_token
        property string refresh_token

        property var access_token_header
        property var refresh_token_header

        onAccess_tokenChanged: {
            access_token_header = ['Authorization', 'Bearer ' + access_token]
        }

        onRefresh_tokenChanged: {
             refresh_token_header = ['Authorization', 'Bearer ' + refresh_token]
        }

        property Timer refreshTimer: Timer {
            interval: internal.tokenRefreshInterval
            running: true
            repeat: true

            onTriggered: {
                if(internal.refresh_token) {
                    internal.refresh(internal.refresh_token)
                }
            }
        }

        function refresh(refresh_token) {
            var req = {
                handler: '/user/refresh',
                method: 'POST',
                headers: [internal.refresh_token_header]
            }
            return server.send(req, function(res) {
                if(res.body !== null) {
                    internal.access_token = res.body.access_token
                }
            })
        }
    }

    function login(username, password, cb) {

        var req = {
            handler: '/user/login',
            method: 'POST',
            params: { username: username, password: password }
        }

        return server.send(req, function(res) {
            if(res.status === 200 && res.body !== null) {
                internal.access_token = res.body.access_token
                internal.refresh_token = res.body.refresh_token
            }
            cb(res)
        })
    }

    function openUpload(projectId, cb) {
        var req = {
            handler: '/upload/create',
            method: 'POST',
            headers: [internal.access_token_header]
        }

        return server.send(req, function(res) {
            if(res.status >= 200 && res.status <= 202) {
                var body = {
                    '_id': res.body.id,
                    'blobParams': {
                        'host': 'https://' + res.body.account
                                + '.blob.core.windows.net',
                        'container': res.body.container,
                        'sas': res.body.sas_token
                    }
                }

                res.body = body
            }

            cb(res)
        })
    }

    // TODO: successful is not handled. Server is notified even if upload failed
    // When done uncomment `closeReq.call(currentId, false)` in UploadDialog.qml
    function closeUpload(uploadId, successful, cb) {
        var req = {
            handler: '/upload/' + uploadId + '/finish',
            method: 'POST',
            headers: [internal.access_token_header]
        }
        return server.send(req, cb)
    }

    function listFiles(cb) {
        var req = {
            handler: '/file/list',
            method: 'GET',
            headers: [internal.access_token_header]
        }
        return server.send(req, cb)
    }

    function download(fileId, cb) {
        var req = {
            handler: '/file/' + fileId + '/download',
            method: 'GET',
            headers: [internal.access_token_header]
        }
        return server.send(req, cb)
    }
}
