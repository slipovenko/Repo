Ext.define('Targeting.model.Group', {
    extend: 'Ext.data.Model',
    fields: ['id', 'name', 'weight', 'priorityid'],

    proxy: {
        type: 'ajax',
        api: {
            create  : 'data/data.pl?obj=group&action=create',
            read: 'data/data.pl?obj=group&action=read',
            update: 'data/data.pl?obj=group&action=update',
            destroy : 'data/data.pl?obj=group&action=destroy'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});