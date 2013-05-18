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

        // Listen for an application wide event
        this.application.on({
            appselected: this.onAppSelect,
            scope: this
        });
    },

    onAppSelect: function(app) {
        console.log('Load groups for app id ' + app.get('id'));
        var store = this.getGroupsStore();

        store.load({
            callback: this.onGroupsLoad,
            params: {
                appid: app.get('appid')
            },            
            scope: this
        });
        //var adoList = this.getAdoList();
        //appEdit.loadRecord(selection[0]);
    },

    onGroupsLoad: function(groups, request) {
        var store = this.getGroupsStore();

        // The data should already be filtered on the serverside but since we
        // are loading static data we need to do this after we loaded all the data
        store.clearFilter();
        //store.filter('appid', request.params.appid);
        store.sort('name', 'ASC');
        //this.getAdoList().update(ados);
    },
});