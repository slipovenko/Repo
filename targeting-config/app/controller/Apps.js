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
                selectionchange: this.onAppSelect
            },
            'appedit button[action=save]': {
                click: this.onAppUpdate
            }
        });
    },

    onAppSelect: function(selModel, selection) {
        console.log('Selected ' + selection[0].get('name'));
        this.application.fireEvent('appselected', selection[0]);
        var appEdit = this.getAppEdit();
        appEdit.loadRecord(selection[0]);
    },

    onAppUpdate: function(button, aEvent, aOptions) {
        var form  = button.up('form'),
        record = form.getRecord(),
        values = form.getValues();

        record.set(values);
        this.getAppsStore().sync();
        console.log('Saved: ' + record.get('appid'));
    }
});
