Ext.define('Targeting.view.ado.List', {
    extend: 'Ext.grid.Panel',
    alias: 'widget.adolist',

    store: 'Ados',

    initComponent: function() {
        this.columns = [
            {header: 'Имя', dataIndex: 'name',  flex: 1},
            {header: 'UUID', dataIndex: 'uuid',  flex: 1}
        ];

        this.callParent(arguments);
    }
});
