Ext.define('Targeting.view.app.List', {
    extend: 'Ext.grid.Panel',
    alias: 'widget.applist',

    store: 'Apps',

    id: 'app-list-grid',
    title: 'Список приложений',
    tbar: [
        {

            id: 'app-button-add',
            text: 'Добавить',
            iconCls: 'button-add',
            action: 'new'
        },
        {
            id: 'app-button-del',
            text: 'Удалить',
            iconCls: 'button-del',
            action: 'delete',
            disabled: true
        }
    ],

    initComponent: function() {
        this.columns = [
            {header: 'ID', dataIndex: 'appid',  flex: 1, maxWidth: 75},
            {header: 'Имя', dataIndex: 'name',  flex: 1}
        ];

        this.callParent(arguments);
    }
});
