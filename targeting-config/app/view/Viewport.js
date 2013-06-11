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
        var groupTab = Ext.create('Ext.panel.Panel', {
            id: 'group-tab-panel',
            title: 'Группы',
            width: '100%',
            height: '100%',
            layout: 'border',
            items: [{
                    xtype: 'grouplist',
                    height: '50%',
                    width: '100%',
                    region: 'center',
                    layout: 'fit',
                    margins: '5 5 0 0'
                },{
                    id: 'group-form-edit',
                    xtype: 'groupedit',
                    disabled: true,
                    height: '50%',
                    width: '100%',
                    region: 'south',
                    split: true,
                    margins: '0 5 5 5'
                }],
            disabled: true
        });
        var adoTab = Ext.create('Ext.panel.Panel', {
            id: 'ado-tab-panel',
            title: 'Объекты',
            width: '100%',
            height: '100%',
            layout: 'border',
            items: [{
                xtype: 'adolist',
                height: '50%',
                width: '100%',
                region: 'center',
                layout: 'fit',
                margins: '5 5 0 0'
            },{
                id: 'ado-form-edit',
                xtype: 'adoedit',
                disabled: true,
                height: '50%',
                width: '100%',
                region: 'south',
                split: true,
                margins: '0 5 5 5'
            }],
            disabled: true
        });
        var propertyTabs = Ext.create('Ext.tab.Panel', {
            height: '100%',
            width: '100%',
            region: 'center',
            margins: '5 5 0 0',
            items: [
                {
                    id: 'app-form-edit',
                    xtype: 'appedit',
                    disabled: true,
                    title: 'Информация'
                },
                groupTab,
                adoTab
            ]
        });
        this.items = {
            width: '100%',
            height: '100%',
            title: 'Настройки таргетинга',
            layout: 'border',
            items: [{
                    xtype: 'applist',
                    height: '100%',
                    width: 200,         
                    region: 'west',
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