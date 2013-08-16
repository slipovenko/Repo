    Ext.define('Targeting.controller.Groups', {
    extend: 'Ext.app.Controller',
    models: ['obj.App', 'obj.Group', 'obj.GroupAdo', 'obj.GroupAttr', 'dict.Attribute', 'dict.Priority', 'dict.Type'],
    stores: ['obj.Apps', 'obj.Groups', 'obj.GroupAdos', 'obj.GroupAttrs', 'dict.Attributes', 'dict.Priorities', 'dict.Types'],
    views: ['group.List', 'group.Edit', 'group.AdoList', 'group.AdoAdd', 'group.AttrTree'],

    refs: [{
        ref: 'groupList',
        selector: 'grouplist'
    },{
            ref: 'groupEdit',
            selector: 'groupedit'
    },{
        ref: 'appList',
        selector: 'applist'
    },{
        ref: 'groupAdoList',
        selector: 'groupadolist'
    },{
        ref: 'groupAdoAdd',
        selector: 'groupadoadd'
    },{
        ref: 'groupAttrTree',
        selector: 'groupattrtree'
    }],

    init: function() {

        this.control({
            'grouplist': {
                selectionchange: this.onGroupSelect
            },
            'grouplist button[action=new]': {
                click: this.onGroupCreate
            },
            'grouplist button[action=delete]': {
                click: this.onGroupDelete
            },
            'groupedit button[action=save]': {
                click: this.onGroupUpdate
            },
            'groupattrtree': {
                checkchange: this.onGroupAttrTreeCheckChange,
                load: this.onGroupAttrLoad
            },
            'groupadolist button[action=add]': {
                click: this.onGroupAdoAdd
            },
            'groupadolist actioncolumn': {
                click: this.onGroupAdoDelete
            },
            'groupadoadd': {
                beforeclose: this.onGroupAdoAddClose
            },
            'groupadoadd button[action=ok]': {
                click: this.onGroupAdoAddOK
            },
            'groupadoadd button[action=cancel]': {
                click: this.onGroupAdoAddCancel
            }
        });

        // Listen for an application wide event
        this.application.on({
            appselected: this.onAppSelect,
            scope: this
        });
    },

    onAppSelect: function(app) {
        this.getGroupEdit().getForm().reset();
        Ext.getCmp('group-button-upd').setDisabled(true);
        Ext.getCmp('group-form-edit').setDisabled(true);

        this.getGroupList().getSelectionModel().deselectAll();
        Ext.getCmp('group-button-del').setDisabled(true);

        // Clear extended group's parameters
        this.getObjGroupAdosStore().removeAll();
        var tree = this.getDictAttributesStore();
        tree.getRootNode().cascadeBy(function(n){n.set('checked', (n.get('checked')!= null)?false:null);} );

        // Clear group store & reload
        var store = this.getObjGroupsStore();
        store.removeAll();
        if(typeof app.get('id') != 'undefined')
        {
            store.load({
                callback: this.onGroupsLoad,
                params: {
                    appid: app.get('appid')
                },
                scope: this
            });
        }
    },

    onGroupSelect: function(selModel, selection) {
        // Enable elements after selection
        if(selection[0] != null)
        {
            var store = this.getObjGroupsStore(),
                tree = this.getDictAttributesStore(),
                form = this.getGroupEdit(),
                record = form.getRecord(),
                values = form.getValues(),
                pos = store.indexOf(record);
            if(form.isValid() || (!form.isValid() && pos<0))
            {
                // Update only if record is loaded, changes made and record exists in store
                if(typeof record != 'undefined' && form.isDirty() && pos>=0) { record.set(values); }
                this.getGroupEdit().setDisabled(true);
                // Load new record
                form.loadRecord(selection[0]);
                // Attr Tree reset and reload
                tree.getRootNode().cascadeBy(function(n){n.set('checked', (n.get('checked')!= null)?false:null);} );
                var attr = this.getObjGroupAttrsStore(),
                    ado = this.getObjGroupAdosStore(),
                    gid = (typeof selection[0].get('id') != 'undefined')?selection[0].get('id'):0;
                attr.removeAll();
                if(gid>0) {
                    // Ado list for group reload
                    attr.load({
                        callback: this.onGroupAttrLoad,
                        params: {
                            id: gid
                        },
                        scope: this
                    });
                    // Ado list for group reload
                    ado.load({
                        callback: this.onGroupAdoLoad,
                        params: {
                            gid: gid
                        },
                        scope: this
                    });
                }
                else {
                    attr.loadData({});
                    ado.loadData({});
                    Ext.getCmp('group-form-attredit').setDisabled(true);
                    Ext.getCmp('group-form-adoedit').setDisabled(true);
                }
                // Enable buttons after selection
                Ext.getCmp('group-button-del').setDisabled(false);
                Ext.getCmp('group-button-upd').setDisabled(false);
                this.getGroupEdit().setDisabled(false);
                this.application.fireEvent('groupselected', selection[0]);
            }
            else
            {
                this.getGroupList().getSelectionModel().select(store.indexOf(record));
                Ext.Msg.alert('Ошибка','Поля заполнены неверно!');
            }
        }
    },

    onGroupsLoad: function(groups, request) {
        var store = this.getObjGroupsStore();
        store.clearFilter();
        store.sort('name', 'ASC');
    },

    onGroupCreate: function(button, aEvent, aOptions) {
        var store = this.getObjGroupsStore(),
            tree = this.getDictAttributesStore(),
            attr = this.getObjGroupAttrsStore();
        if(store.getNewRecords().length == 0)
        {
            attr.removeAll();
            tree.getRootNode().cascadeBy(function(n){n.set('checked', (n.get('checked')!= null)?false:null);} );
            store.insert(0, Ext.create('Targeting.model.obj.Group', {
                appid: this.getAppList().getSelectionModel().getSelection()[0].get('appid'),
                name: 'Новая группа',
                priorityid: 1,
                weight: 0,
                enable: 0,
                attr: []
            }));
            this.getGroupList().getSelectionModel().select(0);
        }
        else
        {
            var newGroup = store.getNewRecords()[0];
            this.getGroupList().getSelectionModel().select(store.indexOf(newGroup));
        }
    },

    onGroupDelete: function(button, aEvent, aOptions) {
        var form = this.getGroupEdit(),
            store = this.getObjGroupsStore(),
            record = this.getGroupList().getSelectionModel().getSelection()[0],
            pos = store.indexOf(record);
        store.remove(record);
        if(store.count()>0)
        {
            this.getGroupList().getSelectionModel().select(pos>=store.count()-1?store.count()-1:pos);
        }
        else
        {
            Ext.getCmp('group-button-del').setDisabled(true);
            Ext.getCmp('group-button-upd').setDisabled(true);
            form.loadRecord(Ext.create('Targeting.model.obj.Group'));
            form.setDisabled(true);
        }
        store.sync({
            success: function (b, o) {
                console.log('Deleted group: ' + record.get('name'));
            },
            failure: function (b, o) {
                console.log('ERROR deleting group: ' + record.get('name'));
                store.insert(pos, record);
                this.getGroupList().getSelectionModel().select(pos);
            },
            scope: this
        });
    },

    onGroupUpdate: function(button, aEvent, aOptions) {
        var form = this.getGroupEdit(),
            record = form.getRecord(),
            values = form.getValues();

        if(form.isValid())
        {
            record.set(values);
            this.GroupAttrUpdate(record);
            this.getObjGroupsStore().sync({
                success: function (b, o) {
                    console.log('Saved group: ' + record.get('name'));
                    var ados = this.getObjGroupAdosStore(),
                        group = this.getGroupList().getSelectionModel().getSelection()[0];
                    ados.sync({
                        success: function (b, o) {
                            console.log('Saved ados for group: ' + group.get('name'));
                        },
                        failure: function (b, o) {
                            console.log('ERROR saving ados for group: ' + group.get('name'));
                        },
                        scope: this
                    });
                    Ext.getCmp('group-form-attredit').setDisabled(false);
                    Ext.getCmp('group-form-adoedit').setDisabled(false);
                },
                failure: function (b, o) {
                    console.log('ERROR saving group: ' + record.get('name'));
                },
                scope: this
            });
        }
        else
        {
            Ext.Msg.alert('Ошибка','Поля заполнены неверно!');
        }
    },

    onGroupAttrTreeCheckChange: function(node, checked, options) {
        node.cascadeBy(function(n){n.set('checked', checked);} );
        this.CheckboxTreeParentCheck(node.parentNode, checked);
    },

    // Check if parent should also be checked
    CheckboxTreeParentCheck: function(node, checked) {
        if(node != null) {
            var state = checked,
                length = node.childNodes.length;
            if(node.get('checked') != null) {
                if(length > 0) {
                    for(var i = 0; i < length; i++) {
                        var child = node.childNodes[i];
                        state = state && ((child.get('checked') != null)?child.get('checked'):true);
                    }
                }
                node.set('checked', state);
            }
            this.CheckboxTreeParentCheck(node.parentNode, state);
        }
    },

    // Set values
    onGroupAttrLoad: function(records, operation, success) {
        var attr = this.getObjGroupAttrsStore(),
            tree = this.getDictAttributesStore(),
            cnt = attr.count();
        if(success && cnt > 0) {
            for(var i = 0; i < cnt; i++) {
                var a = attr.getAt(i),
                    tag = a.get('tag');
                if(tree.getNodeById(tag).hasChildNodes())
                {
                    var node = tree.getNodeById(a.get('id'));
                    if(typeof node != 'undefined')
                    {
                        node.set('checked', (node.get('checked') != null)?true:null);
                        this.CheckboxTreeParentCheck(node.parentNode, true);
                    }
                }
            }
        }
        Ext.getCmp('group-form-attredit').setDisabled(!success);
    },

    // Update attr field using data in targeting tree
    GroupAttrUpdate: function(group) {
        var root = this.getDictAttributesStore().getRootNode(),
            attr = [],
            tlist = {},
            tmp = {};
        //fields: ['id', 'gid', 'aid', 'tag', 'value'],
        root.cascadeBy(
            function(n){
                if(n.get('checked') && !n.hasChildNodes()){
                    var tag = n.get('tag'),
                        value = n.get('value');
                    if(typeof(tmp[tag]) == 'undefined') {
                        tmp[tag] = [];
                    }
                    tmp[tag].push(value);
                };
            },
            this
        );
        for(var t in tmp) {
            attr.push({tag: t, values: tmp[t]});
            tlist[t] = true;
        }
        // Check if all values unset for tag & send empty value list
        root.eachChild(
            function(n){
                var t = n.get('tag');
                if(n.hasChildNodes() && (typeof(tlist[t]) == 'undefined')){
                    attr.push({tag: t, values: []});
                }
            },
            this
        );

        group.set('attr', attr);
    },

    onGroupAdoLoad: function(records, operation, success) {
        Ext.getCmp('group-form-adoedit').setDisabled(!success);
    },

    onGroupAdoAdd: function() {
        var window = Ext.create('Targeting.view.group.AdoAdd'),
            store = Ext.getStore('obj.Ados'),
            ados = this.getObjGroupAdosStore();
        store.filterBy(
            function(record, id){
                return ados.getById(id)==null;
            },
            this
        );
        window.show();
    },

    onGroupAdoDelete: function(view,cell,row,col,e) {
        var ados = this.getObjGroupAdosStore(),
            group = this.getGroupList().getSelectionModel().getSelection()[0];
        ados.removeAt(row);
        ados.sync({
            success: function (b, o) {
                console.log('Deleted ados for group: ' + group.get('name'));
            },
            failure: function (b, o) {
                console.log('ERROR deleting ados for group: ' + group.get('name'));
            },
            scope: this
        });
    },

    onGroupAdoAddOK: function(button) {
        var window = button.up('window'),
            grid = window.down('grid'),
            records = grid.getSelectionModel().getSelection(),
            ados = this.getObjGroupAdosStore(),
            group = this.getGroupList().getSelectionModel().getSelection()[0];
        for(var i = 0, n = records.length; i < n; i++) {
            ados.insert(0, Ext.create('Targeting.model.obj.GroupAdo', {
                oid: records[i].get('id'),
                gid: group.get('id'),
                enable: true,
                name: records[i].get('name'),
                tid: records[i].get('tid')
            }));
        }
        ados.sync({
            success: function (b, o) {
                console.log('Added ados for group: ' + group.get('name'));
            },
            failure: function (b, o) {
                console.log('ERROR adding ados for group: ' + group.get('name'));
            },
            scope: this
        });
        button.up('window').close();
    },

    onGroupAdoAddCancel: function(button) {
        button.up('window').close();
    },

    onGroupAdoAddClose: function() {
        Ext.getStore('obj.Ados').clearFilter();
    }

});