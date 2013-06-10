Ext.define('Targeting.store.dict.Attributes', {
    extend: 'Ext.data.Store',
    requires: 'Targeting.model.dict.Attribute',
    model: 'Targeting.model.dict.Attribute',
    autoLoad: true
});