Ext.define('Targeting.view.app.List' ,{
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
            handler: function(el) {
                return;
            }
        },
        {
            id: 'app-button-del',
            text: 'Удалить',
            iconCls: 'button-del',
            handler: function() {
                return;
            },
            disabled: true
        }
    ],

    initComponent: function() {
        this.columns = [
            {dataIndex: 'name',  flex: 1}
        ];

        this.callParent(arguments);
    }
});
