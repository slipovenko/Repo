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
    
    models: ['App', 'Ado', 'Group', 'GroupAdo', 'GroupAttr', 'dict.Attribute', 'dict.Priority', 'dict.Type'],
    stores: ['Apps', 'Ados', 'Groups', 'GroupAdos', 'GroupAttrs', 'dict.Attributes', 'dict.Priorities', 'dict.Types'],
    controllers: ['Apps', 'Ados', 'Groups']
});
