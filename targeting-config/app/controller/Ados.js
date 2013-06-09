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

        this.getAdoList().getSelectionModel().deselectAll();

        var store = this.getAdosStore();
        store.load({
            callback: this.onAdosLoad,
            params: {
                appid: app.get('appid')
            },            
            scope: this
        });
    },

    onAdosLoad: function(ados, request) {
        var store = this.getAdosStore();

        store.clearFilter();
        store.sort('name', 'ASC');
    }
});
