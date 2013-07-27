Ext.define('Targeting.model.dict.Type', {
    extend: 'Ext.data.Model',
    fields: ['id', 'mtype', 'name'],

    proxy: {
        type: 'ajax',
        api: {
            read: '/call/targeting-config/edit?obj=dict.type&action=read'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});