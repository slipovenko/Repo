Ext.define('Targeting.model.Group', {
    extend: 'Ext.data.Model',
    fields: ['id', 'appid', 'name', 'attr', 'weight', 'priorityid', 'enable'],

    proxy: {
        type: 'ajax',
        api: {
            create  : '/call/targeting-config/edit?obj=group&action=create',
            read: '/call/targeting-config/edit?obj=group&action=read',
            update: '/call/targeting-config/edit?obj=group&action=update',
            destroy : '/call/targeting-config/edit?obj=group&action=destroy'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});