Ext.define('Targeting.model.Ado', {
    extend: 'Ext.data.Model',
    fields: ['id', 'uuid', 'name'],

    proxy: {
        type: 'ajax',
        api: {
            create  : 'data/data.pl?obj=ado&action=create',
            read: 'data/data.pl?obj=ado&action=read',
            update: 'data/data.pl?obj=ado&action=update',
            destroy : 'data/data.pl?obj=ado&action=destroy'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});