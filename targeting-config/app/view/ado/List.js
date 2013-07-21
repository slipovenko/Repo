Ext.define('Targeting.view.ado.List', {
    extend: 'Ext.grid.Panel',
    alias: 'widget.adolist',

    store: 'Ados',

    initComponent: function() {
        this.columns = [
            {header: 'Имя', dataIndex: 'name',  flex: 1},
            {header: 'Тип', dataIndex: 'tid',  flex: 1, renderer: function(value) {
                return Ext.getStore('dict.Types').getById(value).get('name');
            }},
            {header: 'UUID', dataIndex: 'uuid',  flex: 1},
            {header: 'Файл', dataIndex: 'flink',  flex: 1, renderer: function(value) {
                return '<a target="_blank" href="' + value + '">' + value + '</a>';
            }},
            {header: 'Ссылка', dataIndex: 'ilink',  flex: 1, renderer: function(value) {
                return '<a target="_blank" href="' + value + '">' + value + '</a>';
            }},
        ];

        this.callParent(arguments);
    }
});
