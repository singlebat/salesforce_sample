({
    newRecord : function(component) {
    	//新規の場合
    	component.find("recordEditor").getNewRecord(
    			"OpportunityProduct__c", // sObject type (entityAPIName)
    			null,      // recordTypeId
    			false,     // skip cache?
    			$A.getCallback(function() {
    				var rec = component.get("v.record");
    				var error = component.get("v.recordError");
    				component.set("v.opporProductRecord.MonthlyLeaseRate__c",component.get("v.estimate").MonthlyLeaseRate__c); //月額リース料率
    				component.set("v.opporProductRecord.SyokaiMonthlyLeaseRate__c",component.get("v.estimate").MonthlyLeaseRate__c); //(非表示)初回月額リース料率
    				if(component.get("v.estimate").LeaseTerm__c!=null){
    					component.set("v.opporProductRecord.LeaseTerm__c",component.get("v.estimate").LeaseTerm__r.Name); //リース契約期間
    				}
    				component.set("v.opporProductRecord.Rank__c","N");   //ランク
    				component.set("v.opporProductRecord.RankRate__c",100);    //ランク率
    				component.set("v.opporProductRecord.PurchaseRate__c",100);    //仕入率
    				//component.set("v.opporProductRecord.Contract__c",component.get("v.estimate").Estimate__r[0].Id);    //契約と紐づける
    				if(component.get("v.estimate").rel_Delivery__r!=null){
    					component.set("v.opporProductRecord.Delivery__c",component.get("v.estimate").rel_Delivery__r[0].Id); //配送と紐づける
    				}
    				
    				component.set("v.recordNotLockFlag",component.get("v.estimate.QuotationStatus__c")=="見積" && ( component.get("v.estimate.ApprovalStatus__c")=="未提出" || component.get("v.estimate.ApprovalStatus__c")=="却下" )); //編集ロックフラグ
    				
    				var ary = new Array();
    				component.set("v.slides", ary);
    				if(error || (rec == null)) {
    					console.log("Error initializing record template: " + error);
    				}
    				else {
    					console.log("Record template initialized: " + rec.sobjectType);
    				}
    			})
    	);
    },
    
    /** 
     * 合計値の再計算
     */
    helperCaculateSumData : function(component) {
        // 数量
        var quantity = component.get("v.opporProductRecord.Quantity__c");
        //標準小売価格(合計)
        component.set("v.opporProductRecord.ProductListPrice__c",quantity * component.get("v.opporProductRecord.MakerPrice__c"));
        //下代
        component.set("v.opporProductRecord.SalesCost__c",Math.floor(component.get("v.opporProductRecord.PurchaseRate__c") * component.get("v.opporProductRecord.MakerPrice__c")/100));
        
        if (component.get("v.opporProductRecord.PurchaseRate__c") <= 65) {
            //計算価値価格
            component.set("v.opporProductRecord.UnitPriceLease__c",Math.floor(component.get("v.opporProductRecord.MakerPrice__c") * component.get("v.opporProductRecord.RankRate__c")/100));
        } else {
            var UnitPriceLease = Math.ceil((component.get("v.opporProductRecord.SalesCost__c")/0.65)/1000) * 1000;
            //計算価値価格
            component.set("v.opporProductRecord.UnitPriceLease__c",UnitPriceLease);
        }
        
        //計算価値価格(合計)
        component.set("v.opporProductRecord.AmountPercentLease__c",quantity * component.get("v.opporProductRecord.UnitPriceLease__c"));
        
        if (component.get("v.leaseRTId") == component.get("v.recordTypeId")) {
            //リース価値価格
            component.set("v.opporProductRecord.UnitPriceLeaseSansyo__c",Math.floor(component.get("v.opporProductRecord.MakerPrice__c") * component.get("v.opporProductRecord.RankRate__c")/100));
            //月額リース料
            component.set("v.opporProductRecord.EachMonthlyLeaseFee__c",Math.floor(component.get("v.opporProductRecord.UnitPriceLease__c") * component.get("v.opporProductRecord.MonthlyLeaseRate__c") / 100));
            //月額リース料(合計)
            component.set("v.opporProductRecord.MonthlyLeaseFee__c",quantity * component.get("v.opporProductRecord.EachMonthlyLeaseFee__c"));
        }
    },
    
    /** 
     * 仕入別メーカー別マスタから仕入率、販売率を検索して、表示.
     */
    searchPurchaseProductMaster : function(component) {
        //初期化するとき、下記の処理を行わない。
        if (component.get("v.initFlg")) {
             component.set("v.initFlg",false);
             return;
        }
        //if (component.get("v.sellingRTId") == component.get("v.recordTypeId")) {  //販売の場合
        	//仕入先または商品マスタを変わると、仕入率、販売率をリセット
        	console.log("仕入先ID::" + component.get("v.opporProductRecord.Vendor__c"));
        	var productMasterId;
        	var vendorId = component.get("v.opporProductRecord.Vendor__c");
        	var marker = component.get("v.opporProductRecord.Maker__c");
        	if (component.get("v.newEditDivision") == "new") {
        		productMasterId = component.get("v.opportunityProduct.Product__c");
        	} else {
        		productMasterId = component.get("v.opporProductRecord.Product__c");
        	}

        	if (marker != null && productMasterId != null) {
        		var action = component.get("c.getPurchaseProductMasterInfo");
        		//パラメータ設定
        		action.setParams({
        			"productMasterId": productMasterId,
        			"vendorId": vendorId
        		});
        		//メソッド実行
        		$A.enqueueAction(action);
        		action.setCallback(this, function(res) {
        			var state = res.getState();
        			if (state == "SUCCESS") {
        				if (res.getReturnValue() != null) {
        				    component.set("v.opporProductRecord.PurchaseRate__c",res.getReturnValue().PurchaseRate__c);
        				}
        				//合計値の計算
                        this.helperCaculateSumData(component);
        			}
        		});
        	}
        //}
    },
    
    /** 
     * 必須チェック
     */
    requiredCheck: function(component) {
        console.log("checkStart");
        console.log(component.get("v.opporProductRecord.InstallationLocation__c"));
        if (component.get("v.newEditDivision") == "new") {//新規の場合
            //商品マスタ
    	    if ( $A.util.isEmpty(component.get("v.opportunityProduct.Product__c")) || $A.util.isUndefinedOrNull(component.get("v.opportunityProduct.Product__c")) ) {
    		    return "商品マスタ";
    	    }
        } else if (component.get("v.newEditDivision") == "edit") {//編集の場合
            //商品マスタ
    	    if ( $A.util.isEmpty(component.get("v.opporProductRecord.Product__c")) || $A.util.isUndefinedOrNull(component.get("v.opporProductRecord.Product__c")) ) {
    		    return "商品マスタ";
    	    }
        } else {
            return "システムエラー";
        }
	    
    	//数量
    	if ( $A.util.isEmpty(component.get("v.opporProductRecord.Quantity__c")) || $A.util.isUndefinedOrNull(component.get("v.opporProductRecord.Quantity__c")) ) {
    		return "数量";
    	}
    	
    	//設置場所
    	/*if ( $A.util.isEmpty(component.get("v.opporProductRecord.InstallationLocation__c")) 
    	　　　　　　　　|| $A.util.isUndefinedOrNull(component.get("v.opporProductRecord.InstallationLocation__c"))) {
    		return "設置場所";
    	}*/
    	
    	//新規または仕入品編集の場合、仕入れ情報をチェックする。
    	if (component.get("v.newEditDivision") == "new" || (component.get("v.productType") == "仕入品" && component.get("v.newEditDivision") == "edit")) {
    	    //仕入先
    	    if ( $A.util.isEmpty(component.get("v.opporProductRecord.Vendor__c")) 
    	    　　　　　　　　|| $A.util.isUndefinedOrNull(component.get("v.opporProductRecord.Vendor__c")) ) {
    	    	return "仕入先";
    	    }
    	    
    	    //仕入率
    	    if ( ($A.util.isEmpty(component.get("v.opporProductRecord.PurchaseRate__c")) 
    	    　　　　　　　　|| $A.util.isUndefinedOrNull(component.get("v.opporProductRecord.PurchaseRate__c")))
    	         && !component.get("v.opporProductRecord.SetupFeeFlag__c")
    	         && !component.get("v.opporProductRecord.KENSpecialDiscountFlag__c")
    	         && !component.get("v.opporProductRecord.DiscountFlag__c") ) {
    	    	return "仕入率";
    	    }
    	    
    	    //配送区分
    	    if ( ($A.util.isEmpty(component.get("v.opporProductRecord.HaisouType__c")) 
    	　　　　　    　　　|| $A.util.isUndefinedOrNull(component.get("v.opporProductRecord.HaisouType__c")))
    	        && !component.get("v.opporProductRecord.SetupFeeFlag__c")
    	        && !component.get("v.opporProductRecord.KENSpecialDiscountFlag__c")
    	        && !component.get("v.opporProductRecord.DiscountFlag__c") ) {
    	    	return "配送区分";
    	    }
    	}

    	if (component.get("v.leaseRTId") == component.get("v.recordTypeId")) {//リースの場合
            //リース価値価格(単価)
    	    if ( $A.util.isEmpty(component.get("v.opporProductRecord.UnitPriceLease__c"))
    	　　　　　    　　　|| $A.util.isUndefinedOrNull(component.get("v.opporProductRecord.UnitPriceLease__c")) ) {
    	    	return "リース価値価格(単価)";
    	    }
        } /*else if (component.get("v.sellingRTId") == component.get("v.recordTypeId")) {//販売の場合
            //販売価値価格(単価)
    	    if ( $A.util.isEmpty(component.get("v.opporProductRecord.UnitPriceSelling__c")) 
    	　　　　　    　　　|| $A.util.isUndefinedOrNull(component.get("v.opporProductRecord.UnitPriceSelling__c")) ) {
    	    	return "販売価値価格(単価)";
    	    }
        }*/
        
        //型名
        if ( $A.util.isEmpty(component.get("v.opporProductRecord.ModelNumber__c")) 
        　　        || $A.util.isUndefinedOrNull(component.get("v.opporProductRecord.ModelNumber__c")) ) {
    	    return "型名";
    	} else if (this.getLength(component.get("v.opporProductRecord.ModelNumber__c"))>20) {
    	    return "20桁までに型名";
    	}
    	
    	//型番
        if( !$A.util.isUndefinedOrNull(component.get("v.opporProductRecord.ModelNo__c"))　&& this.getLength(component.get("v.opporProductRecord.ModelNo__c"))>20){
        	return "20桁までに型番";
        }
        
        //色番
        if ( !$A.util.isUndefinedOrNull(component.get("v.opporProductRecord.ColorNo__c"))　&& this.getLength(component.get("v.opporProductRecord.ColorNo__c"))>20) {
            return "20桁までに色番";
        }

    	return null;
	},

    /** 
     * 幅・奥行き・直径を変わるの場合、制御処理
     */
    sizeChangeMain:function(component){
        if ( !$A.util.isEmpty(component.get("v.opporProductRecord.Diameter__c")) && !$A.util.isUndefinedOrNull(component.get("v.opporProductRecord.Diameter__c")) ){
            component.set("v.widthDehtpFlg",true);
        } else {
            component.set("v.widthDehtpFlg",false);
        }
        if ( !$A.util.isEmpty(component.get("v.opporProductRecord.Width__c")) && !$A.util.isUndefinedOrNull(component.get("v.opporProductRecord.Width__c")) ){
        	component.set("v.DiameterFlg",true);
        } else {
            if ( !$A.util.isEmpty(component.get("v.opporProductRecord.Depth__c")) && !$A.util.isUndefinedOrNull(component.get("v.opporProductRecord.Depth__c")) ){
        		component.set("v.DiameterFlg",true);
        	} else {
        	    component.set("v.DiameterFlg",false);
        	}
        }
        console.log(component.get("v.DiameterFlg"));
        console.log(component.get("v.widthDehtpFlg"));
    },
    
    /** 
     * 桁数取得
     */
    getLength:function (str){
    	var Zcount = 0;  
    	var ZunicodeNum = 0;  
    	var Ycount = 0;  
    	for(var i=0;i<str.length;i++){
    		if(str.charCodeAt(i)<128 && str.charCodeAt(i)>=0){
    			Ycount++; //一个英文占一个字符位
    		}else{
    			Zcount++;//英語以外の場合、字符个数1
    			ZunicodeNum+=2;
    		}
    	}
    	var total = ZunicodeNum + Ycount
    	return total;
    },
})