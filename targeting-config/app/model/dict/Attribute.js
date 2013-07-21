Ext.define('Targeting.model.dict.Attribute', {
    extend: 'Ext.data.Model',
    fields: ['id', 'tag', 'value', 'name'],

    proxy: {
        type: 'ajax',
        api: {
            read: 'data/data.pl?obj=dict.attr&action=read'
        },
        reader: {
            type: 'json',
            root: 'children',
            successProperty: 'success'
        }
    }
});