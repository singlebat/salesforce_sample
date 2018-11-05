({
	doInit : function(component, event, helper) {
        helper.getInvOppProductMain(component);
	},

    changesection:function(component, event, helper){
        var show = !component.get("v.section_show");
        component.set("v.section_show",show);
    },
    
    scriptsLoaded : function(component, event, helper){

    },
    
    /** 
     * 商品一覧リフレッシュ処理
     */
    refresh:function(component,event,helper){
        helper.getInvOppProductMain(component);
    },
    
    /** 
     * リースボタンを押して、商品一覧を保存する。
     */
    leasing:function(component,event,helper){
        helper.salesDeleteMain(component,'リース中');
    },
    
    /** 
     * 買取ボタンを押して、商品一覧を保存する。
     */
    sales:function(component,event,helper){
        helper.salesDeleteMain(component,'買取');
    },
    
    /** 
     * 除却ボタンを押して、商品一覧を保存する。
     */
    deletes:function(component,event,helper){
        helper.salesDeleteMain(component,'解約');
    },
    
    /** 
     * 配送依頼
     */
    carryOutApply:function(component,event,helper){
        var ProductList = new Array();
        var invOppProductList = component.get("v.invOppProductList");
        for (var j = 0 ; j < invOppProductList.length ; j++) {
        	if (invOppProductList[j].selectedFlg == true) {
        	    if (invOppProductList[j].invOppProduct.Status__c != '解約') {
        	    	helper.showMessage(component,"配送失敗","解約商品のみ、選択できます。","warning");
        	    	return null;
        	    }
        		ProductList.push(invOppProductList[j].invOppProduct);
        	}
        }
        
        if (ProductList.length == 0) {
        	helper.showMessage(component,"配送失敗","商品を選択してください。","warning");
        	return null;
        }
        
        component.set("v.invOppProducts",ProductList);
        component.set("v.showModal",true);
    },
    
    /** 
     * 仕入において、入庫する
     */
    purchaseStoring : function(component, event, helper){
        
        var invOppProductList = component.get("v.invOppProductList");
    	var status = invOppProductList[0].invOppProduct.OpportunityProduct__r.Purchase__r.Status__c;
		if(status == '発注済'){
			helper.combinedMain(component,"入庫");
			helper.changeAllcheck(component,event,helper);
		}else{
            helper.showMessage(component,"エラー!","発注済の場合のみ、入庫処理ができます。","error");
		}
    },
    
    /** 
     * 配送において、出庫準備完了にする
     */
    tehaiApply : function(component, event, helper){
    	var invOppProductList = component.get("v.invOppProductList");
    	var status = invOppProductList[0].invOppProduct.Haisou__r.DeliveryStatus__c;
		if(status == '依頼済'){
			helper.combinedMain(component,"出庫準備完了");
			helper.changeAllcheck(component,event,helper);
		}else{
            helper.showMessage(component,"エラー!","依頼済の場合のみ、出庫準備完了処理ができます。","error");
		}
    },
    
    /** 
     * 配送において、D/L（搬入）完了或は搬出済にする
     */
    deliveryApply : function(component, event, helper){
        helper.combinedMain(component,"配送");
    },
    
    /** 
     * 配送において、メンテ済にする
     */
    repair : function(component, event, helper){
        helper.salesDeleteMain(component,'メンテ済');
    },
    
    /** 
     * 商品全選択/解除
     */
    checkAll:function(component,event,helper){
    	helper.changeAllcheck(component,event,helper);
    },
    
    /** 
     * 保存ボタンを押して、主にダメージ料金を保存する。
     */
    save:function(component,event,helper){
        helper.salesDeleteMain(component,'');
    },
})