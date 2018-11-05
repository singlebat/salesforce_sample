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
	
    changeNyukinKiaknEndDateMain:function(component){
        console.log("changeNyukinKiaknEndDateMain Start :: ");
        //入金期間終了日
        var NyukinKiaknEndDate = component.get("v.agreement.NyukinKiaknEndDate__c");
        //残存リース期間終了日
        var ZanzonEndDate = component.get("v.agreement.ZanzonEndDate__c");
        //入金期間終了日より、残存リース期間開始日を算出する。
        var date = new Date(component.get("v.agreement.NyukinKiaknEndDate__c"));
        date.setDate( date.getDate() + 1);
        var ZanzonStartDate = date.getFullYear()
                             +"-"+Array(2>(''+(date.getMonth()+1)).length?(2-(''+(date.getMonth()+1)).length+1):0).join(0)+(date.getMonth()+1)
                             +"-"+Array(2>(''+(date.getDate())).length?(2-(''+(date.getDate())).length+1):0).join(0)+(date.getDate());
        component.set("v.agreement.ZanzonStartDate__c",ZanzonStartDate);
        
        //支払予定表を繰り返して、入金期間開始日から残存リース期間終了日までに入金べき総額を算出する。
        //支払予定表を繰り返して、入金期間終了日までに入金済金額を算出する。
        var PaymentDetails = component.get("v.PaymentDetails");
        if (PaymentDetails != null && PaymentDetails != undefined) {
        	var sumPayment = 0;
        	var sumMoney = 0;
            for (var i = 0 ; i < PaymentDetails.length ; i++) {
        		console.log(PaymentDetails[i].KijitsuDate__c);
        		if (ZanzonEndDate > PaymentDetails[i].KijitsuDate__c) {
        			sumPayment += PaymentDetails[i].Payment__c;
        		}
        		if (NyukinKiaknEndDate > PaymentDetails[i].KijitsuDate__c) {
        			sumMoney += PaymentDetails[i].Payment__c;
        		}
        	}
        	console.log(sumMoney);
        	//入金済金額
        	component.set("v.agreement.NyukinOverAmount__c",sumMoney);
        	//残存リース料
        	component.set("v.agreement.ZanzonLeaseAmount__c",sumPayment -  sumMoney);
        }
    },
    
    //PDF印刷メイン処理
    executePrint:function(action,component){
    	action.setCallback(this, function(response) {
    		var state = response.getState();
    		console.log(state);
    		var toastEvent = $A.get("e.force:showToast");
    		if(state == "SUCCESS"){
    			$A.get("e.force:closeQuickAction").fire();
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
	                this.showError(component,"PDF作成失敗。");
	            }
    		}else if (state == "ERROR") {
    			this.showError(component,"システム管理者を連絡ください。");
    			$A.get("e.force:closeQuickAction").fire();
    		}
    		$A.get('e.force:refreshView').fire();
    	});
    	$A.enqueueAction(action);
    },
    
    changeKaiyakuDateMain:function(component){
        var date = new Date(component.get("v.agreement.KaiyakuDate__c"));
        date.setDate( 1 - 1);
        console.log(date);
        //解約日より、入金期間終了日を算出する。
        var NyukinKiaknEndDate = date.getFullYear()
                             +"-"+Array(2>(''+(date.getMonth()+1)).length?(2-(''+(date.getMonth()+1)).length+1):0).join(0)+(date.getMonth()+1)
                             +"-"+Array(2>(''+(date.getDate())).length?(2-(''+(date.getDate())).length+1):0).join(0)+(date.getDate());
        console.log(NyukinKiaknEndDate);
        component.set("v.agreement.NyukinKiaknEndDate__c",NyukinKiaknEndDate);
    },
    
    
})