Ext.define('Targeting.model.dict.Attribute', {
    extend: 'Ext.data.Model',
    fields: ['id', 'tag', 'name'],

    proxy: {
        type: 'ajax',
        api: {
            read: 'data/data.pl?obj=dict.attr&action=read'
        },
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    }
});