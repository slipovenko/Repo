Ext.define('Targeting.store.dict.Attributes', {
    extend: 'Ext.data.TreeStore',
    requires: 'Targeting.model.dict.Attribute',
    model: 'Targeting.model.dict.Attribute',
    autoLoad: true,

    listeners: {
        append: function( thisNode, newChildNode, index, eOpts ) {
            if( !newChildNode.isRoot() ) {
                newChildNode.set('text', newChildNode.get('name'));
            }
        }
    }
});