Ext.define('Targeting.model.dict.Priority', {
    extend: 'Ext.data.Model',
    fields: ['id', 'value', 'name'],

    proxy: {
        type: 'ajax',
        api: {
            read: '/call/targeting-config/edit?store=dict.priority&action=read'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});