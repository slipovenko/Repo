Ext.define('Targeting.view.app.Edit', {
    extend: 'Ext.form.Panel',
    alias: 'widget.appedit',

    store: 'obj.Apps',

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
                xtype: 'fieldset',
                title: 'Базовые параметры',
                layout: 'anchor',
                collapsible: true,
                margin: 5,
                padding: 5,
                defaults: {
                labelAlign: 'right',
                    labelWidth: 100,
                    margin: '5 0 5 10'
                },
                items: [
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
                    }]
            },
            {
                xtype: 'fieldset',
                title: 'Конфигурация',
                layout: 'vbox',
                collapsible: false,
                margin: 5,
                padding: 5,
                defaults: {
                    labelAlign: 'right',
                    labelWidth: 100,
                    margin: '5 0 5 10'
                },
                items: [
                    {
                        id: 'app-text-conf-status',
                        xtype: 'text',
                        text: 'Статус: -'
                    },
                    {
                        id: 'app-text-conf-utime',
                        xtype: 'text',
                        text: 'Обновлено: -'
                    },
                    {
                        id: 'app-button-conf-apply',
                        xtype: 'button',
                        text: 'Применить',
                        iconCls: 'button-apply',
                        action: 'apply',
                        disabled: true
                    }]
            }
        ];

        this.callParent(arguments);
    }
});
