    Ext.define('Targeting.controller.Groups', {
    extend: 'Ext.app.Controller',
    
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
        ref: 'groupAttrTree',
        selector: 'groupattrtree'
    }],

    views: ['group.List', 'group.Edit', 'group.AdoList', 'group.AttrTree'],
    stores: ['Apps', 'Groups', 'GroupAdos', 'GroupAttrs', 'dict.Attributes'],

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
        this.getGroupAdosStore().removeAll();
        var tree = this.getDictAttributesStore();
        tree.getRootNode().cascadeBy(function(n){n.set('checked', (n.get('checked')!= null)?false:null);} );

        // Clear group store & reload
        var store = this.getGroupsStore();
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
            var store = this.getGroupsStore(),
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
                var attr = this.getGroupAttrsStore();
                attr.load({
                    callback: this.onGroupAttrLoad,
                    params: {
                        id: selection[0].get('id')
                    },
                    scope: this
                });
                // Ado list for group reload
                var ado = this.getGroupAdosStore();
                ado.removeAll();
                ado.load({
                    //callback: this.onGroupAttrLoad,
                    params: {
                        gid: selection[0].get('id')
                    },
                    scope: this
                });
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
        var store = this.getGroupsStore();
        store.clearFilter();
        store.sort('name', 'ASC');
    },

    onGroupCreate: function(button, aEvent, aOptions) {
        var store = this.getGroupsStore();
        if(store.getNewRecords().length == 0)
        {
            var newGroup = Ext.create('Targeting.model.Group');
            newGroup.set('appid', this.getAppList().getSelectionModel().getSelection()[0].get('appid'));
            newGroup.set('name', 'Новая группа');
            newGroup.set('priorityid', 1);
            newGroup.set('weight', 0);
            newGroup.set('enable', 0);
            newGroup.set('attr', '');
            store.insert(0, newGroup);
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
            store = this.getGroupsStore(),
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
            form.loadRecord(Ext.create('Targeting.model.Group'));
            form.setDisabled(true);
        }
        store.sync({
            success: function (b, o) {
                console.log('Deleted group: ' + record.get('name'));
            },
            failure: function (b, o) {
                console.log('ERROR deleting group: ' + record.get('name'));
                store.insert(pos, record);
            }
        });
    },

    onGroupUpdate: function(button, aEvent, aOptions) {
        var form = this.getGroupEdit(),
            record = form.getRecord(),
            values = form.getValues();

        if(form.isValid())
        {
            record.set(values);
            this.getGroupsStore().sync({
                success: function (b, o) {
                    console.log('Saved group: ' + record.get('name'));
                },
                failure: function (b, o) {
                    console.log('ERROR saving group: ' + record.get('name'));
                }
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

    onGroupAttrLoad: function() {
        var attr = this.getGroupAttrsStore(),
            tree = this.getDictAttributesStore(),
            cnt = attr.count();
        if(cnt > 0) {
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
    }
});