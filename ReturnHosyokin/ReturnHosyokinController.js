({
	handleRecordUpdated: function(component, event, helper) {
    	var eventParams = event.getParams();
    	if(eventParams.changeType === "LOADED") {
    		// record is loaded (render other component which needs record data value)
    		console.log("Record is loaded successfully.");
    		//ダメージ料金（配送から）をダメージ料金（実際）にセットする。
    		if ( $A.util.isEmpty(component.get ("v.simpleNewAgreement.damageMoney__c")) || component.get ("v.simpleNewAgreement.damageMoney__c") == 0) {
    		    component.set("v.simpleNewAgreement.damageMoney__c",component.get("v.simpleNewAgreement.DamageMoneySum__c"));
    		}
        } else if(eventParams.changeType === "CHANGED") {
            // record is changed
            console.log("Record is CHANGED successfully.");
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    },
	
	/** 
     * 保存ボタンを押す
     */
    handleSaveContact: function(component, event, helper) {
        console.log("handleSaveContact");
        
        if (component.get("v.simpleNewAgreement.NextProductUpdCnt__c") == 0 &&  ($A.util.isEmpty(component.get("v.simpleNewAgreement.ReturnHoshokinDate__c"))
    	　　　　　    　　　|| $A.util.isUndefinedOrNull(component.get("v.simpleNewAgreement.ReturnHoshokinDate__c")))){
        	var inputCmp = component.find("ReturnHoshokinDate");
        	inputCmp.set("v.errors", [{message:"返金日を入力してください"}]);
        	return;
        }
        
        var status=component.get("v.simpleNewAgreement.Status__c");
        console.log(status);
        if(status=="契約更新済" || status== "契約解除待ち" ){
            $A.util.toggleClass(component.find("mySpinner"),"slds-hide");
            component.set("v.simpleNewAgreement.ApprovalStatus__c","申請提出");
            component.find("AgreementEditor").saveRecord(function(saveResult) {
            	var resultsToast = $A.get("e.force:showToast");
            	if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
            		// record is saved successfully
            		resultsToast.setParams({
            			"title": "承認申請成功",
            			"message": "承認申請しました。",
            			"type":"success"
            		});
            		resultsToast.fire();
            		$A.get("e.force:closeQuickAction").fire();
            		$A.get('e.force:refreshView').fire();
            	} else if (saveResult.state === "INCOMPLETE") {
            		// handle the incomplete state
            		console.log("User is offline, device doesn't support drafts.");
            	} else if (saveResult.state === "ERROR") {
            		$A.util.toggleClass(component.find("mySpinner"),"slds-hide");
            		// handle the error state
            		console.log('Problem saving Agreement, error: ' + 
            				JSON.stringify(saveResult.error));
            		console.log(saveResult.error);
            		component.set("v.errorMessage",saveResult.error[0].message);
            	} else {
            		console.log('Unknown problem, state: ' + saveResult.state +
            				', error: ' + JSON.stringify(saveResult.error));
            		component.set("v.errorMessage",saveResult.error[0].message);
            	}
            });
        }else{
            var errorMessage = "契約更新済、または契約解除待ちの更新のみ、返金処理ができます。";
            helper.showError(component,errorMessage);
            $A.get("e.force:closeQuickAction").fire();
            return;
        }	
    },
    
    /** 
     * 保証金関連金額変更の場合
     */
    caculateSumData : function(component, event, helper) {
        //保証金
        var Hoshokin = component.get("v.simpleNewAgreement.Hoshokin__c");
        //残存ﾘｰｽ料
        var ZanzonLeaseAmount = component.get("v.simpleNewAgreement.ZanzonLeaseAmount__c");
        //買取商品金額(集計)
        var ProductKaitoriAmnout = component.get("v.simpleNewAgreement.ProductKaitoriAmnout__c");
        //買取商品金額消費税
        var ProductKaitoriTax = component.get("v.simpleNewAgreement.ProductKaitoriTax__c");
        //(保証金返金)ダメージ料金
        var damageMoney = component.get("v.simpleNewAgreement.damageMoney__c");
        //(保証金返金)個別送料
        var DeliveryFee = component.get("v.simpleNewAgreement.DeliveryFee__c");
        //(保証金返金)その他料金
        var OthersFee = component.get("v.simpleNewAgreement.OthersFee__c");
        //(保証金返金)過入金
        var OverPaymentAmount = component.get("v.simpleNewAgreement.OverPaymentAmount__c");
        
        //(保証金返金)差引
        var TotalFee = ZanzonLeaseAmount + ProductKaitoriAmnout + ProductKaitoriTax + damageMoney + DeliveryFee + OthersFee;
        component.set("v.simpleNewAgreement.TotalFee__c",TotalFee);
        //(保証金返金)返金金額
        if (component.get("v.simpleNewAgreement.NextProductUpdCnt__c") == 0) {
            if (component.get("v.simpleNewAgreement.HoshokinSousai__c") == "希望しない") {
                component.set("v.simpleNewAgreement.HenkinAmount__c",Hoshokin + OverPaymentAmount);
            } else {
                component.set("v.simpleNewAgreement.HenkinAmount__c",Hoshokin - TotalFee + OverPaymentAmount > 0 ? Hoshokin - TotalFee + OverPaymentAmount : 0);
            }
        }
        //(保証金返金)不足請求金額
        if (component.get("v.simpleNewAgreement.NextProductUpdCnt__c") > 0 || component.get("v.simpleNewAgreement.HoshokinSousai__c") == "希望しない") {
            component.set("v.simpleNewAgreement.FusokuAmount__c",TotalFee);
        } else {
            component.set("v.simpleNewAgreement.FusokuAmount__c",Hoshokin - TotalFee + OverPaymentAmount > 0 ? 0 : Math.abs(Hoshokin - TotalFee + OverPaymentAmount));
        }
    },
    
    close:function(component,event,helper){
        $A.get("e.force:closeQuickAction").fire();
    },
})