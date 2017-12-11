import QtQuick 2.8
//import "../code/utils.js" as Utils

QtObject {

    property var callback
    property bool debug: false
    property string currentHost
    readonly property string hostUrl: "http://%1/MCWS/v1/".arg(currentHost)

    signal dataReady(var data, var index)
    signal connectionError(var msg, var cmd)
    signal commandError(var msg, var cmd)

    function getResponse(cmd, callback)
    {
        var xhr = new XMLHttpRequest

        xhr.onreadystatechange = function()
        {
            if (xhr.readyState === XMLHttpRequest.DONE) {

                // check for null return, connect failure
                var resp = xhr.responseXML
                if (resp === null) {
                    connectionError("Unable to connect", cmd)
                    return
                }

                var doc = resp.documentElement;

                // print resp status with cmd
                if (xhr.statusText !== "OK") {
                    commandError(doc.attributes[1].value, cmd)
                    return
                }

                //
                if (typeof callback === "function")
                    callback(doc)
            }
        }

        xhr.open("GET", cmd);
        xhr.send();
    }

    // Caller can determine how the data obj is returned.
    // Set the reader.callback to use the callback with the data object.
    // Otherwise, data obj will be emitted with dataReady and optionally model index passed in (loadObjDirect).
    function runQuery(cmdstr, obj, ndx)
    {
        var cmd = hostUrl + cmdstr
        var loadObjDirect = (obj !== undefined && (ndx !== undefined & ndx >= 0))
        var values = {}
        if (debug)
            console.log("Load object direct: " + loadObjDirect + ", " + cmd + ', for index: ' + ndx)

        getResponse(cmd, function(xml)
        {
            for (var i = 0, len = xml.childNodes.length; i < len; ++i)
            {
                var node = xml.childNodes[i]
                if (node.nodeName === "Item")
                {
                    values[node.attributes[0].value.toLowerCase()] = node.childNodes[0].data
                    if (loadObjDirect)
                    {
                        obj.setProperty(ndx, node.attributes[0].value.toLowerCase(), node.childNodes[0].data)
                    }
                }
            }
            // if callback is set, then call it with the data object
            // otherwise emit the object
            if (typeof callback === "function")
                callback(values)
            else
                dataReady(values, (loadObjDirect ? ndx : -1))

        })

    }

    function exec(cmdstr)
    {
        var cmd = hostUrl + cmdstr
        if (debug)
            console.log(cmd)
        getResponse(cmd)
    }

}
