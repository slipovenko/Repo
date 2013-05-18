Ext.define('Targeting.view.group.List' ,{
    extend: 'Ext.grid.Panel',
    alias: 'widget.grouplist',

    store: 'Groups',

    initComponent: function() {
        this.columns = [
            {header: 'Имя', dataIndex: 'name',  flex: 1},
            {header: 'Вес', dataIndex: 'weight',  flex: 1},
            {header: 'Приоритет', dataIndex: 'priorityid',  flex: 1}
        ];

        this.callParent(arguments);
    }

});
