Ext.define('Targeting.model.GroupAdo', {
    extend: 'Ext.data.Model',
    fields: ['id', 'gid', 'enable', 'name', 'tid'],

    proxy: {
        type: 'ajax',
        api: {
            create  : 'data/data.pl?obj=group.ado&action=create',
            read: 'data/data.pl?obj=group.ado&action=read',
            update: 'data/data.pl?obj=group.ado&action=update',
            destroy : 'data/data.pl?obj=group.ado&action=destroy'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});