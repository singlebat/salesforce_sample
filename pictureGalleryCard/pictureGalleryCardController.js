({
    doInit : function(component) {
        //component.set("v.slides",component.get("v.imgUrl"));
        component.set("v.fullScreen", false);
    },

	closeDialog : function(component) {
        component.set("v.fullScreen", false);
	},
	
	itemsChange : function(component) {
	    console.log(component.get("v.imgUrl"));
        component.set("v.slides",component.get("v.imgUrl"));
	}

})