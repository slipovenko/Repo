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
        this.getAdoEdit().getForm().reset();
        Ext.getCmp('ado-button-upd').setDisabled(true);
        Ext.getCmp('ado-form-edit').setDisabled(true);

        this.getAdoList().getSelectionModel().deselectAll();

        var store = this.getAdosStore();
        store.removeAll();
        if(typeof app.get('id') != 'undefined')
        {
            store.load({
                callback: this.onAdosLoad,
                params: {
                    appid: app.get('appid')
                },
                scope: this
            });
        }
    },

    onAdoSelect: function(selModel, selection) {
        // Enable elements after selection
        if(selection[0] != null)
        {
            var store = this.getAdosStore(),
                form = this.getAdoEdit(),
                record = form.getRecord(),
                values = form.getValues(),
                pos = store.indexOf(record);
            if(form.isValid() || (!form.isValid() && pos<0))
            {
                console.log('Object selected: ' + selection[0].get('id'));
                // Update only if record is loaded, changes made and record exists in store
                if(typeof record != 'undefined' && form.isDirty() && pos>=0) { record.set(values); }
                // Load new record
                form.loadRecord(selection[0]);
                // Enable buttons after selection
                Ext.getCmp('ado-button-upd').setDisabled(false);
                Ext.getCmp('ado-form-edit').setDisabled(false);
                this.application.fireEvent('adoselected', selection[0]);
            }
            else
            {
                this.getAdoList().getSelectionModel().select(store.indexOf(record));
                Ext.Msg.alert('Ошибка','Поля заполнены неверно!');
            }
        }
    },

    onAdosLoad: function(ados, request) {
        var store = this.getAdosStore();
        store.clearFilter();
        store.sort('name', 'ASC');
    },

    onAdoUpdate: function(button, aEvent, aOptions) {
        var form = this.getAdoEdit(),
            record = form.getRecord(),
            values = form.getValues();

        console.log('Saved object: ' + record.get('name'));
        if(form.isValid())
        {
            record.set(values);
            this.getAdosStore().sync({
                success: function (b, o) {
                    console.log('Saved object: ' + record.get('name'));
                },
                failure: function (b, o) {
                    console.log('ERROR saving object: ' + record.get('name'));
                }
            });
        }
        else
        {
            Ext.Msg.alert('Ошибка','Поля заполнены неверно!');
        }
    }
});
