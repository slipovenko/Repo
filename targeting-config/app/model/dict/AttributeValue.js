Ext.define('Targeting.model.dict.AttributeValue', {
    extend: 'Ext.data.Model',
    fields: ['id', 'value', 'name'],

    proxy: {
        type: 'ajax',
        api: {
            read: 'data/data.pl?obj=dict.attrvalue&action=read'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});