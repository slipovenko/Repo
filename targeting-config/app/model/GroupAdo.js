Ext.define('Targeting.model.GroupAdo', {
    extend: 'Ext.data.Model',
    fields: ['id', 'gid', 'enable', 'name', 'tid'],

    proxy: {
        type: 'ajax',
        api: {
            create  : '/call/targeting-config/edit?obj=group.ado&action=create',
            read: '/call/targeting-config/edit?obj=group.ado&action=read',
            update: '/call/targeting-config/edit?obj=group.ado&action=update',
            destroy : '/call/targeting-config/edit?obj=group.ado&action=destroy'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});