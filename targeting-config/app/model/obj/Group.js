Ext.define('Targeting.model.obj.Group', {
    extend: 'Ext.data.Model',
    fields: ['id', 'appid', 'name', 'attr', 'weight', 'priorityid', 'enable'],

    proxy: {
        type: 'ajax',
        api: {
            create  : '/call/targeting-config/edit?store=obj.group&action=create',
            read: '/call/targeting-config/edit?store=obj.group&action=read',
            update: '/call/targeting-config/edit?store=obj.group&action=update',
            destroy: '/call/targeting-config/edit?store=obj.group&action=destroy'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});