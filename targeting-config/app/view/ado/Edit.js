Ext.define('Targeting.view.ado.Edit', {
    extend: 'Ext.form.Panel',
    alias: 'widget.adoedit',

    store: 'Ados',

    autoShow: true,

    tbar: [
        {
            id: 'ado-button-upd',
            text: 'Сохранить',
            iconCls: 'button-upd',
            action: 'save',
            handler: function() {
                return;
            },
            disabled: true
        }
    ],

    initComponent: function() {
        this.items = [
            {
                xtype: 'textfield',
                name : 'name',
                fieldLabel: 'Имя'
            },
            {
                xtype: 'textfield',
                name : 'uuid',
                fieldLabel: 'UUID'
            }
        ];

        this.callParent(arguments);
    }
});
