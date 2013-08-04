Ext.define('Targeting.model.obj.GroupAttr', {
    extend: 'Ext.data.Model',
    fields: ['id', 'gid', 'aid', 'tag', 'value'],

    proxy: {
        type: 'ajax',
        api: {
            read: '/call/targeting-config/edit?store=obj.group.attr&action=read'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});