({
	helperMethod : function() {
		
	},
	
	showError : function(component,errorMessage) {
    	var resultsToast = $A.get("e.force:showToast");
    	resultsToast.setParams({
    		"title": "更新失敗",
    		"message": errorMessage,
    		"type":"ERROR"
    	});
    	resultsToast.fire();
	},
})