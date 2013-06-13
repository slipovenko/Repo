Ext.define('Targeting.controller.Apps', {
    extend: 'Ext.app.Controller',
    models: ['App'],
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
            'applist button[action=new]': {
                click: this.onAppCreate
            },
            'applist button[action=delete]': {
                click: this.onAppDelete
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
        if(selection[0] != null)
        {
            this.getAppEdit().loadRecord(selection[0]);
            // Enable buttons after selection
            Ext.getCmp('app-button-del').setDisabled(false);
            Ext.getCmp('app-form-edit').setDisabled(false);
            var tflag = typeof selection[0].get('id') == 'undefined';
            Ext.getCmp('group-tab-panel').setDisabled(tflag);
            Ext.getCmp('ado-tab-panel').setDisabled(tflag);
            if(tflag){Ext.getCmp('app-form-edit').show();}
            this.application.fireEvent('appselected', selection[0]);
        }
    },

    onAppCreate: function(button, aEvent, aOptions) {
        var store = this.getAppsStore();
        if(store.getNewRecords().length == 0)
        {
            var newApp = Ext.create('Targeting.model.App');
            newApp.set('name', 'Новое приложение');
            store.insert(0, newApp);
            this.getAppList().getSelectionModel().select(0);
        }
        else
        {
            var newApp = store.getNewRecords()[0];
            this.getAppList().getSelectionModel().select(store.indexOf(newApp));
        }
    },

    onAppDelete: function(button, aEvent, aOptions) {
        var store = this.getAppsStore();
        var record = this.getAppList().getSelectionModel().getSelection()[0];
        var pos = store.indexOf(record);
        store.remove(record);
        this.getAppList().getSelectionModel().select(pos>=store.count()-1?store.count()-1:pos);
        store.sync({
            success: function (b, o) {
                console.log('Deleted app: ' + record.get('name'));
            },
            failure: function (b, o) {
                console.log('ERROR deleting app: ' + record.get('name'));
                store.insert(pos, record);
            }
        });
    },

    onAppUpdate: function(button, aEvent, aOptions) {
        var form = button.up('form'),
        record = form.getRecord(),
        values = form.getValues();

        record.set(values);
        this.getAppsStore().sync({
            success: function (b, o) {
                console.log('Saved app: ' + record.get('name'));
                Ext.getCmp('group-tab-panel').setDisabled(false);
                Ext.getCmp('ado-tab-panel').setDisabled(false);
            },
            failure: function (b, o) {
                console.log('ERROR saving app: ' + record.get('name'));
            }
        });
    }
});
