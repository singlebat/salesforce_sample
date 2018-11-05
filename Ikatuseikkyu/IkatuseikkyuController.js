({
	myAction : function(component, event, helper) {
		
	},
	  /** 
     * 初期化処理
     */
    doInit: function(component, event, helper) {
    	var hiduke=new Date(); 
    	var year = hiduke.getFullYear();
    	var month = hiduke.getMonth()+1;
    	component.set("v.month",month.toString()); 
    	component.set("v.year",year.toString()); 
    },
    
    handleClick: function(component, event, helper) {
    	var vYear = Number(component.get("v.year"));
    	var vMonth = Number(component.get("v.month")) - 1; // Javascriptは、0-11で表現
    	var vDay = 1;

    	if(vMonth >= 0 && vMonth <= 11){
    		var vDt = new Date(vYear, vMonth, vDay);
    		if(isNaN(vDt)){
    			component.set("v.errorMessage","請求年を入力してください!");
    		    return;
    		}else if(vDt.getFullYear() == vYear && vDt.getMonth() == vMonth && vDt.getDate() == vDay){
    		
    		}else{
    			component.set("v.errorMessage","請求年を正しく入力してください!");
    		    return;
    		}
    	}else{
    	    component.set("v.errorMessage","請求月を正しく入力してください!");
    		return;
    	}
    	
    	//請求先
    	var request=component.get("v.newBill.Account__c");
    	//問い合わせNO
    	var questionNO=component.get("v.newBill.agrement__c");
    	var firstAction = component.get("c.saveAllBillDetail");
    	firstAction.setParams({
    		"year": component.get("v.year"),
    		"month": component.get("v.month"),
    		"PaywayValue": component.get("v.PaywayValue"),
    		"localValue": component.get("v.localValue"),
    		"day":component.get("v.day"),
    		"request": request,
    		"questionNO": questionNO,
    	});
    	firstAction.setCallback(this,function(res){
    		if(res.getState() === "SUCCESS"){
    			var action = component.get("c.createInvoiceMutiPDF");
    			action.setParams({
    				"year": component.get("v.year"),
    				"month": component.get("v.month"),
    				"PaywayValue": component.get("v.PaywayValue"),
    				"localValue": component.get("v.localValue"),
    				"day":component.get("v.day"),
    				"request": request,
    				"questionNO": questionNO,
    			});
    			//印刷actionを実行する 
    			helper.executePrint(action,component);
    		}else{
    			helper.showError(component,"一括請求明細を作成する時、エラーを発生する。");
    		}
    	})
        $A.enqueueAction(firstAction);
    }
})