Ext.define('Targeting.view.app.Edit', {
    extend: 'Ext.form.Panel',
    alias: 'widget.appedit',

    store: 'Apps',

    autoShow: true,

    tbar: [
        {
            id: 'app-button-upd',
            text: 'Сохранить',
            iconCls: 'button-upd',
            action: 'save',
            handler: function() {
                return;
            }
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
                name : 'appid',
                fieldLabel: 'ИД приложения'
            }
        ];

        this.callParent(arguments);
    }
});
