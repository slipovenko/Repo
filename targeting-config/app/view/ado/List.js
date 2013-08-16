Ext.define('Targeting.view.ado.List', {
    extend: 'Ext.grid.Panel',
    alias: 'widget.adolist',

    store: 'obj.Ados',

    tbar: [
        {
            id: 'ado-button-add',
            text: 'Добавить',
            iconCls: 'button-add',
            action: 'new'
        },
        {
            id: 'ado-button-del',
            text: 'Удалить',
            iconCls: 'button-del',
            action: 'delete',
            disabled: true
        }
    ],

    initComponent: function() {
        this.columns = [
            {header: 'UUID', dataIndex: 'uuid',  flex: 1},
            {header: 'Имя', dataIndex: 'name',  flex: 1},
            {header: 'Тип', dataIndex: 'tid',  flex: 1, renderer: function(value) {
                return Ext.getStore('dict.Types').getById(value).get('name');
            }},
            {header: 'Файл', dataIndex: 'flink',  flex: 1, renderer: function(value) {
                return '<a target="_blank" href="' + value + '">' + value + '</a>';
            }},
            {header: 'Изображение', dataIndex: 'ilink',  flex: 1, renderer: function(value) {
                return '<a target="_blank" href="' + value + '">' + value + '</a>';
            }},
        ];

        this.callParent(arguments);
    }
});
