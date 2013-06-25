Ext.define('Targeting.view.group.attr.Geo', {
    extend: 'Ext.tree.Panel',
    alias: 'widget.groupattrgeo',

    autoShow: true,

    title: 'Таргетинг',

    initComponent: function() {
        this.store = Ext.create('Ext.data.TreeStore', {
            root: {
                expanded: true,
                iconCls: 'x-tree-icon',
                children: [
                    { text: "География", checked: false, children: [
                        { text: "Россия", checked: false, leaf: true },
                        { text: "СНГ (кроме России)", checked: false, leaf: true},
                        { text: "Европа", checked: false, leaf: true}
                    ] },
                    { text: "Пол", checked: false, icon: null, children: [
                        { text: "Не определен", checked: false, leaf: true },
                        { text: "Мужской", checked: false, leaf: true},
                        { text: "Женский", checked: false, leaf: true}
                    ] },
                    { text: "Возраст", checked: false, expanded: true, children: [
                        { text: "от 11 до 20 лет", checked: false, leaf: true },
                        { text: "от 21 до 30 лет", checked: false, leaf: true}
                    ] }
                ]
            }
        });

        this.callParent(arguments);
    }
});
