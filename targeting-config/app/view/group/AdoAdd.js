Ext.define('Targeting.view.group.AdoAdd', {
    extend: 'Ext.window.Window',
    alias: 'widget.groupadoadd',

    title: 'Hello',
    height: 200,
    width: 400,
    layout: 'fit',
    modal: true,
    items: {
        xtype: 'grid',
        store: 'obj.Ados',
        border: false,
        selModel: { mode: 'MULTI'},
        scroll: 'vertical',
        columns: [
            {header: 'Имя', dataIndex: 'name',  flex: 1},
            {header: 'Тип', dataIndex: 'tid',  flex: 1, renderer: function(value) {
                return Ext.getStore('dict.Types').getById(value).get('name');
            }}
        ]
    },
    buttons: [
        {
            text: 'Выбрать',
            action: 'ok'
        },
        {
            text: 'Отменить',
            action: 'cancel'
        }
    ]
});