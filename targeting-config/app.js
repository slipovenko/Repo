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
    
    models: ['App', 'Ado', 'Group', 'dict.Priority', 'dict.Type'],
    stores: ['Apps', 'Ados', 'Groups', 'dict.Priorities', 'dict.Types'],
    controllers: ['Apps', 'Ados', 'Groups']
});
