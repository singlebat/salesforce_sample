({	
	/** 
     * メイン検索処理
     */ 
    mainSearch: function(component,categoryName) {
        //カテゴリー変わるとき、条件をクリア
        if (component.get("v.oldCategory") != null && component.get("v.oldCategory") != '') {
            var oldCategory = component.get("v.oldCategory").split(' > ');
            var newCategory = component.get("v.category").split(' > ');
            if (oldCategory[0] != newCategory[0]) {
                //クリア処理
                this.conditionClear(component);
                component.set("v.category",categoryName);
            }
        }
        var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
        
        //入庫予定日チェック処理
        var nyukoyoteibiLowerLimit = component.get("v.searchCondition.nyukoyoteibiLowerLimit");
        var nyukoyoteibiUpLimit = component.get("v.searchCondition.nyukoyoteibiUpLimit");
        if (!this.dateCheck(nyukoyoteibiLowerLimit) || !this.dateCheck(nyukoyoteibiUpLimit)) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                        "title": "入庫予定日エラー",
                        "message": "入庫予定日 開始日 或は 入庫予定日 終了日が正しくありません。改めて入力してください。",
                        "type":"warning"
                    });
                    toastEvent.fire();
            $A.util.toggleClass(spinner, "slds-hide");
            return;
        }
        
        //呼び出すメソッドを定義する
        var action = component.get("c.searchInventoryProduct");
        //パラメータ設定
        action.setParams({
                         "categoryName": categoryName,
                         "conditionArea": JSON.stringify(component.get("v.searchCondition")),
                         "currentStatus": component.get("v.currentStatusValue"),
                         "rank": component.get("v.rankValue")
                         });
        //メソッド実行
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
            var state = res.getState();
            $A.util.toggleClass(spinner, "slds-hide");
            if (state == "SUCCESS") {
                if (res.getReturnValue() == null || res.getReturnValue().length == 0) {
                    component.set("v.InventoryProductDetailList", []);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "商品なし",
                        "message": "在庫商品がありません。",
                        "type":"warning"
                    });
                    toastEvent.fire();
                } else {
                     component.set("v.InventoryProductDetailList", res.getReturnValue());
                }
            } else if (state == "ERROR") {
                component.set("v.InventoryProductDetailList", []);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "システムエラー",
                    "message": "在庫商品検索失敗、システム管理者に連絡ください。",
                    "type":"error"
                });
                toastEvent.fire();
            }
        });	
    },
    
    /** 
     * 切替より商品登録
     */ 
    createProduct : function (component, InventoryProductDetailList,index) {
        var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
        var toastEvent = $A.get("e.force:showToast");
        var action = component.get("c.productSelected");
        action.setParams({
                         "inventoryProductObj": JSON.stringify(InventoryProductDetailList[index]),
                         "estimatecId": component.get("v.estimatecId"),
                         });
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
            var state = res.getState();
            $A.util.toggleClass(spinner, "slds-hide");
            if (state == "SUCCESS") {
                if (res.getReturnValue() != null) {
                    var result = res.getReturnValue();
                    console.log(result);
                    for (var i = 0 ; i < result.length ; i++) {
                        for (var j = 0 ; j < InventoryProductDetailList.length ; j++) {
                            if (InventoryProductDetailList[j].ID == result[i].InventoryProduct__c) {
                                InventoryProductDetailList[j].opportunityProductID = result[i].OpportunityProduct__c;
                                InventoryProductDetailList[j].selectKBN = true;
                                break;
                            }
                        }
                    }
                    //InventoryProductDetailList[index].opportunityProductID = res.getReturnValue();
                    //InventoryProductDetailList[index].selectKBN = true;
                    component.set("v.InventoryProductDetailList", InventoryProductDetailList);
                    toastEvent.setParams({
                        "title": "選択成功!",
                        "message": "商品登録成功",
                        "type":"success"
                    });
                    toastEvent.fire();
                } else {
                    toastEvent.setParams({
                        "title": "選択失敗",
                        "message": "他の人は既にこの商品を選択しました。",
                        "type":"error"
                    });
                    toastEvent.fire();
                }
            } else if (state === "ERROR") {	
                toastEvent.setParams({
                    "title": "保存失敗",
                    "message": "システム管理者を連絡ください。",
                    "type":"error"
                });
                toastEvent.fire();
            }
        });
    },
    
    /** 
     * 切替より商品削除
     */ 
    deleteProduct : function (component, InventoryProductDetailList,index) {
        var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
        var toastEvent = $A.get("e.force:showToast");
        var action = component.get("c.deleteProduct");
        action.setParams({
                         "inventoryProductObj": JSON.stringify(InventoryProductDetailList[index]),
                         "estimatecId": component.get("v.estimatecId"),
                         });
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
            var state = res.getState();
            $A.util.toggleClass(spinner, "slds-hide");
            if (state == "SUCCESS") {
                if (InventoryProductDetailList[index].setNo != null && InventoryProductDetailList[index].setNo != "") {
                    for (var j = 0 ; j < InventoryProductDetailList.length ; j++) {
                        if (InventoryProductDetailList[j].setNo == InventoryProductDetailList[index].setNo) {
                        	InventoryProductDetailList[j].opportunityProductID = null;
                        	InventoryProductDetailList[j].selectKBN = false;
                        }
                    }
                } else {
                    InventoryProductDetailList[index].opportunityProductID = null;
                    InventoryProductDetailList[index].selectKBN = false;
                }
                //InventoryProductDetailList[index].opportunityProductID = null;
                //InventoryProductDetailList[index].selectKBN = false;
                component.set("v.InventoryProductDetailList", InventoryProductDetailList);
            } else if (state === "ERROR") {	
                toastEvent.setParams({
                    "title": "保存失敗",
                    "message": "システム管理者を連絡ください。",
                    "type":"error"
                });
                toastEvent.fire();
            }
        });
    },
    
    /** 
     *クリア処理
     */ 
    conditionClear: function(component) {
    	component.set("v.searchCondition.priceLowerLimit", null);    //価値価格帯下限
    	component.set("v.searchCondition.priceUpLimit", null);       //価値価格帯上限
    	component.set("v.searchCondition.depthLowerLimit", null);    //奥下限
    	component.set("v.searchCondition.depthUpLimit", null);       //奥上限
    	component.set("v.searchCondition.widthLowerLimit", null);    //幅下限
    	component.set("v.searchCondition.widthUpLimit", null);       //幅上限
    	component.set("v.searchCondition.heightLowerLimit", null);   //高さ下限
    	component.set("v.searchCondition.heightUpLimit", null);      //高さ上限
    	component.set("v.searchCondition.nyukoyoteibiLowerLimit", null);    //入庫予定日下限
    	component.set("v.searchCondition.nyukoyoteibiUpLimit", null);       //入庫予定日上限
    	component.set("v.searchCondition.shortTerm", false);                //短期かどうか
    	component.set("v.searchCondition.searchBar", '');                   //検索サーチバー
    	var ary = new Array();
    	component.set("v.currentStatusValue",ary);    //現状区分
    	component.set("v.rankValue",ary);             //ランク
    	component.set("v.category",null);             //カテゴリー
    	component.set("v.mediumTypes",null);          //カテゴリー中分類
    	component.set("v.smallTypes", null);          //カテゴリー小分類
    	component.set("v.oldCategory",null);          //前回選択されたカテゴリー
    	component.set("v.InventoryProductDetailList", []);    //在庫商品明細リスト

    },
    
    /** 
     * 日付チェック
     */ 
    dateCheck: function(datestr) {
        if (datestr != null && datestr.trim() != '') {
            if(!datestr.trim().match(/^\d{4}\/\d{2}\/\d{2}$/) && !datestr.match(/^\d{4}\-\d{2}\-\d{2}$/)){
                return false;
            }
            var vYear = datestr.substr(0, 4) - 0;
            var vMonth = datestr.substr(5, 2) - 1; // Javascriptは、0-11で表現
            var vDay = datestr.substr(8, 2) - 0;
        
            if(vMonth >= 0 && vMonth <= 11 && vDay >= 1 && vDay <= 31){
                var vDt = new Date(vYear, vMonth, vDay);
                if(isNaN(vDt)){
                    return false;
                }else if(vDt.getFullYear() == vYear && vDt.getMonth() == vMonth && vDt.getDate() == vDay){
                    return true;
                }else{
                    return false;
                }
            }else{
                return false;
            }
        }            
        
        return true;
    },
    
    /** 
     * Package商品に、商品を追加
     */
    createPackageProduct:function(component, InventoryProductDetailList, index){
        var toastEvent = $A.get("e.force:showToast");
        var action = component.get("c.doCreatePackageProduct");
        action.setParams({
                         "inventoryProductObj": JSON.stringify(InventoryProductDetailList[index]),
                         "invProduct": component.get("v.invProduct")
                         });
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
            var state = res.getState();	
            if (state == "SUCCESS") {
                toastEvent.setParams({
                    "title": "選択成功!",
                    "message": "Package商品を登録しました。",
                    "type":"success"
                });
                toastEvent.fire();
                InventoryProductDetailList[index].selectKBN = true;
                component.set("v.InventoryProductDetailList", InventoryProductDetailList);
            } else if (state === "ERROR") {
                toastEvent.setParams({
                    "title": "システムエラー",
                    "message": "システム管理者を連絡ください。",
                    "type":"error"
                });
                toastEvent.fire();
            }
        });
    },
    
    /** 
     * Package商品から、選択された商品を削除
     */
    deletePackageProduct:function(component, InventoryProductDetailList, index){
        var toastEvent = $A.get("e.force:showToast");
        var action = component.get("c.doDeletePackageProduct");
        action.setParams({
                         "inventoryProductObj": JSON.stringify(InventoryProductDetailList[index])
                         });
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
            var state = res.getState();	
            if (state == "SUCCESS") {
                toastEvent.setParams({
                    "title": "取消成功!",
                    "message": "Package商品から削除しました。",
                    "type":"success"
                });
                toastEvent.fire();
                InventoryProductDetailList[index].selectKBN = false;
                component.set("v.InventoryProductDetailList", InventoryProductDetailList);
            } else if (state === "ERROR") {
                toastEvent.setParams({
                    "title": "システムエラー",
                    "message": "システム管理者を連絡ください。",
                    "type":"error"
                });
                toastEvent.fire();
            }
        });
    },
})