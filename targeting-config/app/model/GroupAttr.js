Ext.define('Targeting.model.GroupAttr', {
    extend: 'Ext.data.Model',
    fields: ['id', 'gid', 'aid', 'tag', 'value'],

    proxy: {
        type: 'ajax',
        api: {
            read: 'data/data.pl?obj=group.attr&action=read',
            update: 'data/data.pl?obj=group.attr&action=update'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});