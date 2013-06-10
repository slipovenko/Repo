Ext.define('Targeting.view.group.List', {
    extend: 'Ext.grid.Panel',
    alias: 'widget.grouplist',

    store: 'Groups',

    tbar: [
        {
            id: 'group-button-add',
            text: 'Добавить',
            iconCls: 'button-add',
            handler: function(el) {
                return;
            }
        },
        {
            id: 'group-button-del',
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
            {header: 'Имя', dataIndex: 'name',  flex: 1},
            {header: 'Приоритет', dataIndex: 'priorityid',  flex: 1, renderer: function(value) {
                return Ext.getStore('dict.Priorities').getById(value).get('name');
            }},
            {header: 'Состояние', dataIndex: 'enable',  flex: 1, renderer: function(value) {
                return value?'Активна':'Неактивна';
            }},
            {header: 'Вес', dataIndex: 'weight',  flex: 1},
        ];

        this.callParent(arguments);
    }

});
