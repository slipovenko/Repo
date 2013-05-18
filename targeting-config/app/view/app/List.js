Ext.define('Targeting.view.app.List' ,{
    extend: 'Ext.grid.Panel',
    alias: 'widget.applist',

    store: 'Apps',

    initComponent: function() {
        this.columns = [
            {dataIndex: 'name',  flex: 1}
        ];

        this.callParent(arguments);
    }
});
