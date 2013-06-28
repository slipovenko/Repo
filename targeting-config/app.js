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
    
    models: ['App', 'Ado', 'Group', 'GroupAttr', 'dict.Attribute', 'dict.Priority', 'dict.Type'],
    stores: ['Apps', 'Ados', 'Groups','GroupAttrs', 'dict.Attributes', 'dict.Priorities', 'dict.Types'],
    controllers: ['Apps', 'Ados', 'Groups']
});
