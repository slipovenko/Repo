    Ext.define('Targeting.controller.Ados', {
    extend: 'Ext.app.Controller',
    
    refs: [{
        ref: 'adoList',
        selector: 'adolist'
    },{
        ref: 'adoEdit',
        selector: 'adoedit'
    },{
        ref: 'appList',
        selector: 'applist'
    }],

    views: ['ado.List', 'ado.Edit'],
    stores: ['Apps','Ados'],

    init: function() {

        this.control({
            'adolist': {
                selectionchange: this.onAdoSelect
            }
        });

        // Listen for an application wide event
        this.application.on({
            appselected: this.onAppSelect,
            scope: this
        });
    },

    onAppSelect: function(app) {
        console.log('Load ados for app id ' + app.get('id'));

        this.getAdoEdit().getForm().reset();
        Ext.getCmp('ado-button-upd').setDisabled(true);

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

    onAdoSelect: function(selModel, selection) {
        // Enable elements after selection
        if(selection[0] != null)
        {
            console.log('Object selected: ' + selection[0].get('id'));
            this.application.fireEvent('adoselected', selection[0]);
            this.getAdoEdit().loadRecord(selection[0]);
            Ext.getCmp('ado-button-upd').setDisabled(false);
        }
    },

    onAdosLoad: function(ados, request) {
        var store = this.getAdosStore();
        store.clearFilter();
        store.sort('name', 'ASC');
    }
});
