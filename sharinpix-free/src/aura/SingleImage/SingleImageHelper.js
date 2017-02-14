({
    reloadSource: function(component) {
        var source = component.get('v.attachmentId');
        if (!$A.util.isEmpty(source) && (source.length === 15 || source.length === 18)) {
            if (source.startsWith('00P')){
                component.set('v.source', component.get('v.siteUrl') + '/servlet/servlet.FileDownload?file=' + source);
            }
            else if (source.startsWith('068')){
                component.set('v.source', '/sfc/servlet.shepherd/version/download/'+source);
            }
        }
        else {
            component.set('v.source', source);
        }
    },
    site_url: function(component){
        var action = component.get("c.site");
        action.setCallback(this, function(response) {
            component.set('v.siteUrl', response.getReturnValue());
            this.reloadSource(component);
        });
        $A.enqueueAction(action);
    }
})