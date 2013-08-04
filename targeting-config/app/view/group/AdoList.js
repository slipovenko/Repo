Ext.define('Targeting.view.group.AdoList', {
    extend: 'Ext.grid.Panel',
    alias: 'widget.groupadolist',

    autoShow: true,

    id: 'group-form-adoedit',
    title: 'Объекты в группе',
    store: 'obj.GroupAdos',

    initComponent: function() {
        this.columns = [
            {header: 'Вкл.', dataIndex: 'enable',  flex: 0, xtype: 'checkcolumn', maxWidth: 35},
            {header: 'Имя', dataIndex: 'name',  flex: 1},
            {header: 'Тип', dataIndex: 'tid',  flex: 1, renderer: function(value) {
                return Ext.getStore('dict.Types').getById(value).get('name');
            }}
        ];

        this.callParent(arguments);
    }
});