({
    showMessage : function(component,title,message,type) {
    	var resultsToast = $A.get("e.force:showToast");
    	resultsToast.setParams({
    		"title": title,
    		"message": message,
    		"type":type
    	});
    	resultsToast.fire();
	},
	
	getInvOppProductMain : function(component) {
	    var action = component.get("c.getInitInfo");
        action.setParams({
                          "Id":component.get("v.recordId"),
                          "sObjectName":component.get("v.sObjectName")
                        });
        action.setCallback(this,function(res){
            if(component.isValid() && res.getState() === "SUCCESS"){
                var result = res.getReturnValue();
                console.log(result);
                component.set("v.invOppProductList",result.invOppProducts);
                if (component.get("v.sObjectName") == "Agreement__c") {
                    component.set("v.agreement",result.agreement);
                    component.set("v.deleteFlag",result.deleteFlag);
                }
            }else{
                this.showMessage(component,"エラー!","管理者にご連絡ください．","error");
            }
        })
        $A.enqueueAction(action);
	},
	
	changeAllcheck : function(component,event,helper){
	    var flg  = component.get("v.checkFlag");
        var invOppProductList   = component.get("v.invOppProductList");
        for (var j = 0 ; j < invOppProductList.length ; j++) {
            if (component.get("v.sObjectName") == 'Purchase__c' && invOppProductList[j].invOppProduct.Status__c == "在庫") {
                invOppProductList[j].selectedFlg = false;
            } else {
                invOppProductList[j].selectedFlg = flg;
            }
        }
        component.set("v.invOppProductList",invOppProductList);
	},
	
    /** 
     * 仕入におてい入庫、配送において出庫準備完了、配送においてD/L（搬入）完了メイン処理。
     */
    combinedMain : function(component, type){
    	if(confirm("商品を" + type + "して、よろしいでしょうか？")){
    		$A.util.toggleClass(component.find("mySpinner"),"slds-hide");
    		var invOppProductList   = component.get("v.invOppProductList");
    		var toastEvent = $A.get("e.force:showToast");
    		var selectedProducts = new Array();
    		var error = "";
    		var DeliveryType = invOppProductList[0].invOppProduct.Haisou__r.DeliveryType__c;
    		for (var j = 0 ; j < invOppProductList.length ; j++) {
    			if (invOppProductList[j].selectedFlg) {
    				if (type == "出庫準備完了" && (invOppProductList[j].invOppProduct.Status__c != "在庫" && invOppProductList[j].invOppProduct.ProductFlag__c)) {
    					error = "在庫のみ商品を出庫準備完了できますので、ご確認をお願いします。";
    					break;
    				} else if (DeliveryType == "搬入" && type == "配送" && invOppProductList[j].invOppProduct.Status__c != "出庫準備完了") {
    					error = "出庫準備完了商品を配送できますので、ご確認をお願いします。";
    					break;
    				}
    				selectedProducts.push(invOppProductList[j].invOppProduct);
    			}
    		}
    		if ( error != "") {
    			console.log("error:::" + error);
    			this.showMessage(component,type + "失敗",error,"warning");
    			$A.util.toggleClass(component.find("mySpinner"),"slds-hide");
    			return;
    		}
    		if ( selectedProducts.length == 0) {
    			this.showMessage(component,type + "失敗","商品を選択してください。","warning");
    			$A.util.toggleClass(component.find("mySpinner"),"slds-hide");
    			return;
    		}
    		var action;
    		if (type == "入庫") {
    			action = component.get("c.storing");
    		} else if (type == "出庫準備完了") {
    			action = component.get("c.deliveryTehai");
    		} else if (type == "配送") {
    			action = component.get("c.delivery");
    		} else if (type == "メンテ済") {
    			action = component.get("c.deliveryRepair");
    		}
    		//パラメータ設定
    		action.setParams({
    			"id": component.get("v.recordId"), 
    			"invOppProducts":selectedProducts
    		});
    		//メソッド実行
    		$A.enqueueAction(action);
    		action.setCallback(this, function(res) {
    			var state = res.getState();
                component.set("v.checkFlag",false);
    			if (state == "SUCCESS") {
    				this.showMessage(component,type + "成功","選択された商品を" + type + "完了しました。","success");
    				//$A.get('e.force:refreshView').fire();
    				this.getInvOppProductMain(component);
    			} else {
    				this.showMessage(component,"システムエラー","予想外のエラーを発生するため、システム管理者に連絡ください。","error");
    			}
    			$A.util.toggleClass(component.find("mySpinner"),"slds-hide");
    		});
    	}
    },
    
    /** 
     * 買取ボタン或は除却ボタンを押して、商品一覧を保存する。
     */
    salesDeleteMain:function(component,type){
        var toastEvent = $A.get("e.force:showToast");
        var ProductList = new Array();
        var invOppProductList   = component.get("v.invOppProductList");
        for (var j = 0 ; j < invOppProductList.length ; j++) {
        	if (type != "") {
        		if (invOppProductList[j].selectedFlg == true) {
        			invOppProductList[j].invOppProduct.Status__c = type;
        			ProductList.push(invOppProductList[j].invOppProduct);
        		}
        	} else {
                ProductList.push(invOppProductList[j].invOppProduct);
        	}
        }
        var action = component.get("c.updateInvOppProduct");
        $A.util.toggleClass(component.find("mySpinner"),"slds-hide");
        action.setParams({
                          "invOppProductList":ProductList,
                          "id": component.get("v.recordId"), 
                          "KBN":type
                         });
        action.setCallback(this,function(res){
            $A.util.toggleClass(component.find("mySpinner"),"slds-hide");
            if(component.isValid() && res.getState() === "SUCCESS"){
                component.set("v.checkFlag",false);
                this.showMessage(component,"更新成功","更新成功しました","success");
                //$A.get('e.force:refreshView').fire();
                this.getInvOppProductMain(component);
            }else{
                this.showMessage(component,"エラー!","管理者にご連絡ください。","error");
            }
        })
        $A.enqueueAction(action);
    },
})