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
    
    models: ['App', 'Ado', 'Group'],
    stores: ['Apps', 'Ados', 'Groups'],
    controllers: ['Apps', 'Ados', 'Groups']
});
