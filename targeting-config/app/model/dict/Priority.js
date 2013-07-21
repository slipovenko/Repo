Ext.define('Targeting.model.dict.Priority', {
    extend: 'Ext.data.Model',
    fields: ['id', 'value', 'name'],

    proxy: {
        type: 'ajax',
        api: {
            read: 'data/data.pl?obj=dict.priority&action=read'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});