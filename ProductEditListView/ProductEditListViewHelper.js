({
	getWonProductByMitumoriId : function(component) {
	    if (!component.get("v.initFlg")) {
	        console.log("mySpinner start");
	        $A.util.toggleClass(component.find("mySpinner"),"slds-hide");
	    }
	    
		var action = component.get("c.getInitInfo");
		console.log("sObjectName:" + component.get("v.sObjectName"));
        action.setParams({"Id":component.get("v.recordId"),"sObjectName":component.get("v.sObjectName")});
        
        action.setCallback(this,function(res){
            if(component.isValid() && res.getState() === "SUCCESS"){
                var result = res.getReturnValue();
                console.log(result);
                component.set("v.oppProductList",result.oppProducts);    //商品明細
                component.set("v.estimate",result.estimate);   //見積
                if (component.get("v.initFlg")) {
                    //component.set("v.estimate",result.estimate);   //見積
                	component.set("v.recordTypeId",component.get("v.estimate.RecordTypeId"));    //レコードタイプID
                	component.set("v.salesOppId",result.salesOppId);    //販売商品ID
                	component.set("v.installationLocationOpts",result.options);    //設置場所選択肢
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
            if (!component.get("v.initFlg")) {
            	console.log("mySpinner end");
            	$A.util.toggleClass(component.find("mySpinner"),"slds-hide");
            } else {
                component.set("v.initFlg",false);
            }
        })
        $A.enqueueAction(action);
	},

	reSort:function(component,event,helper){
        component.set("v.sortField",null);
        var sortNumList = new Array();
        $(".sortNum").each(function(){
            sortNumList.push($(this).text());    
        })
        console.log(sortNumList);

        var ProductList = this.getOppProductList(component,event,helper);
        for(var i=0;i<ProductList.length;i++){
            for(var j=0;j<sortNumList.length;j++){
                if(ProductList[i].Id == sortNumList[j]){
                    ProductList[i].SortNo__c = j;
                }
            }
        }
        console.log(ProductList);
        //component.set("v.ProductList",ProductList);
        return ProductList;
    },
    
    getOppProductList:function(component,event,helper){
        var oppProductList = component.get("v.oppProductList");
        var ProductList = new Array();
        for (var j = 0 ; j < oppProductList.length ; j++) {
            ProductList.push(oppProductList[j].oppProduct);
        }
        return ProductList;
    },
})