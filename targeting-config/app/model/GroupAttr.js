Ext.define('Targeting.model.GroupAttr', {
    extend: 'Ext.data.Model',
    fields: ['id', 'aid', 'values'],

    proxy: {
        type: 'ajax',
        api: {
            create  : 'data/data.pl?obj=group.attr&action=create',
            read: 'data/data.pl?obj=group.attr&action=read',
            update: 'data/data.pl?obj=group.attr&action=update',
            destroy : 'data/data.pl?obj=group.attr&action=destroy'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});