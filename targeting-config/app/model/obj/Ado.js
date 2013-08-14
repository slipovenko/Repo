Ext.define('Targeting.model.obj.Ado', {
    extend: 'Ext.data.Model',
    fields: ['id', 'appid', 'uuid', 'flink', 'ilink', 'tid', 'name', 'attr'],

    proxy: {
        type: 'ajax',
        api: {
            create  : '/call/targeting-config/edit?store=obj.ado&action=create',
            read: '/call/targeting-config/edit?store=obj.ado&action=read',
            update: '/call/targeting-config/edit?store=obj.ado&action=update',
            destroy: '/call/targeting-config/edit?store=obj.ado&action=destroy'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});