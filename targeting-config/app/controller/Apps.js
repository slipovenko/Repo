Ext.define('Targeting.controller.Apps', {
    extend: 'Ext.app.Controller',
    models: ['obj.App', 'conf.Status'],
    stores: ['obj.Apps', 'conf.Status'],
    views: [ 'app.List', 'app.Edit' ],
    
    refs: [{
        ref: 'appEdit',
        selector: 'appedit'
    },{
        ref: 'appList',
        selector: 'applist'
    }],

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
            },
            'appedit button[action=apply]': {
                click: this.onConfApply
            }
        });
        // Update tasks
        this.runner = new Ext.util.TaskRunner();
        this.task = null;
    },

    onAppListRendered: function() {
        this.getObjAppsStore().load({
            callback: this.onAppsLoad,
            scope: this
        });
    },

    onAppsLoad: function(apps, request) {
        this.getAppList().getSelectionModel().select(0);
    },

    onAppSelect: function(selModel, selection) {
        if(selection[0] != null)
        {
            var store = this.getObjAppsStore(),
                form = this.getAppEdit(),
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
                Ext.getCmp('app-button-del').setDisabled(false);
                Ext.getCmp('app-form-edit').setDisabled(false);
                var tflag = typeof selection[0].get('id') == 'undefined';
                Ext.getCmp('group-tab-panel').setDisabled(tflag);
                Ext.getCmp('ado-tab-panel').setDisabled(tflag);
                if(tflag){
                    form.show();
                    this.onAppConfStatusLoad(null);
                }
                else {
                    // Load configuration status
                    this.ConfStatusUpdate(selection[0].get('appid'));
                }
                this.application.fireEvent('appselected', selection[0]);
            }
            else
            {
                this.getAppList().getSelectionModel().select(store.indexOf(record));
                Ext.Msg.alert('Ошибка','Поля заполнены неверно!');
            }
        }
    },

    ConfStatusUpdate: function(appid) {
        this.getConfStatusStore().load({
            callback: this.onAppConfStatusLoad,
            params: {
                appid: appid
            },
            scope: this
        });
    },

    onAppConfStatusLoad: function(status, request) {
        var form = this.getAppEdit(),
            statusText = 'Состояние: ',
            utimeText = 'Обновлено: ',
            buttonDisabled = true;
        if(this.task != null) { this.task.destroy();}
        if(status != null && status.length>0) {
            switch (status[0].get('value')) {
                case 0: {statusText += 'Загружена'; break;}
                case 1: {statusText += 'В очереди'; break;}
                case 2: {statusText += 'Сохранена'; break;}
                case 3: {statusText += 'Загружается'; break;}
                default: {statusText += 'Неизвестно';}
            }
            utimeText += status[0].get('utime');
            buttonDisabled = status[0].get('value')>0;
            this.task = this.runner.newTask({
                run: function(){
                    this.ConfStatusUpdate(status[0].get('id'));
                },
                interval: 10000,
                scope: this
            });
            this.task.start();
        }
        else {
            statusText += '-';
            utimeText += '-';
        }
        Ext.getCmp('app-text-conf-status').setText(statusText);
        Ext.getCmp('app-text-conf-utime').setText(utimeText);
        Ext.getCmp('app-button-conf-apply').setDisabled(buttonDisabled);
    },

    onAppCreate: function(button, aEvent, aOptions) {
        var store = this.getObjAppsStore();
        if(store.getNewRecords().length == 0)
        {
            var newApp = Ext.create('Targeting.model.obj.App');
            newApp.set('name', 'Новое приложение');
            store.insert(0, newApp);
            this.getAppList().getSelectionModel().select(0);
            this.onAppConfStatusLoad(null);
        }
        else
        {
            var newApp = store.getNewRecords()[0];
            this.getAppList().getSelectionModel().select(store.indexOf(newApp));
        }
    },

    onAppDelete: function(button, aEvent, aOptions) {
        var form = this.getAppEdit(),
            store = this.getObjAppsStore(),
            record = this.getAppList().getSelectionModel().getSelection()[0],
            pos = store.indexOf(record);
        store.remove(record);
        if(store.count()>0)
        {
            this.getAppList().getSelectionModel().select(pos>=store.count()-1?store.count()-1:pos);
        }
        else
        {
            Ext.getCmp('app-button-del').setDisabled(true);
            Ext.getCmp('group-tab-panel').setDisabled(true);
            Ext.getCmp('ado-tab-panel').setDisabled(true);
            form.loadRecord(Ext.create('Targeting.model.App'));
            form.setDisabled(true);
            form.show();
        }
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
        var form = this.getAppEdit(),
        record = form.getRecord(),
        values = form.getValues();

        if(form.isValid())
        {
            record.set(values);
            this.getObjAppsStore().sync({
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
        else
        {
            Ext.Msg.alert('Ошибка','Поля заполнены неверно!');
        }
    },

    onConfApply: function(button, aEvent, aOptions) {
        var store = this.getConfStatusStore(),
            conf = store.getAt(0);
        conf.setDirty();
        store.getProxy().extraParams.appid = conf.get('id');
        store.sync({
            success: function (b, o) {
                this.onAppConfStatusLoad(store.getRange(0,0));
            },
            failure: function (b, o) {
                console.log('ERROR updating configuration status');
                this.onAppConfStatusLoad(null);
            },
            scope: this
        });
    }
});
