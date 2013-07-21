Ext.define('Targeting.model.App', {
    extend: 'Ext.data.Model',
    fields: ['id', 'appid', 'name'],

    proxy: {
        type: 'ajax',
        api: {
            create  : 'data/data.pl?obj=app&action=create',
            read: 'data/data.pl?obj=app&action=read',
            update: 'data/data.pl?obj=app&action=update',
            destroy : 'data/data.pl?obj=app&action=destroy'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});