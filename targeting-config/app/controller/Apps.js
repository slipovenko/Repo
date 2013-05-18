Ext.define('Targeting.controller.Apps', {
    extend: 'Ext.app.Controller',
    
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
            }
        });
    },

    onAppSelect: function(selModel, selection) {
        console.log('Selected ' + selection[0].get('name'));
        this.application.fireEvent('appselected', selection[0]);
        var appEdit = this.getAppEdit();
        appEdit.loadRecord(selection[0]);
    }
});
