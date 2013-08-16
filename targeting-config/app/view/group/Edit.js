Ext.define('Targeting.view.group.Edit', {
    extend: 'Ext.form.Panel',
    alias: 'widget.groupedit',

    store: 'obj.Groups',

    autoShow: true,
    autoScroll: true,

    tbar: [
        {
            id: 'group-button-upd',
            text: 'Сохранить',
            iconCls: 'button-upd',
            action: 'save',
            disabled: true
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
                    labelWidth: 75,
                    margin: '5 0 5 10'
                },
                items: [
                    {
                        xtype: 'textfield',
                        name : 'name',
                        fieldLabel: 'Имя',
                        allowBlank: false,
                        blankText: 'Имя группы не должно быть пустым'
                    },
                    {
                        xtype: 'combo',
                        store: Ext.getStore('dict.Priorities'),
                        valueField: 'id',
                        displayField: 'name',
                        editable: false,
                        forceSelection: true,
                        name : 'priorityid',
                        value: 'priorityid',
                        fieldLabel: 'Приоритет'
                    },
                    {
                        xtype: 'numberfield',
                        name : 'weight',
                        fieldLabel: 'Вес',
                        allowBlank: false,
                        blankText: 'Значением статистического веса должно быть число большее или равное нулю',
                        minValue: 0,
                        minText: 'Минимальное значение 0',
                        maxValue: 2147483647,
                        maxText: 'Максимальное значение 2147483647'
                    },
                    {
                        xtype: 'checkbox',
                        uncheckedValue: '0',
                        inputValue: '1',
                        name : 'enable',
                        value : 'enable',
                        fieldLabel: 'Активна'
                    }]
            },
            {
                xtype: 'fieldcontainer',
                layout: 'hbox',
                width: '100%',
                margin: 5,
                items: [
                    {
                        id: 'group-form-attredit',
                        xtype: 'groupattrtree',
                        width: '45%',
                        height: 'auto',
                        margin: '0 5 0 0',
                        rootVisible: false
                    },{
                        id: 'group-form-adoedit',
                        xtype: 'groupadolist',
                        width: '45%',
                        height: 'auto'
                    }
                ]
            }
        ];

        this.callParent(arguments);
    }
});
