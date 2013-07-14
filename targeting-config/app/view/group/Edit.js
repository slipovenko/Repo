Ext.define('Targeting.view.group.Edit', {
    extend: 'Ext.form.Panel',
    alias: 'widget.groupedit',

    store: 'Groups',

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
                        xtype: 'textfield',
                        name : 'weight',
                        fieldLabel: 'Вес'
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
                margin: 5,
                items: [
                    {
                        xtype: 'groupattrtree',
                        width: 600,
                        height: 300,
                        margin: '0 5 0 0',
                        rootVisible: false
                    },{
                        xtype: 'groupadolist',
                        width: 600,
                        height: 300
                    }
                ]
            }
        ];

        this.callParent(arguments);
    }
});
