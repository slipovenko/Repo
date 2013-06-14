Ext.define('Targeting.view.app.Edit', {
    extend: 'Ext.form.Panel',
    alias: 'widget.appedit',

    store: 'Apps',

    autoShow: true,
    trackResetOnLoad: true,
    bodyPadding: 5,

    tbar: [
        {
            id: 'app-button-upd',
            text: 'Сохранить',
            iconCls: 'button-upd',
            action: 'save'
        }
    ],

    initComponent: function() {
        this.items = [
            {
                xtype: 'numberfield',
                name : 'appid',
                fieldLabel: 'ИД приложения',
                hideTrigger:true,
                allowBlank: false,
                blankText: 'ID приложения не должно быть пустым',
                minValue: 1,
                minText: 'Минимальное значение 1',
                maxValue: 2147483647,
                maxText: 'Максимальное значение 2147483647'
            },
            {
                xtype: 'textfield',
                name : 'name',
                fieldLabel: 'Имя',
                allowBlank: false,
                blankText: 'Имя приложения не должно быть пустым'
            }
        ];

        this.callParent(arguments);
    }
});
