Ext.define('Targeting.view.app.Edit', {
    extend: 'Ext.form.Panel',
    alias: 'widget.appedit',

    store: 'Apps',

    autoShow: true,

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

        this.buttons = [
            {
                text: 'Сохранить',
                action: 'save'
            }
        ];

        this.callParent(arguments);
    }
});
