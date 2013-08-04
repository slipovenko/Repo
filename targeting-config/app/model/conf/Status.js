Ext.define('Targeting.model.conf.Status', {
    extend: 'Ext.data.Model',
    fields: ['id', 'value', 'cid', 'utime'],

    proxy: {
        type: 'ajax',
        api: {
            read: '/call/targeting-config/edit?store=conf.status&action=read',
            update: '/call/targeting-config/edit?store=conf.status&action=update'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});