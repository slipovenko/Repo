Ext.define('Targeting.model.obj.App', {
    extend: 'Ext.data.Model',
    fields: ['id', 'appid', 'name'],

    proxy: {
        type: 'ajax',
        api: {
            create  : '/call/targeting-config/edit?store=obj.app&action=create',
            read: '/call/targeting-config/edit?store=obj.app&action=read',
            update: '/call/targeting-config/edit?store=obj.app&action=update',
            destroy : '/call/targeting-config/edit?store=obj.app&action=destroy'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});