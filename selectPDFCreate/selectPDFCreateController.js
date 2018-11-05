({
    /** 
     * 初期化処理
     */
    doInit: function(component, event, helper) {
    	var action = component.get("c.getInitInfo");
    	//パラメータ設定
    	action.setParams({
    		"Id": component.get("v.recordId"),
    		"sobName":component.get("v.sObjectName")
    	});

    	action.setCallback(this, function(res) {
    		if(component.isValid() && res.getState() === "SUCCESS"){
    			if(component.get("v.sObjectName")== "Estimate__c"){
    				var result = res.getReturnValue().ec;
    				console.log(result);
    				component.set("v.estimate",result);
    				component.set("v.QuotationStatus",result.QuotationStatus__c);
    				component.set("v.modelNumberHide",result.ModelNumberHide__c);
    				component.set("v.truckCancelHide",result.TruckCancelFlag__c);
    				component.set("v.newAgreemntHide",result.NewAgreemntFlag__c);
    				component.set("v.hatyuNyukinHide",result.HatyuNyukinFlag__c);
    				component.set("v.furikomiKozaHide",result.FurikomiKozaFlag__c);
                    if(result.EstimateLanguage__c != null){
    			        component.set("v.languagesValue",result.EstimateLanguage__c);
    			    }
    			    component.set("v.MonthlyPrintFlag",result.MonthlyPrintFlag__c);
    			}else{
    				var result = res.getReturnValue().ag;
    				if(result.Estimate__r.EstimateLanguage__c != null){
    			        component.set("v.languagesValue",result.Estimate__r.EstimateLanguage__c);
    			    }
    			    component.set("v.MonthlyPrintFlag",result.Estimate__r.MonthlyPrintFlag__c);
    			}
    		}else{
    			var toastEvent = $A.get("e.force:showToast");
    			toastEvent.setParams({
    				"title": "エラー!",
    				"message": "管理者にご連絡ください．",
    				"type":"error"
    			});
    			toastEvent.fire();
    		}
    	});

    	//メソッド実行
    	$A.enqueueAction(action);
    },
    
    /** 
     * モデルを開いている時
     */
    doNext : function(component, event, helper) {
        component.set("v.step1",false);
        component.set("v.step2",true);
        
        if (component.get("v.sObjectName") == "Estimate__c") {
        	if (component.get("v.value") == "Mitsumoridepend") {
        		component.set("v.pdfLable","納期確認及び見積依頼書");
        	} else if (component.get("v.value") == "Order") {
        		component.set("v.pdfLable","注文書兼注文請書");
        	} else if (component.get("v.value") == "Mitsumori") {
        		component.set("v.pdfLable","御見積書");
        	} else if (component.get("v.value") == "Invoice") {
        		component.set("v.pdfLable","請求書");
        	} 

        	if (component.get("v.value") == "Mitsumoridepend" || component.get("v.value") == "Order") {
        		//見積に関連する仕入を検索
        		var action = component.get("c.getPurchaseById");
        		action.setParams({
        			"Id": component.get("v.recordId")
        		});

        		action.setCallback(this,function(res){
        			if(component.isValid() && res.getState() === "SUCCESS"){
        				var result = res.getReturnValue();
        				console.log(result);
        				component.set("v.purchaseList",result);
        			}else{
        				var toastEvent = $A.get("e.force:showToast");
        				toastEvent.setParams({
        					"title": "エラー!",
        					"message": "管理者にご連絡ください．",
        					"type":"error"
        				});
        				toastEvent.fire();
        			}
        		})
        		$A.enqueueAction(action);
        	}
        } else {
            if (component.get("v.contractPDFValue") == "Kaiyaku") {
        		component.set("v.pdfLable","解約精算確認書");
        		//更新情報を検索
        		var action = component.get("c.getAgreementById");
        		action.setParams({
        			"id": component.get("v.recordId")
        		});

        		action.setCallback(this,function(res){
        			if(component.isValid() && res.getState() === "SUCCESS"){
        				var result = res.getReturnValue();
        				console.log(result);
        				component.set("v.agreement",result);
        				component.set("v.PaymentDetails",result.rel_PaymentDetails__r);
        				if (component.get("v.agreement.NyukinKiaknEndDate__c") != null) {
                            helper.changeNyukinKiaknEndDateMain(component);
                        }
        			}else{
        				var toastEvent = $A.get("e.force:showToast");
        				toastEvent.setParams({
        					"title": "エラー!",
        					"message": "管理者にご連絡ください．",
        					"type":"error"
        				});
        				toastEvent.fire();
        			}
        		})
        		$A.enqueueAction(action);
        	}
        }
    },
    
    /** 
     * モデルを開いている時
     */
    doBack : function(component, event, helper) {
        component.set("v.step1",true);
        component.set("v.step2",false);
    },
    
    /** 
     * 印刷
     */
    print: function(component, event, helper) {
    	console.log('選択された帳票種類は' + component.get("v.sObjectName"));
    	var pdfType = "";
    	if (component.get("v.sObjectName") == "Estimate__c") {
    	    pdfType = component.get("v.value");
    	} else {
    	    pdfType = component.get("v.contractPDFValue");
    	}
    	console.log("pdfType:::" + pdfType);
    	
    	var language=component.get("v.languagesValue");
    	if($A.util.isEmpty(component.get("v.languagesValue"))){
    		component.set("v.errorMessage","帳票の言語を選択してください。");
	        return ;
    	}

	    var action;
	    $A.util.toggleClass(component.find("mySpinner"),"slds-hide");
    	if (component.get("v.step2") && (pdfType == "Mitsumoridepend" || pdfType == "Order") && component.get("v.sObjectName") == "Estimate__c") {
	    	console.log("納期確認及び見積依頼書 或は 注文書　印刷");
	    	if (component.get("v.estimate.ApprovalStatus__c") == "申請提出") {
        	    component.set("v.errorMessage","承認中の見積が納期確認及び見積依頼書 或は 注文書を印刷できません。");
        		$A.util.toggleClass(component.find("mySpinner"),"slds-hide");
        	} else {
        		var purchaseList = component.get("v.purchaseList");
        		var purchaseSelectList = new Array();
        		for (var i = 0 ; i < purchaseList.length ; i++) {
        			if (purchaseList[i].selectedFlg) {
        				if (component.get("v.value") == "Order" && $A.util.isEmpty(purchaseList[i].purchaseObj.DeliveryTime2__c)) {
        					component.set("v.errorMessage","納品日を入力してください。");
        					$A.util.toggleClass(component.find("mySpinner"),"slds-hide");
        					return ;
        				}
        				purchaseSelectList.push(purchaseList[i].purchaseObj);
        			}
        		}
        		//納期確認及び見積依頼書 或は 注文書　印刷
        		action = component.get("c.updPurchaseList");
        		action.setParams({
        			"purchaseList": purchaseSelectList,
        			"pdfType": pdfType,
        			"id": component.get("v.recordId"),
        			"language":language
        		});
        		//印刷actionを実行する
        		helper.executePrint(action,component);
        	}
        }else if(pdfType == "Invoice"){
        	console.log("請求書　印刷："+component.get("v.QuotationStatus"));         
        	if(component.get("v.QuotationStatus") != "契約済" && component.get("v.QuotationStatus") != "成約"){
        		component.set("v.errorMessage","成約処理済または契約済の状態、請求書が印刷できます");
        		$A.util.toggleClass(component.find("mySpinner"),"slds-hide");
        	} else if (!component.get("v.MonthlyPrintFlag")) {
        	    component.set("v.errorMessage","初回請求作成できません。手動で初回請求作成フラグを更新すると、印刷できます。");
        		$A.util.toggleClass(component.find("mySpinner"),"slds-hide");
        	} else {
        		//請求・請求明細(リース、販売)を作成
        		var firstAction = component.get("c.createBillDetail");
        		firstAction.setParams({
        			"sObjectName":component.get("v.sObjectName"),
        			"id": component.get("v.recordId")
        		});
        		firstAction.setCallback(this, function(response) {
        			var state = response.getState();
        			if(state == "SUCCESS"){
        				//PDFを作成
        				action = component.get("c.createInvoicePDF");
        				action.setParams({
        					"sObjectName":component.get("v.sObjectName"),
        					"id": component.get("v.recordId"),
        					"language":language
        				});
        				//印刷actionを実行する 
        				helper.executePrint(action,component);
        			} else {
        				helper.showError(component,"請求明細作成失敗のため、エラーを発生する。");
        			}
        		});
        		$A.enqueueAction(firstAction);
        	}
        } else if(pdfType == "Mitsumori"){
            console.log("見積書　印刷");
	        var firstAction = component.get("c.updateForMitumoriPDF");
	        firstAction.setParams({
	    		"id": component.get("v.recordId"), 
	    		"linkedId":component.get("v.recordId"),
	    		"modelNumberHide":component.get("v.modelNumberHide"),
	    		"truckCancelHide":component.get("v.truckCancelHide"),
	    		"newAgreemntHide":component.get("v.newAgreemntHide"),
	    		"hatyuNyukinHide":component.get("v.hatyuNyukinHide"),
	    		"furikomiKozaHide":component.get("v.furikomiKozaHide"),
	    		"language":language
	    	});
	    	firstAction.setCallback(this, function(response) {
	    		var state = response.getState();
	    		console.log(state);
	    		if(state == "SUCCESS"){
	    			action = component.get("c.createMitumoriPDF");
	    			action.setParams({
	    				"id": component.get("v.recordId"), 
	    				"linkedId":component.get("v.recordId")
	    			});
	    			//印刷actionを実行する 
	    			helper.executePrint(action,component);
	    		} else {
	    			helper.showError(component,"見積更新のエラー");
	    		}
	    	});
	    	$A.enqueueAction(firstAction);
        } else if(pdfType == "Kaiyaku"){
        	console.log("解約精算確認書　印刷");
        	var firstAction = component.get("c.updateForKaiyakuPDF");
        	firstAction.setParams({
        		"agreement":component.get("v.agreement"),
        		"language":language
        	});
        	firstAction.setCallback(this, function(response) {
        		var state = response.getState();
        		console.log(state);
        		if(state == "SUCCESS"){
        			action = component.get("c.createKaiyakuOrLTConfirmPDF");
        			action.setParams({
        				"aggrementId": component.get("v.recordId"), 
        				"linkedId":component.get("v.recordId"),
        				"pdfType":pdfType,
        				"language":language
        			});
        			//印刷actionを実行する 
        			helper.executePrint(action,component);
        		}else if (state == "ERROR") {
        			helper.showError(component,"解約精算確認書を印刷前に、契約更新でエラーを発生する。");
        		}
        	});
        	$A.enqueueAction(firstAction);
        } else if(pdfType == "LeaseTermConfirm"){
            console.log("リース満了期間通知書　印刷");
	        var firstAction = component.get("c.updateForLeaseTermConfirmPDF");
	        firstAction.setParams({
	    		"id": component.get("v.recordId"),
	    		"language":language,
	    		"updateFlg":component.get("v.updateFlg")
	    	});
	    	firstAction.setCallback(this, function(response) {
		    		var state = response.getState();
		    		if(state == "SUCCESS"){
		    			action = component.get("c.createKaiyakuOrLTConfirmPDF");
		    			action.setParams({
		    				"aggrementId": component.get("v.recordId"), 
		    				"linkedId":component.get("v.recordId"),
		    				"pdfType":pdfType,
		    				"language":language
		    			});
		    			//印刷actionを実行する 
		    			helper.executePrint(action,component);
		    		}else if (state == "ERROR") {
		    			helper.showError(component,"リース満了期間通知書を印刷前に、契約更新でエラーを発生する。");
		    		}
		    	});
	    	$A.enqueueAction(firstAction);
	    	return ;
        } else if(pdfType == "Shiharai"){
            console.log("支払予定明細　印刷");
	        //支払予定明細　印刷
	        var firstAction = component.get("c.createPaymentDetailsForShiharaiPDF");
	        firstAction.setParams({
	    		"id": component.get("v.estimate").Estimate__r[0].Id, 
	    		"language":language
	    	});
	    	firstAction.setCallback(this, function(response) {
		    		var state = response.getState();
		    		console.log(state);
		    		var toastEvent = $A.get("e.force:showToast");
		    		if(state == "SUCCESS"){
		    			action = component.get("c.createShiharaiPDF");
		    			action.setParams({
				        	"aggrementId": component.get("v.estimate").Estimate__r[0].Id, 
				    		"linkedId":component.get("v.recordId"),
				    		"pdfType":pdfType,
				    		"language":language
				    	});
				    	//印刷actionを実行する 
		    			helper.executePrint(action,component);
		    		}else if (state == "ERROR") {
		    			helper.showError(component,"支払予定明細を印刷前に、支払予定明細作成の時エラーを発生する。");
		    		}
		    	});
	    	$A.enqueueAction(firstAction);
        } else {
            var id = "";
            if (component.get("v.sObjectName") == "Estimate__c") {
                id = component.get("v.estimate").Estimate__r[0].Id;
            } else {
                id = component.get("v.recordId");
            }
    		//言語より、印刷actionを決定する 
    		if(language=="日本語"){
    		    action = component.get("c.savePDFCommon");
    		}else{
    			action = component.get("c.savePDFENGCommon");
    		}
    		
	    	action.setParams({
	    		"id": id, 
	    		"pdfType": pdfType,
	    		"linkedId":component.get("v.recordId")
	    	});
	    	console.log(pdfType);
	    	//印刷actionを実行する 
		    helper.executePrint(action,component);
    	}
    },
    
    /** 
     * 仕入先全選択/解除
     */
    checkAll:function(component,event,helper){
        var flg  = component.get("v.allCheck");
        var purchaseList   = component.get("v.purchaseList");
        for (var j = 0 ; j < purchaseList.length ; j++) {
            purchaseList[j].selectedFlg = flg;
        }
        component.set("v.purchaseList",purchaseList);
    },
    
    /** 
     *解約日変わるの場合、解約日より、入金期間終了日を算出する。
     */
    changeKaiyakuDate:function(component,event,helper){
        helper.changeKaiyakuDateMain(component);
    },
    
    /** 
     *入金期間終了日を変わるの場合、入金期間終了日までに入金済金額を算出する。
     */
    changeNyukinKiaknEndDate:function(component,event,helper){
        console.log(component.get("v.agreement.NyukinKiaknEndDate__c"));
        if (component.get("v.agreement.NyukinKiaknEndDate__c") != null) {
            helper.changeNyukinKiaknEndDateMain(component);
        }
    }, 
})