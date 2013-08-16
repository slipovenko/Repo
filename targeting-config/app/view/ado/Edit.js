Ext.define('Targeting.view.ado.Edit', {
    extend: 'Ext.form.Panel',
    alias: 'widget.adoedit',

    store: 'obj.Ados',

    autoShow: true,

    tbar: [
        {
            id: 'ado-button-upd',
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
                    xtype: 'textfield',
                    labelAlign: 'right',
                    labelWidth: 75,
                    width: 500,
                    margin: '5 0 5 10'
                },
                items: [
                    {
                        name : 'uuid',
                        fieldLabel: 'UUID',
                        readOnly: true
                    },
                    {
                        name : 'name',
                        fieldLabel: 'Имя',
                        allowBlank: false,
                        blankText: 'Имя объекта не должно быть пустым'
                    },
                    {
                        xtype: 'combo',
                        store: Ext.getStore('dict.Types'),
                        valueField: 'id',
                        displayField: 'name',
                        editable: false,
                        forceSelection: true,
                        name : 'tid',
                        value: 'tid',
                        fieldLabel: 'Тип'
                    },
                    {
                        name : 'flink',
                        fieldLabel: 'Файл',
                        allowBlank: false,
                        blankText: 'Ссылка на файл не должна быть пустой',
                        vtype: 'url',
                        vtypeText: 'Неверный формат ссылки'
                    },
                    {
                        name : 'ilink',
                        fieldLabel: 'Изображение',
                        allowBlank: false,
                        blankText: 'Ссылка на изображение не должна быть пустой',
                        vtype: 'url',
                        vtypeText: 'Неверный формат ссылки'
                    },
                    {
                        name : 'attr',
                        fieldLabel: 'Таргетинг',
                        hidden: true
                    }
                ]
            }
        ];

        this.callParent(arguments);
    }
});
