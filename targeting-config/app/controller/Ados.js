    Ext.define('Targeting.controller.Ados', {
    extend: 'Ext.app.Controller',
    models: ['obj.App','obj.Ado'],
    stores: ['obj.Apps','obj.Ados'],
    views: ['ado.List', 'ado.Edit'],

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

    init: function() {

        this.control({
            'adolist': {
                selectionchange: this.onAdoSelect
            },
            'adolist button[action=new]': {
                click: this.onAdoCreate
            },
            'adolist button[action=delete]': {
                click: this.onAdoDelete
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
        Ext.getCmp('ado-button-del').setDisabled(true);
        Ext.getCmp('ado-button-upd').setDisabled(true);
        Ext.getCmp('ado-form-edit').setDisabled(true);

        this.getAdoList().getSelectionModel().deselectAll();

        var store = this.getObjAdosStore();
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
            var store = this.getObjAdosStore(),
                form = this.getAdoEdit(),
                record = form.getRecord(),
                values = form.getValues(),
                pos = store.indexOf(record);
            if(form.isValid() || (!form.isValid() && pos<0))
            {
                // Update only if record is loaded, changes made and record exists in store
                if(typeof record != 'undefined' && form.isDirty() && pos>=0) { record.set(values); }
                // Load new record
                form.loadRecord(selection[0]);
                // Enable buttons after selection
                Ext.getCmp('ado-button-del').setDisabled(false);
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
        var store = this.getObjAdosStore();
        store.clearFilter();
        store.sort('name', 'ASC');
    },

    onAdoCreate: function(button, aEvent, aOptions) {
        var store = this.getObjAdosStore();
        if(store.getNewRecords().length == 0)
        {
            store.insert(0, Ext.create('Targeting.model.obj.Ado', {
                appid: this.getAppList().getSelectionModel().getSelection()[0].get('appid'),
                name: 'Новый объект',
                uuid: 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                    var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
                    return v.toString(16);
                }),
                flink: '',
                ilink: '',
                tid: 0,
                attr: ''
            }));
            this.getAdoList().getSelectionModel().select(0);
        }
        else
        {
            var newAdo = store.getNewRecords()[0];
            this.getAdoList().getSelectionModel().select(store.indexOf(newAdo));
        }
    },

    onAdoDelete: function(button, aEvent, aOptions) {
        var form = this.getAdoEdit(),
            store = this.getObjAdosStore(),
            record = this.getAdoList().getSelectionModel().getSelection()[0],
            pos = store.indexOf(record);
        store.remove(record);
        if(store.count()>0)
        {
            this.getAdoList().getSelectionModel().select(pos>=store.count()-1?store.count()-1:pos);
        }
        else
        {
            Ext.getCmp('ado-button-del').setDisabled(true);
            Ext.getCmp('ado-button-upd').setDisabled(true);
            form.loadRecord(Ext.create('Targeting.model.obj.Ado'));
            form.setDisabled(true);
        }
        store.sync({
            success: function (b, o) {
                console.log('Deleted object: ' + record.get('name'));
            },
            failure: function (b, o) {
                console.log('ERROR deleting object: ' + record.get('name'));
                store.insert(pos, record);
                this.getAdoList().getSelectionModel().select(pos);
            },
            scope: this
        });
    },

    onAdoUpdate: function(button, aEvent, aOptions) {
        var form = this.getAdoEdit(),
            record = form.getRecord(),
            values = form.getValues();

        if(form.isValid())
        {
            record.set(values);
            this.getObjAdosStore().sync({
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
