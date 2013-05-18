    Ext.define('Targeting.controller.Ados', {
    extend: 'Ext.app.Controller',
    
    refs: [{
        ref: 'adoList',
        selector: 'adolist'
    },{
        ref: 'appList',
        selector: 'applist'
    }],

    views: ['ado.List'],
    stores: ['Apps','Ados'],

    init: function() {

        // Listen for an application wide event
        this.application.on({
            appselected: this.onAppSelect,
            scope: this
        });
    },

    onAppSelect: function(app) {
        console.log('Load ados for app id ' + app.get('id'));
        var store = this.getAdosStore();

        store.load({
            callback: this.onAdosLoad,
            params: {
                appid: app.get('appid')
            },            
            scope: this
        });
        //var adoList = this.getAdoList();
        //appEdit.loadRecord(selection[0]);
    },

    onAdosLoad: function(ados, request) {
        var store = this.getAdosStore();

        // The data should already be filtered on the serverside but since we
        // are loading static data we need to do this after we loaded all the data
        store.clearFilter();
        //store.filter('appid', request.params.appid);
        store.sort('name', 'ASC');
        //this.getAdoList().update(ados);
    },
});
