({
	//エラーメッセージ
    showError : function(component,errorMessage) {
    	var resultsToast = $A.get("e.force:showToast");
    	resultsToast.setParams({
    		"title": "印刷失敗",
    		"message": errorMessage,
    		"type":"ERROR"
    	});
    	resultsToast.fire();
	},
	
	//PDF印刷メイン処理
    executePrint:function(action,component){
    	action.setCallback(this, function(response) {
    		var state = response.getState();
    		console.log(state);
    		var toastEvent = $A.get("e.force:showToast");
    		if(state == "SUCCESS"){
    			//PDFのプレビュー機能を実現する
    			console.log("response:"+response.getReturnValue());
    			if(response.getReturnValue() != null){
    				toastEvent.setParams({
    					"title": '',
    					"message": "PDF作成成功",
    					"type":"success"
    				});
    				toastEvent.fire();
    			    var result=response.getReturnValue();
    			    console.log("response:"+result);
                    var fileIdlist = [];
                    for(var i in result){
                        fileIdlist.push(result[i]);
                    }
                    $A.get('e.lightning:openFiles').fire({
                        recordIds: fileIdlist,
                    });
	            } else {
	                this.showError(component,"請求明細ないのため、印刷しません。");
	            }
    		}else if (state == "ERROR") {
    			this.showError(component,"システム管理者を連絡ください。");
    		}
    	});
    	$A.enqueueAction(action);
    },
})