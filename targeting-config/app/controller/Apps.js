Ext.define('Targeting.controller.Apps', {
    extend: 'Ext.app.Controller',
    stores: ['Apps'],
    
    refs: [{
        ref: 'appEdit',
        selector: 'appedit'
    },{
        ref: 'appList',
        selector: 'applist'
    }],

    views: [ 'app.List', 'app.Edit' ],

    init: function() {
        this.control({
            'applist': {
                render: this.onAppListRendered,
                selectionchange: this.onAppSelect
            },
            'appedit button[action=save]': {
                click: this.onAppUpdate
            }
        });
    },

    onAppListRendered: function() {
        //console.log('The App panel was rendered');
        this.getAppsStore().load({
            callback: this.onAppsLoad,
            scope: this
        });
    },

    onAppsLoad: function(apps, request) {
        //console.log('The App list was loaded');
        this.getAppList().getSelectionModel().select(0);
    },

    onAppSelect: function(selModel, selection) {
        //console.log('Selected ' + selection[0].get('name'));
        this.application.fireEvent('appselected', selection[0]);
        this.getAppEdit().loadRecord(selection[0]);
        // Enable elements after selection
        Ext.getCmp('app-button-del').setDisabled(false);
        Ext.getCmp('group-tab-panel').setDisabled(false);
        Ext.getCmp('ado-tab-panel').setDisabled(false);
    },

    onAppUpdate: function(button, aEvent, aOptions) {
        var form = button.up('form'),
        record = form.getRecord(),
        values = form.getValues();

        record.set(values);
        this.getAppsStore().sync();
        console.log('Saved: ' + record.get('appid'));
    }
});
