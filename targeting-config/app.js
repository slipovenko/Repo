Ext.application({
    name: 'Targeting',
    appFolder: 'app',

    require: [
        'Ext.grid.*',
        'Ext.data.*',
        'Ext.util.*',
        'Ext.state.*',
        'Ext.form.*'
    ],

    autoCreateViewport: true,
    
    models: ['App', 'Ado', 'Group', 'GroupAttr', 'dict.Attribute', 'dict.AttributeValue', 'dict.Priority', 'dict.Type'],
    stores: ['Apps', 'Ados', 'Groups','GroupAttrs', 'dict.Attributes', 'dict.AttributeValues', 'dict.Priorities', 'dict.Types'],
    controllers: ['Apps', 'Ados', 'Groups']
});
