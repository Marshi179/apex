({
	doInit : function(component, event, helper) {
		helper.siteUrl(component);
		helper.reloadSource(component);

		var height = component.get('v.height');
		if (typeof height !== "undefined" && height !== null && height > 200) {

		}else{
			height = 200;
		}
		component.set('v.style', 'height: '+height+'px; line-height: '+height+'px;');
	},
	doReload: function(component, event, helper){
		component.set('v.loading', true);
		helper.reloadSource(component)
	},
	onLoaded: function (component) {
		component.set('v.loading', false);
	}
})