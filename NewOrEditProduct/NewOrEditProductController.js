({

    handleRecordUpdated: function(component, event, helper) {
    	var eventParams = event.getParams();
    	if(eventParams.changeType === "LOADED") {
    		// record is loaded (render other component which needs record data value)
    		console.log("Record is loaded successfully.");
    		//付属品１
    		if(component.get("v.opporProductRecord.Accessories__c") !=null && component.get("v.opporProductRecord.Accessories__c") != ''){
    			component.set("v.display1","");
    		}else{
    			component.set("v.display1","display:none");
    		}

    		//付属品２
    		if(component.get("v.opporProductRecord.Accessories2__c") !=null && component.get("v.opporProductRecord.Accessories2__c") != ''){
    			component.set("v.display2","");
    		}else{
    			component.set("v.display2","display:none");
    		}

    		//付属品３
    		if(component.get("v.opporProductRecord.Accessories3__c") !=null && component.get("v.opporProductRecord.Accessories3__c") != ''){
    			component.set("v.display3","");
    		}else{
    			component.set("v.display3","display:none");
    		}
    		helper.sizeChangeMain(component);
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
     * 初期化
     */
    doInit : function(component, event, helper) {
    	if (component.get("v.initFlg")) {//初期化の時、
    		helper.newRecord(component);
    		component.set("v.initFlg",false);
    		return;
    	} else { //見積編集の場合、
    		component.set("v.opporProductRecord.MonthlyLeaseRate__c",component.get("v.estimate").MonthlyLeaseRate__c); //月額リース料率
    		component.set("v.opporProductRecord.SyokaiMonthlyLeaseRate__c",component.get("v.estimate").MonthlyLeaseRate__c); //(非表示)初回月額リース料率
    		if(component.get("v.estimate").LeaseTerm__c!=null){
    			component.set("v.opporProductRecord.LeaseTerm__c",component.get("v.estimate").LeaseTerm__r.Name); //リース契約期間
    		}
    		component.set("v.recordNotLockFlag",component.get("v.estimate.QuotationStatus__c")=="見積" && ( component.get("v.estimate.ApprovalStatus__c")=="未提出" || component.get("v.estimate.ApprovalStatus__c")=="却下" )); //編集ロックフラグ
    	    helper.helperCaculateSumData(component);
    	}
    },
    
    //付属品の当行を削除
    deleterow: function(component, event, helper) {
    	 var Id = event.getSource().get("v.name");
    	 //表示するかどうかの判断です
    	 if (Id== "1") {
    		component.set("v.display1","display:none");  
        }else if(Id== "2"){
        	component.set("v.display2","display:none");  
        }else if(Id== "3"){
        	component.set("v.display3","display:none");  
        }
    },
    
    /** 
     * モデルを開いている時
     */
    upsertRecord : function(component, event, helper) {
        console.log("upsertRecord");
        if (component.get("v.newEditDivision") != "edit") {
            return;
        }
        //初期化するとき、初期化フラグをリセットする。
        component.set("v.initFlg",true);
        var ary = new Array();
        component.set("v.slides", ary);
        component.set("v.clearFlg",true);
        console.log("childSpinner start");
        $A.util.toggleClass(component.find("childSpinner"),"slds-hide");
        var productId = component.get("v.productId");
        console.log("productId:::" + productId);
        //LDSレコードをリロード
        component.find("recordEditor").reloadRecord(true);

        //アクションを定義
        var action = component.get("c.initEdit");
        //パラメータ設定
        action.setParams({"productId":productId});
        //コールバック処理
        action.setCallback(this,function(res){
        	if(component.isValid() && res.getState() === "SUCCESS"){
        		if (res.getReturnValue().oppProduct.InstallationLocation__c != null) {
        			component.set("v.installationLocationName",res.getReturnValue().oppProduct.InstallationLocation__r.Name);   //設置場所表示名
        		}
        		component.set("v.installationLocationId",res.getReturnValue().oppProduct.InstallationLocation__c);   //初期設置場所ID
        		
        		if (res.getReturnValue().oppProduct.Vendor__c != null) {
        			component.set("v.vendorName",res.getReturnValue().oppProduct.Vendor__r.Name);   //仕入先表示名
        		} else {
        		    component.set("v.initFlg",false);
        		}

        		//画像の複数URLを取得
        		var PictureURL = res.getReturnValue().pictureURL;
        		console.log("PictureURL::" + PictureURL);
        		if (PictureURL != null && PictureURL != undefined) {
        		    var url = PictureURL.substring(0,PictureURL.lastIndexOf('/'));
        		    var imgIds = res.getReturnValue().imgIds;
                    for (var i = 0 ; i < imgIds.length ; i++) {
                        imgIds[i] = url + '/' + imgIds[i];
                    }
                    console.log(imgIds);
                    component.set("v.slides", imgIds);
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
        	console.log("childSpinner end");
        	$A.util.toggleClass(component.find("childSpinner"),"slds-hide");
        })
        //アクションを実行
        $A.enqueueAction(action);
    },
    
    /** 
     * 数量変更の場合
     */
    caculateSumData : function(component, event, helper) {
        //合計値の計算
        helper.helperCaculateSumData(component);
    },
    
    /** 
     * 仕入率或はメーカ単価変更の場合
     */
    caculateData : function(component, event, helper) {
        console.log("caculateData");
        console.log(component.get("v.opporProductRecord.PurchaseRate__c"));
        console.log(component.get("v.opporProductRecord.MakerPrice__c"));
        

        //合計値の計算
        helper.helperCaculateSumData(component);
    },
    
    /** 
     * 保存ボタンを押す
     */
    handleSaveRecord: function(component, event, helper) {
        console.log("handleSaveRecord");
        console.log("childSpinner start");
        $A.util.toggleClass(component.find("childSpinner"),"slds-hide");
        if(component.get("v.display1")=="display:none"){
		    //付属品１
            component.set("v.opporProductRecord.Accessories__c",null);
             //型番１
            component.set("v.opporProductRecord.AccessorieMod1__c",null);
             //仕様１
            component.set("v.opporProductRecord.AccessorieSp1__c",null);
             //数量１
            component.set("v.opporProductRecord.AccessorieNum1__c",null);
             //サイズ１
            component.set("v.opporProductRecord.AccessorieSize1__c",null);
            component.set("v.display1","display:none"); 
        }
        if(component.get("v.display2")=="display:none"){
        	//付属品２
            component.set("v.opporProductRecord.Accessories2__c",null);
             //型番２
            component.set("v.opporProductRecord.AccessorieMod2__c",null);
             //仕様２
            component.set("v.opporProductRecord.AccessorieSp2__c",null);
             //数量２
            component.set("v.opporProductRecord.AccessorieNum2__c",null);
             //サイズ２
            component.set("v.opporProductRecord.AccessorieSize2__c",null);
            component.set("v.display2","display:none"); 
        }
        if(component.get("v.display3")=="display:none"){
        	//付属品３
            component.set("v.opporProductRecord.Accessories3__c",null);
             //型番３
            component.set("v.opporProductRecord.AccessorieMod3__c",null);
             //仕様３
            component.set("v.opporProductRecord.AccessorieSp3__c",null);
             //数量３
            component.set("v.opporProductRecord.AccessorieNum3__c",null);
             //サイズ３
            component.set("v.opporProductRecord.AccessorieSize3__c",null);
            component.set("v.display3","display:none"); 
        }
        //必須チェック
        var checkResult = helper.requiredCheck(component);
        if (checkResult != null) {
            var errorMsg;
            if (checkResult == "システムエラー") {
                errorMsg = checkResult;
            } else {
                errorMsg = checkResult + "を入力してください。";
            }
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
            	"title": "保存失敗",
            	"message": errorMsg,
            	"type":"warning"
            });
            console.log("childSpinner end");
            $A.util.toggleClass(component.find("childSpinner"),"slds-hide");
            resultsToast.fire();
            return;
        }
        
        //編集の場合、設置場所を変更すると、ソート番号をブランクになる。
        if (component.get("v.newEditDivision") == "edit") {
            if (component.get("v.opporProductRecord.InstallationLocation__c") != component.get("v.installationLocationId")) {
                component.set("v.opporProductRecord.SortNo__c",null);
            }
        }
        
        //新規の場合、標準LookUp値をLDSの項目にセットする。
        if (component.get("v.newEditDivision") == "new") {
            //商品マスタ
            component.set("v.opporProductRecord.Product__c",component.get("v.opportunityProduct.Product__c"));
        }
        
        console.log(component.get("v.opporProductRecord.InstallationLocation__c"));
        component.set("v.opporProductRecord.Estimates__c",component.get("v.estimateRecordId"));
        component.find("recordEditor").saveRecord(function(saveResult) {
            console.log(saveResult);
            console.log(component.get("v.productId"));
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                // record is saved successfully
                var action;
            	if (component.get("v.newEditDivision") == "new") {
            		component.set("v.newEditDivision","edit");    //新規の場合、保存した後、新規したばかリレコードの編集状態になる。
            		component.set("v.productId",component.get("v.opporProductRecord.Id"));    //新規したばかリレコードID
            		action = component.get("c.createInvOppProducts");
            	} else if (component.get("v.newEditDivision") == "edit") {
            		action = component.get("c.updateInvOppProducts");
            	}
            	action.setParams({
            		"id": component.get("v.opporProductRecord.Id"),
            	});
            	//メソッド実行
            	$A.enqueueAction(action);
            	action.setCallback(this, function(res) {
            		var state = res.getState();
            		var resultsToast = $A.get("e.force:showToast");
            		if (state == "SUCCESS") {
            			resultsToast.setParams({
            				"title": "保存成功",
            				"message": "更新成功しました",
            				"type":"success"
            			});
            		} else {
            			resultsToast.setParams({
            				"title": "システムエラー",
            				"message": "予想外のエラーを発生するため、システム管理者に連絡ください。",
            				"type":"error"
            			});
            		}
            		console.log("childSpinner end");
            		$A.util.toggleClass(component.find("childSpinner"),"slds-hide");
            	    $A.get('e.force:refreshView').fire();
            		resultsToast.fire();
            	});
            } else if (saveResult.state === "INCOMPLETE") {
                // handle the incomplete state
                console.log("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                // handle the error state
                console.log('Problem saving product, error: ' + 
                             JSON.stringify(saveResult.error));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state +
                            ', error: ' + JSON.stringify(saveResult.error));
            }
        });
    },
    
    /** 
     * 仕入先変更の場合
     */
    vendorChange: function(component, event, helper) {
        if (component.get("v.opporProductRecord.Vendor__c") != null ) {
            //仕入別メーカー別マスタから仕入率、販売率を検索して、表示.
            helper.searchPurchaseProductMaster(component);
        }
    },
    
    /** 
     * 商品マスタ選択
     */
    productMasterChange: function(component, event, helper) {
        console.log(component.get("v.opportunityProduct.Product__c"));
        //商品を削除する場合
        if(component.get("v.opportunityProduct.Product__c") == null || component.get("v.opportunityProduct.Product__c") == "" ){
            helper.newRecord(component);
        	return;
        }
        var action = component.get("c.getProductMasterInfo");
        //パラメータ設定
        action.setParams({
                         "productMasterId": component.get("v.opportunityProduct.Product__c")
                         });
        //メソッド実行
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
    	    var state = res.getState();
            if (state == "SUCCESS") {
                if (res.getReturnValue() == null) {
                    return;
                }
                
                if (res.getReturnValue().Maker__c != null ) {
                    component.set("v.opporProductRecord.Maker__c",res.getReturnValue().Maker__r.Name);
                }
                
                //商品名
                component.set("v.opporProductRecord.Name",res.getReturnValue().ProductName2__c);
                
                //商品レコードタイプ
                if (component.get("v.sellingRTId") == component.get("v.recordTypeId")) {
                    component.set("v.opporProductRecord.RecordTypeId",component.get("v.salesOppId"));
                }
                
                //設置費用の場合
                if (res.getReturnValue().SetupFeeFlag__c == true) {
                    component.set("v.opporProductRecord.MonthlyLeaseRate__c",0);    //リース料率は０にする。
                    component.set("v.opporProductRecord.SetupFeeFlag__c",true);    //フラグTRUEにする。
                    component.set("v.opporProductRecord.FeeType__c",res.getReturnValue().ProductCategory__r.FeeType__c);    //費用分類
                    component.set("v.opporProductRecord.PurchaseStatus__c","在庫");    //ステータスが　在庫　にする
                }
                
                //KEN様特別値引きの場合
                if (res.getReturnValue().KENSpecialDiscountFlag__c == true) {
                    component.set("v.opporProductRecord.MonthlyLeaseRate__c",0);    //リース料率は０にする。
                    component.set("v.opporProductRecord.KENSpecialDiscountFlag__c",true);    //フラグTRUEにする。
                    component.set("v.opporProductRecord.PurchaseStatus__c","在庫");    //ステータスが　在庫　にする
                }
                
                //出精値引の場合
                if (res.getReturnValue().DiscountFlag__c == true) {
                    component.set("v.opporProductRecord.MonthlyLeaseRate__c",0);    //リース料率は０にする。
                    component.set("v.opporProductRecord.DiscountFlag__c",true);    //フラグTRUEにする。
                    component.set("v.opporProductRecord.PurchaseStatus__c","在庫");    //ステータスが　在庫　にする
                }
                
                //付属品１
                component.set("v.opporProductRecord.Accessories__c",res.getReturnValue().Accessories__c);
                //alert(res.getReturnValue().oppProduct.Accessories__c);
                if(res.getReturnValue().Accessories__c!=null && res.getReturnValue().Accessories__c!=''){
                	component.set("v.display1","");
                }else{
                	component.set("v.display1","display:none");
                }
                 //型番１
                component.set("v.opporProductRecord.AccessorieMod1__c",res.getReturnValue().AccessorieMod1__c);
                 //仕様１
                component.set("v.opporProductRecord.AccessorieSp1__c",res.getReturnValue().AccessorieSp1__c);
                 //数量１
                component.set("v.opporProductRecord.AccessorieNum1__c",res.getReturnValue().AccessorieNum1__c);
                 //サイズ１
                component.set("v.opporProductRecord.AccessorieSize1__c",res.getReturnValue().AccessorieSize1__c);
                
                //付属品２
                component.set("v.opporProductRecord.Accessories2__c",res.getReturnValue().Accessories2__c);
                if(res.getReturnValue().Accessories2__c!=null && res.getReturnValue().Accessories2__c!=''){
                	component.set("v.display2","");
                }else{
                	component.set("v.display2","display:none");
                }
                 //型番２
                component.set("v.opporProductRecord.AccessorieMod2__c",res.getReturnValue().AccessorieMod2__c);
                 //仕様２
                component.set("v.opporProductRecord.AccessorieSp2__c",res.getReturnValue().AccessorieSp2__c);
                 //数量２
                component.set("v.opporProductRecord.AccessorieNum2__c",res.getReturnValue().AccessorieNum2__c);
                 //サイズ２
                component.set("v.opporProductRecord.AccessorieSize2__c",res.getReturnValue().AccessorieSize2__c);
                
                //付属品３
                component.set("v.opporProductRecord.Accessories3__c",res.getReturnValue().Accessories3__c);
                if(res.getReturnValue().Accessories3__c!=null && res.getReturnValue().Accessories3__c!=''){
                	component.set("v.display3","");
                }else{
                	component.set("v.display3","display:none");
                }
                 //型番３
                component.set("v.opporProductRecord.AccessorieMod3__c",res.getReturnValue().AccessorieMod3__c);
                 //仕様３
                component.set("v.opporProductRecord.AccessorieSp3__c",res.getReturnValue().AccessorieSp3__c);
                 //数量３
                component.set("v.opporProductRecord.AccessorieNum3__c",res.getReturnValue().AccessorieNum3__c);
                 //サイズ３
                component.set("v.opporProductRecord.AccessorieSize3__c",res.getReturnValue().AccessorieSize3__c);
                
                //型名
                component.set("v.opporProductRecord.ModelNumber__c",res.getReturnValue().ModelNumber__c);
                //型番
                component.set("v.opporProductRecord.ModelNo__c",res.getReturnValue().ModelNumber__c);
                //色番
                component.set("v.opporProductRecord.ColorNo__c",res.getReturnValue().ColorNo__c);
                //白熱色
                component.set("v.opporProductRecord.WhiteHot__c",res.getReturnValue().WhiteHot__c);
                //電球色
                component.set("v.opporProductRecord.DenkyuColor__c",res.getReturnValue().DenkyuColor__c);
                //LED
                component.set("v.opporProductRecord.LED__c",res.getReturnValue().LED__c);
                //色
                component.set("v.opporProductRecord.Color__c",res.getReturnValue().Color__c);
                //体積
                component.set("v.opporProductRecord.Volume__c",res.getReturnValue().Volume__c);
                //容量
                component.set("v.opporProductRecord.YoRyo__c",res.getReturnValue().YoRyo__c);
                //RC
                component.set("v.opporProductRecord.RC__c",res.getReturnValue().RC__c);
                //簡易取付
                component.set("v.opporProductRecord.EasySet__c",res.getReturnValue().EasySet__c);
                //ワンタッチ取付
                component.set("v.opporProductRecord.OneTatch__c",res.getReturnValue().OneTatch__c);
                //商品カテゴリー
                component.set("v.opporProductRecord.Category__c",res.getReturnValue().Category__c);
                //高さ（mm）
                component.set("v.opporProductRecord.Height__c",res.getReturnValue().Height__c);
                //高さⅡ（mm）
                component.set("v.opporProductRecord.Height2__c",res.getReturnValue().Height2__c);
                //幅（mm）
                component.set("v.opporProductRecord.Width__c",res.getReturnValue().Width__c);
                //直径（mm）
                component.set("v.opporProductRecord.Diameter__c",res.getReturnValue().Diameter__c);
                //奥行（mm）
                component.set("v.opporProductRecord.Depth__c",res.getReturnValue().Depth__c);

                //仕様1～8
                component.set("v.opporProductRecord.Specification1__c",res.getReturnValue().Specification1__c);
                component.set("v.opporProductRecord.Specification2__c",res.getReturnValue().Specification2__c);
                component.set("v.opporProductRecord.Specification3__c",res.getReturnValue().Specification3__c);
                component.set("v.opporProductRecord.Specification4__c",res.getReturnValue().Specification4__c);
                component.set("v.opporProductRecord.Specification5__c",res.getReturnValue().Specification5__c);
                component.set("v.opporProductRecord.Specification6__c",res.getReturnValue().Specification6__c);
                component.set("v.opporProductRecord.Specification7__c",res.getReturnValue().Specification7__c);
                component.set("v.opporProductRecord.Specification8__c",res.getReturnValue().Specification8__c);
                //標準小売価格(単価)
                component.set("v.opporProductRecord.MakerPrice__c",res.getReturnValue().ListPrice__c);
                
                //設置場所
                if (res.getReturnValue().InstallationLocation__c != null) {
                    component.set("v.opporProductRecord.InstallationLocation__c",res.getReturnValue().InstallationLocation__c);
                    component.set("v.installationLocationName",res.getReturnValue().InstallationLocation__r.Name);
                } else {
                    component.set("v.opporProductRecord.InstallationLocation__c",null);
                    component.set("v.installationLocationName","");
                }
                
                //仕入先
                if (res.getReturnValue().MainSupplier__c != null) {
                    component.set("v.opporProductRecord.Vendor__c",res.getReturnValue().MainSupplier__c);   
                    component.set("v.vendorName",res.getReturnValue().MainSupplier__r.Name);
                } else {
                    component.set("v.opporProductRecord.Vendor__c",null);   
                    component.set("v.vendorName","");
                }
                
                console.log(component.get("v.leaseRTId"));
                console.log(component.get("v.recordTypeId"));

                //仕入別メーカー別マスタから仕入率、販売率を検索して、表示.且 下代を計算する。
                component.set("v.opporProductRecord.PurchaseRate__c",100);
                if (component.get("v.opporProductRecord.Vendor__c") != null ) {
                    helper.searchPurchaseProductMaster(component);
                } else {
                    //合計値の計算
                    helper.helperCaculateSumData(component);
                }
            }
    	});
    },
    
    /** 
     * 商品選択ボタンを押して、 商品選択コンポーネントへ遷移する。
     */
    oppProductCreate:function(component,event,helper){
        console.log('遷移開始');
        console.log('遷移開始:' + component.get("v.estimateRecordId"));
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:OppProductCreate",
            componentAttributes: {
                estimatecId : component.get("v.estimateRecordId")
            }
        });
        evt.fire();
    },
    
    
     /** 
     *付属品追加ボタンを押して、 付属品の一行を追加する（最大限は３行）。
     */
     accessAdd:function(component,event,helper){
        console.log('付属品追加');
        var flg1=component.get("v.display1");
        component.set("v.display1","");
        
        var flg2=component.get("v.display2");
        if(flg1==""){
        	component.set("v.display2","");
        }
        
        if(flg2==""){
        	component.set("v.display3","");
        }
        
    },
    
    /** 
     * クリアボタンを押して、新規・編集商品コンポーネントにパラメータを設定して、開きます。
     */
    clearNew:function(component,event,helper){
        component.set("v.productType","");
        component.set("v.newEditDivision","new");
        component.set("v.productId","");
        helper.newRecord(component);
        component.set("v.clearFlg",true);
        component.set("v.display1","display:none");
        component.set("v.display2","display:none");
        component.set("v.display3","display:none");
    },
    
    /** 
     * 幅・奥行き・直径を変わるの場合、制御処理
     */
    sizeChange:function(component,event,helper){
        helper.sizeChangeMain(component);
    },
})