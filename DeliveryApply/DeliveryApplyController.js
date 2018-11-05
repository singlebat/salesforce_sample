({
	doInit : function(component, event, helper) {
        
	},
	
	/** 
     * モデルを開いている時
     */
    deliveryApply : function(component, event, helper) {
        if(!component.get("v.showModal")){
            return;
        }
        console.log(component.get("v.objectName"));
        console.log("Start");
        var productList ;
        var id;
        if (component.get("v.objectName") == 'Agreement__c') {
            productList = component.get("v.invOppProductList");
            id = productList[0].Agreement__c;
        } else {
            productList = component.get("v.productList");
            id = productList[0].Estimates__c;
        }
        
        var action = component.get("c.getDeliverys");
        //パラメータ設定
        action.setParams({
        	"id": id,
        	"sObjectName": component.get("v.objectName")
        });
        $A.enqueueAction(action);
        action.setCallback(this, function(res) {
        	var state = res.getState();
        	if (state == "SUCCESS") {
        		component.set("v.options",res.getReturnValue());
        		component.set("v.optionsvalue",res.getReturnValue()[0].value);
        	} else {
        		var resultsToast = $A.get("e.force:showToast");
        		resultsToast.setParams({
        			"title": "配送情報を取得失敗",
        			"message": "予想外のエラーを発生するために、管理者に連絡ください。",
        			"type":"error"
        		});
        		resultsToast.fire();
        	}
        });
        
        //モデルを開く
        helper.openModal(component);
    },
    
    /** 
     * モデルを開いている時
     */
    doNext : function(component, event, helper) {
    	if (component.get("v.optionsvalue") == "new") {
            component.set("v.deliveryDate","");
    		component.set("v.customersRemarks","");
    	} else {
    		var action = component.get("c.getDeliveryInfo");
    		//パラメータ設定
    		action.setParams({
    			"deliveryId": component.get("v.optionsvalue")
    		});
    		$A.enqueueAction(action);
    		action.setCallback(this, function(res) {
    			var state = res.getState();
    			if (state == "SUCCESS") {
    				component.set("v.deliveryDate",res.getReturnValue().DeliveryPrepareDay__c);
    				component.set("v.customersRemarks",res.getReturnValue().CustomersRemarks__c);
    			} else {
    				var resultsToast = $A.get("e.force:showToast");
    				resultsToast.setParams({
    					"title": "システムエラー",
    					"message": "予想外のエラーを発生するために、管理者に連絡ください。",
    					"type":"error"
    				});
    				resultsToast.fire();
    			}
    		});
    	}
    	component.set("v.step1",false);
    	component.set("v.step2",true);
    },
    
    /** 
     * モデルを開いている時
     */
    doBack : function(component, event, helper) {
        component.set("v.step1",true);
        component.set("v.step2",false);
    },
    
    /** 
     * キャンセルボタン或は「✖」をクリック
     */
    close : function(component, event, helper) {
        helper.closeModal(component);
    },
    
    /** 
     * 配送作成
     */
    doDelivery : function(component, event, helper) {
        var productList;
    	var action ;
    	if (component.get("v.objectName") == "Agreement__c") {
    	    action = component.get("c.createDeliveryOut");
    	    productList = component.get("v.invOppProductList");
    	} else {
    	    action = component.get("c.createDeliveryIn");
    	    productList = component.get("v.productList");
    	}
    	
    	//パラメータ設定
    	action.setParams({
    		"productList": productList,
    		"typeId":component.get("v.optionsvalue"),
    		"deliveryDate":component.get("v.deliveryDate"),
    		"customersRemarks":component.get("v.customersRemarks"),
    		"welcomekit":component.get("v.welcomekit"),
    		"tachiaiPerson":component.get("v.delivery.TachiaiPerson__c")
    	});
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
    		var state = res.getState();
    		var resultsToast = $A.get("e.force:showToast");
    		if (state == "SUCCESS") {
    			resultsToast.setParams({
    				"title": "配送依頼成功",
    				"message": "配送依頼完了しました。",
    				"type":"success"
    			});
    			var navEvt = $A.get("e.force:navigateToSObject");
	            navEvt.setParams({
	                            "recordId": res.getReturnValue(),
	                            "slideDevName": "detail"
	            });
	            navEvt.fire();
    		} else {
    			resultsToast.setParams({
    				"title": "配送依頼失敗",
    				"message": "予想外のエラーを発生するために、管理者に連絡ください。",
    				"type":"error"
    			});
    		}
    		resultsToast.fire();
    	});
        helper.closeModal(component);
    },
})