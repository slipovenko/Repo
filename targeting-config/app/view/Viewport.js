Ext.define('Targeting.view.Viewport', {
    extend: 'Ext.container.Viewport',
    layout: 'fit',
    
    requires: [
        'Targeting.view.app.List',
        'Targeting.view.app.Edit',
        'Targeting.view.ado.List',
        'Targeting.view.group.List'
    ],
    
    initComponent: function() {
        var propertyTabs = Ext.create('Ext.tab.Panel', {
            height: '100%',
            width: '100%',
            region: 'center',
            margins: '5 5 0 0',
            items: [
                {
                    xtype: 'appedit',
                    title: 'Информация'
                },{
                    xtype: 'grouplist',
                    title: 'Группы',
                    html: 'Группы контента',
                },{
                    xtype: 'adolist',
                    title: 'Объекты'
                }               
            ]
        });
        this.items = {
            width: '100%',
            height: '100%',
            title: 'Настройки таргетинга',
            layout: 'border',
            items: [{
                    xtype: 'applist',
                    title: 'Список приложений',
                    height: '100%',
                    width: 200,         
                    region:'west',
                    margins: '5 0 0 5',
                    collapsible: true,          
                    layout: 'fit'
                },
                propertyTabs
            ]
        };

        this.callParent();
    }
});