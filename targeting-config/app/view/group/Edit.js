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
            },
            {
                xtype: 'groupattrgeo',
                width: 600,
                height: 300,
                rootVisible: false
            }
        ];

        this.callParent(arguments);
    }
});
