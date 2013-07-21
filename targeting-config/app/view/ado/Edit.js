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
            disabled: true
        }
    ],

    initComponent: function() {
        this.items = [
            {
                xtype: 'fieldcontainer',
                layout: 'anchor',
                margin: 5,
                items: [
                    {
                        xtype: 'textfield',
                        name : 'name',
                        fieldLabel: 'Имя'
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
                        xtype: 'textfield',
                        name : 'uuid',
                        fieldLabel: 'UUID',
                        readOnly: true
                    },
                    {
                        xtype: 'textfield',
                        name : 'flink',
                        fieldLabel: 'Файл',
                        readOnly: true
                    },
                    {
                        xtype: 'textfield',
                        name : 'ilink',
                        fieldLabel: 'Ссылка',
                        readOnly: true
                    },
                    {
                        xtype: 'textfield',
                        name : 'attr',
                        fieldLabel: 'Таргетинг',
                        readOnly: true
                    }
                ]
            }
        ];

        this.callParent(arguments);
    }
});
