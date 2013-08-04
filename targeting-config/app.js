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
    
    controllers: ['Apps', 'Ados', 'Groups']
});
