    Ext.define('Targeting.controller.Groups', {
    extend: 'Ext.app.Controller',
    
    refs: [{
        ref: 'groupList',
        selector: 'grouplist'
    },{
        ref: 'appList',
        selector: 'applist'
    }],

    views: ['group.List'],
    stores: ['Apps','Groups'],

    init: function() {

        this.control({
            'grouplist': {
                selectionchange: this.onGroupSelect
            }
        });

        // Listen for an application wide event
        this.application.on({
            appselected: this.onAppSelect,
            scope: this
        });
    },

    onAppSelect: function(app) {
        console.log('Load groups for app id ' + app.get('id'));

        this.getGroupList().getSelectionModel().deselectAll();
        Ext.getCmp('group-button-del').setDisabled(true);

        var store = this.getGroupsStore();
        store.load({
            callback: this.onGroupsLoad,
            params: {
                appid: app.get('appid')
            },            
            scope: this
        });
    },

    onGroupSelect: function(selModel, selection) {
        // Enable elements after selection
        Ext.getCmp('group-button-del').setDisabled(false);
    },

    onGroupsLoad: function(groups, request) {
        var store = this.getGroupsStore();

        store.clearFilter();
        store.sort('name', 'ASC');
    }
});