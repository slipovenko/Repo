    Ext.define('Targeting.controller.Groups', {
    extend: 'Ext.app.Controller',
    
    refs: [{
        ref: 'groupList',
        selector: 'grouplist'
    },{
            ref: 'groupEdit',
            selector: 'groupedit'
    },{
        ref: 'appList',
        selector: 'applist'
    }],

    views: ['group.List', 'group.Edit'],
    stores: ['Apps','Groups'],

    init: function() {

        this.control({
            'grouplist': {
                selectionchange: this.onGroupSelect
            },
            'groupedit button[action=save]': {
                click: this.onGroupUpdate
            }
        });

        // Listen for an application wide event
        this.application.on({
            appselected: this.onAppSelect,
            scope: this
        });
    },

    onAppSelect: function(app) {
        this.getGroupEdit().getForm().reset();
        Ext.getCmp('group-button-upd').setDisabled(true);
        Ext.getCmp('group-form-edit').setDisabled(true);

        this.getGroupList().getSelectionModel().deselectAll();
        Ext.getCmp('group-button-del').setDisabled(true);

        var store = this.getGroupsStore();
        store.removeAll();
        if(typeof app.get('id') != 'undefined')
        {
            store.load({
                callback: this.onGroupsLoad,
                params: {
                    appid: app.get('appid')
                },
                scope: this
            });
        }
    },

    onGroupSelect: function(selModel, selection) {
        // Enable elements after selection
        if(selection[0] != null)
        {
            console.log('Group selected: ' + selection[0].get('id'));
            Ext.getCmp('group-button-del').setDisabled(false);
            this.application.fireEvent('groupselected', selection[0]);
            this.getGroupEdit().loadRecord(selection[0]);
            Ext.getCmp('group-button-upd').setDisabled(false);
            Ext.getCmp('group-form-edit').setDisabled(false);
        }
    },

    onGroupsLoad: function(groups, request) {
        var store = this.getGroupsStore();
        store.clearFilter();
        store.sort('name', 'ASC');
    },

    onGroupUpdate: function(button, aEvent, aOptions) {
        var form = button.up('form'),
            record = form.getRecord(),
            values = form.getValues();

        record.set(values);
        this.getGroupsStore().sync();
        console.log('Saved object: ' + record.get('name'));
    }
});