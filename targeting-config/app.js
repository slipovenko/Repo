Ext.application({
    name: 'Targeting',
    appFolder: 'app',

    autoCreateViewport: true,
    
    models: ['App', 'Ado', 'Group'],
    stores: ['Apps', 'Ados', 'Groups'],
    controllers: ['Apps', 'Ados', 'Groups']
});
