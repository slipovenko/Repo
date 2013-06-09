Ext.define('Targeting.view.group.Edit', {
    extend: 'Ext.form.Panel',
    alias: 'widget.groupedit',

    store: 'Groups',

    autoShow: true,

    tbar: [
        {
            id: 'group-button-upd',
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
                name : 'weight',
                fieldLabel: 'Вес'
            }
        ];

        this.callParent(arguments);
    }
});
