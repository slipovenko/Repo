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
            },
            'adoedit button[action=save]': {
                click: this.onAdoUpdate
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
        Ext.getCmp('ado-form-edit').setDisabled(true);

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
            Ext.getCmp('ado-form-edit').setDisabled(false);
        }
    },

    onAdosLoad: function(ados, request) {
        var store = this.getAdosStore();
        store.clearFilter();
        store.sort('name', 'ASC');
    },

    onAdoUpdate: function(button, aEvent, aOptions) {
        var form = button.up('form'),
            record = form.getRecord(),
            values = form.getValues();

        record.set(values);
        this.getAdosStore().sync();
        console.log('Saved object: ' + record.get('name'));
    }
});
