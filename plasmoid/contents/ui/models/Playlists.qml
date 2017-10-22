import QtQuick 2.8
import QtQuick.XmlListModel 2.0
import org.kde.plasma.core 2.1 as PlasmaCore

Item {

    property alias hostUrl: xlm.hostUrl
    readonly property alias model: sf
    property string filterType: ""

    function load() {
        xlm.load("Playlists/List")
    }

    function clear() {
        sf.sourceModel = null
        xlm.source = ""
        sf.sourceModel = xlm
    }

    /* HACK: Use of the SortFilterModel::filterCallback.  It doesn't really
      support xmllistmodel filterRole/String, so instead of invalidate(),
      reset the sourceModel to force a reload, using callback to filter.
    */
    onFilterTypeChanged: {
        sf.sourceModel = null
        xlm.reload()
        sf.sourceModel = xlm
    }

    PlasmaCore.SortFilterModel {
        id: sf
        sourceModel: xlm
        filterCallback: function(i,str)
        {
            return (filterType === "" || filterType.toLowerCase() === "all")
                    ? true
                    : filterType.toLowerCase().indexOf(xlm.get(i).type.toLowerCase()) !== -1
        }
    }

    BaseXml {
        id: xlm

        XmlRole { name: "id";   query: "Field[1]/string()" }
        XmlRole { name: "name"; query: "Field[2]/string()" }
        XmlRole { name: "path"; query: "Field[3]/string()" }
        XmlRole { name: "type"; query: "Field[4]/string()" }

    }
}
