({
    /** 
     * 初期化処理
     */ 
    doInit : function(component, event, helper) {
        //呼び出すメソッドを定義する
        var action = component.get("c.initAction");
        //メソッド実行
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {//アクションの完了処理
    	    //var spinner = component.find("mySpinner");
            //$A.util.toggleClass(spinner, "slds-hide");
    	    var state = res.getState();	
    	    component.set("v.InventoryProductDetailList", []);
            if (state == "SUCCESS") {//処理正常の場合
                //検索条件部分初期化処理
                component.set("v.searchCondition", res.getReturnValue().conditionArea);
                component.set("v.rank", res.getReturnValue().conditionArea.rank);
                component.set("v.packageProductOpts", res.getReturnValue().packageProductMasters);
                component.set("v.productMasterId", res.getReturnValue().packageProductMasters[0].value);
                //カテゴリー設定
                component.set("v.bigTypeList", res.getReturnValue().bigTypeList);
                //カテゴリー検索欄の高さを設定する
                if (res.getReturnValue().bigTypeList != null && res.getReturnValue().bigTypeList.length != 0) {
                    var bigTypeList = res.getReturnValue().bigTypeList;
                    var largeSize = bigTypeList.length;
                    //カテゴリーの大中小分類より、最大のサイズを算出する。
                    for (var i = 0 ; i < bigTypeList.length ; i++) {
                        if (bigTypeList[i].mediumTypeList != undefined) {
                            if (bigTypeList[i].mediumTypeList.length > largeSize) {
                                largeSize = bigTypeList[i].mediumTypeList.length;
                            }
                            for (var j = 0 ; j < bigTypeList[i].mediumTypeList.length ; j++) {
                                if (bigTypeList[i].mediumTypeList[j].smallTypeList != undefined) {
                                    if (bigTypeList[i].mediumTypeList[j].smallTypeList.length > largeSize) {
                                        largeSize = bigTypeList[i].mediumTypeList[j].smallTypeList.length;
                                    }
                                }
                            }
                        }
                    }
                    //最大のサイズより、高さを設定する。
                    if (largeSize > 3) {
                        component.set("v.categoryHeight", (largeSize + 1) * component.get("v.PDomHeight") + 30);
                    }
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "商品カテゴリーなし",
                        "message": "商品カテゴリーがありません。",
                        "type":"warning"
                    });
                    toastEvent.fire();
                }
            } else if (state == "ERROR") {//処理異常の場合
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "初期化エラー",
                    "message": "システム管理者に連絡ください。",
                    "type":"error"
                });
                toastEvent.fire();
            }
        });	
    },
    
    /** 
     * 検索ボタンを押して、検索処理を行う
     */ 
    doSearch : function (component, event, helper) {
        //メイン検索処理
        helper.mainSearch(component,component.get("v.category"));
        //前回選択されたカテゴリーを記録する。
        component.set("v.oldCategory",component.get("v.category"));
    },
    
    doKeySearch : function (component, event, helper) {
    	if (event.getParams().keyCode == 13) {
            //メイン検索処理
    		helper.mainSearch(component,component.get("v.category"));
    		//前回選択されたカテゴリーを記録する。
    		component.set("v.oldCategory",component.get("v.category"));
    	}
    },
    
    /** 
     * カテゴリーをクリックして、検索処理を行う
     */ 
    categorySearch : function (component, event, helper) {
        //選択されたカテゴリーを画面に記録する。
        component.set("v.category",event.currentTarget.id);
        //メイン検索処理
        helper.mainSearch(component,event.currentTarget.id);
        //前回選択されたカテゴリーを記録する。
        component.set("v.oldCategory",event.currentTarget.id);
    },
    
    /** 
     * 大分類をクリックして、中分類を表示される。
     */ 
    bigtypeSelect : function (component, event, helper) {
        component.set("v.mediumTypes",null);
        var bigTypeList = component.get("v.bigTypeList");
        var targetIndex = event.currentTarget.name;
        //選択されたカテゴリーを画面に記録する。
        component.set("v.mediumTypes",bigTypeList[targetIndex].mediumTypeList);
        component.set("v.smallTypes",null);
        //選択されたカテゴリーを画面に記録する。
        component.set("v.category",event.currentTarget.id);
    },
    
    /** 
     * 中分類をクリックして、小分類を表示される。
     */ 
    mediumTypeSelect : function (component, event, helper) {
        component.set("v.smallTypes",null);
        var mediumTypeList = component.get("v.mediumTypes");
        var targetIndex = event.currentTarget.name;
        //選択されたカテゴリーを画面に記録する。
        component.set("v.smallTypes",mediumTypeList[targetIndex].smallTypeList);
        var categorySet= component.get("v.category").split(' > ');
        //選択されたカテゴリーを画面に記録する。
        var category = categorySet[0] + " > " + event.currentTarget.id;
        component.set("v.category",category);
        //メイン検索処理
        helper.mainSearch(component,category);
        //前回選択されたカテゴリーを記録する。
        component.set("v.oldCategory",category);
    },
    
    /** 
     * 小分類をクリックする。
     */ 
    smallTypeSelect : function (component, event, helper) {
        var categorySet= component.get("v.category").split(' > ');
        var category = categorySet[0] + " > " + categorySet[1] + " > " + event.currentTarget.id;
        //選択されたカテゴリーを画面に記録する。
        component.set("v.category",category);
        //メイン検索処理
        helper.mainSearch(component,category);
        //前回選択されたカテゴリーを記録する。
        component.set("v.oldCategory",category);
    },
    
    /** 
     * 戻るボタンを押して、見積へ
     */ 
    doBack : function (component, event, helper) {
        location.reload();
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.estimatecId"),
            "slideDevName": "detail"
        });
        navEvt.fire();
    },

    /** 
     * セット番号をクリックして、関連商品のコンポーネントを開いて、関連セット商品を表示します。
     */ 
    openRelatedProduct: function(component, event, helper) {
    	component.set("v.registInit", true);
    },

    /** 
     * 在庫商品の画像をクリックすると、該当在庫商品にアップロードした画像をすべて表示します。
     */ 
    fullScreen: function(component, event, helper) {
        var InventoryProductDetailList = component.get("v.InventoryProductDetailList");
        var index = event.currentTarget.name;
        var toastEvent = $A.get("e.force:showToast");
        var url = event.currentTarget.src.substring(0,event.currentTarget.src.lastIndexOf('/'));
        console.log(url);
        if (InventoryProductDetailList[index].imgsId == null || InventoryProductDetailList[index].imgsId == '') {
            toastEvent.setParams({
                "title": "画像なし",
                "message": "画像まだアップロードしません。",
                "type":"error"
            });
            toastEvent.fire();
            return;
        }
        
        var action = component.get("c.getImgId");
        action.setParams({
                         "contentVersionIds": InventoryProductDetailList[index].imgsId
                         });
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
            var state = res.getState();
            if (state == "SUCCESS") {
                console.log(res.getReturnValue());
                var imgsId = res.getReturnValue();
                for (var i = 0 ; i < imgsId.length ; i++) {
                    imgsId[i] = url + '/' + imgsId[i];
                }
                component.set("v.fullScreen", true);
    	        component.set("v.fullScreenUrl", imgsId);
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
     * 選択ボタンが、選択と選択済みの切り替え処理
     */ 
    toggleSelect: function(component, event, helper) {
    	var InventoryProductDetailList = component.get("v.InventoryProductDetailList");
        var index = event.getSource().get('v.value');
        console.log('index:' + index);
        if (component.get("v.estimatecId") != '' && component.get("v.estimatecId") != null) {//見積から画面入って、在庫品選択パターン
        	if (InventoryProductDetailList[index].selectKBN == true) {
        		//既に選択済みの場合、商品削除処理を行う。
        		helper.deleteProduct(component,InventoryProductDetailList,index);
        	} else {
        		//未選択の場合、商品登録処理を行う。
        		helper.createProduct(component,InventoryProductDetailList,index);
        	}
        } else {//タブから画面入って、package商品作成パターン
            console.log('package');
            if (component.get("v.invProduct.PackageStatus__c") != '作成中') {
            	var toastEvent = $A.get("e.force:showToast");
            	toastEvent.setParams({
            		"title": "操作誤り",
            		"message": "作成中以外のpackage商品について、商品の追加、削除はできません。",
            		"type":"warning"
            	});
            	toastEvent.fire();
            	return null;
            }
            if (InventoryProductDetailList[index].selectKBN == true) {
        		//既に選択済みの場合、商品削除処理を行う。
        		helper.deletePackageProduct(component,InventoryProductDetailList,index);
        	} else {
        		//未選択の場合、商品登録処理を行う。
        		helper.createPackageProduct(component,InventoryProductDetailList,index);
        	}
        }
    },
    
    /** 
     * 在庫商品レポートボタンを押して、在庫商品リストレポートを開きます。
     */ 
    /*openReport: function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        var action = component.get("c.getReportURL");
        action.setParams({
                         "reportName": 'SelectedProductList',
                         "recordId": component.get("v.estimatecId")
                         });
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
            var state = res.getState();	
            if (state == "SUCCESS") {
                if (res.getReturnValue() != null) {
                     window.open(res.getReturnValue());                
                } else {
                    toastEvent.setParams({
                        "title": "在庫商品リストなし",
                        "message": "在庫商品リストレポートを作りません。",
                        "type":"warning"
                    });
                    toastEvent.fire();
                }
            } else if (state === "ERROR") {	
                toastEvent.setParams({
                    "title": "システムエラー",
                    "message": "システム管理者を連絡ください。",
                    "type":"error"
                });
                toastEvent.fire();
            }
        });
    },*/
    
    /** 
     * 絞り条件クリア処理
     */ 
    clear: function(component, event, helper) {
    	helper.conditionClear(component);
    },
    
    changesection:function(component, event, helper){
        var show = !component.get("v.section_show");
        component.set("v.section_show",show);
    },
    
    /** 
     * 新規Packageボタンを押すと、パッケージ商品を作成
     */
    createPackage:function(component, event, helper){
        console.log('productMasterId::' + component.get("v.productMasterId"));
        var toastEvent = $A.get("e.force:showToast");
        var action = component.get("c.doCreatePackage");
        action.setParams({
                         "productMasterId": component.get("v.productMasterId")
                         });
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
            var state = res.getState();	
            if (state == "SUCCESS") {
                toastEvent.setParams({
                    "title": "新規完了",
                    "message": "Package商品を作成しました。",
                    "type":"success"
                });
                toastEvent.fire();
                console.log(res.getReturnValue());
                component.set("v.packageProductName",res.getReturnValue().Name);
                component.set("v.invProduct",res.getReturnValue());
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
     * Package商品の保存ボタンを押すと、パッケージ商品を保存する。（状態変更だけ）
     */
    packageProductSave:function(component, event, helper){
        var toastEvent = $A.get("e.force:showToast");
        var action = component.get("c.doPackageProductSave");
        action.setParams({
                         "invProduct": component.get("v.invProduct")
                         });
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
            var state = res.getState();	
            if (state == "SUCCESS") {
                toastEvent.setParams({
                    "title": "保存完了",
                    "message": "保存完了しました。",
                    "type":"success"
                });
                toastEvent.fire();
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
     * Package商品の確定ボタンを押すと、パッケージ商品を検索する。
     */
    packageProductSelect:function(component, event, helper){
        var toastEvent = $A.get("e.force:showToast");
        var action = component.get("c.doPackageProductSelect");
        action.setParams({
                         "packageProductName": component.get("v.packageProductName")
                         });
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
            var state = res.getState();	
            if (state == "SUCCESS") {
                component.set("v.invProduct",res.getReturnValue().invProduct);
                component.set("v.InventoryProductDetailList", res.getReturnValue().packageProducts);
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