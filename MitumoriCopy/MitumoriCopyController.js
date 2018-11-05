({
	doInit : function(component, event, helper) {
		
	},
	
    copyEstimate : function(component, event, helper){
    	$A.util.toggleClass(component.find("mySpinner"),"slds-hide");
    	var statusAction = component.get("c.getStatus");
    	//パラメータ設定
    	statusAction.setParams({
    		"id": component.get("v.recordId"),
    	});
    	//メソッド実行
    	$A.enqueueAction(statusAction);
    	statusAction.setCallback(this, function(result) {
    		var prestate = result.getState();
    		if (prestate == "SUCCESS") {
    			if(result.getReturnValue().QuotationStatus__c=="成約" || result.getReturnValue().QuotationStatus__c=="契約済"){
    				var resultsToast = $A.get("e.force:showToast");
    				resultsToast.setParams({
    					"title": "Copy fail",
    					"message": "成約後の見積はコピーできません。",
    					"type":"ERROR"
    				});
    				resultsToast.fire();
    				
    				$A.get("e.force:closeQuickAction").fire();
    			}else{
    				var action = component.get("c.copy");
    				//パラメータ設定
    				action.setParams({
    					"id": component.get("v.recordId"),
    					"copyType": component.get("v.value"),
    				});
    				//メソッド実行
    				$A.enqueueAction(action);
    				action.setCallback(this, function(res) {
    					var state = res.getState();
    					if (state == "SUCCESS") {
    						var toastEvent = $A.get("e.force:showToast");
    						if (res.getReturnValue() == "") {
    							toastEvent.setParams({
    								"title": "見積コピー失敗",
    								"message": "該当見積下、更新がないために、コピーできません。",
    								"type":"error"
    							});
    							$A.get("e.force:closeQuickAction").fire();
    						} else {
    							var navEvt = $A.get("e.force:navigateToSObject");

    							navEvt.setParams({
    								"recordId": res.getReturnValue(),
    								"slideDevName": "detail"
    							});
    							navEvt.fire();

    							toastEvent.setParams({
    								"title": "見積コピー成功",
    								"message": "新しい見積へ遷移しました。",
    								"type":"success"
    							});
    						}
    						toastEvent.fire();
    					}
    				});
    			}    	
    		}
    	});
    },
})