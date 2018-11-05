({
    doInit: function(component, event, helper) {
        var action = component.get("c.init");
        //パラメータ設定
        var recordId = component.get("v.recordId");
        
        action.setParams({
            estimateId: recordId
        });
        //メソッド実行
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
    	    var state = res.getState();
            if (state == "SUCCESS") {
                console.log(res.getReturnValue());
                if (res.getReturnValue()!= null) {
                //alert(res.getReturnValue().RecordType.Name);
                	component.set("v.optionsvalue",res.getReturnValue().RecordType.Name);
                	if(res.getReturnValue().RecordType.Name=='リース'){
                		component.set("v.initEs.DepositMonth__c",res.getReturnValue().LeaseTerm__r.Hosyokin__c); 
                    }
                    component.set("v.initOp.Name",res.getReturnValue().Opportunity__r.Name); 
                    component.set("v.initOp.CloseDate",res.getReturnValue().Opportunity__r.CloseDate); 
                    if(res.getReturnValue().Opportunity__r.UserNew__r!=null){
                    	component.set("v.accountName",res.getReturnValue().Opportunity__r.UserNew__r.Name); 
                    }
                    component.set("v.accountId",res.getReturnValue().Opportunity__r.UserNew__c); 
                    if(res.getReturnValue().Opportunity__r.PropertyName__r!=null){
                    	component.set("v.PropertyName",res.getReturnValue().Opportunity__r.PropertyName__r.Name); 
                    }
                    
                    component.set("v.PropertyId",res.getReturnValue().Opportunity__r.PropertyName__c);
                    component.set("v.initOp.HomeNumber__c",res.getReturnValue().Opportunity__r.HomeNumber__c); 
                    component.set("v.KeiyakuKikan",res.getReturnValue().DepositMonth__c); 
                    component.set("v.OpportunityId",res.getReturnValue().Opportunity__c);
                    
                } else {
                    console.log("none");
                }
            }
    	});
    },
    
    /** 
     * 保存ボタンを押す
     */
    handleSaveContact: function(component, event, helper) {

        console.log("handleSaveContact");
        console.log(component.get("v.sObjectName"));
        if(component.get("v.initEs.QuotationStatus__c")!="見積" || !( component.get("v.initEs.ApprovalStatus__c")=="未提出" || component.get("v.initEs.ApprovalStatus__c")=="却下" ) ){
        	var resultsToast = $A.get("e.force:showToast");
        	resultsToast.setParams({
        		"title": "見積編集失敗",
        		"message": "承認中、または承認済の見積は編集できません。",
        		"type":"ERROR"
        	});
        	resultsToast.fire();
			$A.get("e.force:closeQuickAction").fire();
			$A.get('e.force:refreshView').fire();
			return;
        }else{
            if (component.get("v.initOp.Name") == '' || component.get("v.initOp.Name") == null) {
                component.set("v.errorMessage","案件名を入力してください");
            } else if (component.get("v.initOp.CloseDate") == '' || component.get("v.initOp.CloseDate") == null){
                component.set("v.errorMessage","納品日を入力してください");
            } else {
                $A.util.toggleClass(component.find("mySpinner"),"slds-hide");
                var action = component.get("c.updateOpportunity");
            	//パラメータ設定
            	action.setParams({
            		"OpportunityId": component.get("v.OpportunityId"),
            		"oppName":component.get("v.initOp.Name"),
            		"closeDate":component.get("v.initOp.CloseDate"),
            		"userNew":component.get("v.accountId"),
            		"PropertyId":component.get("v.PropertyId"),
            		"homeNumber":component.get("v.initOp.HomeNumber__c")
            	});
            	//メソッド実行
            	$A.enqueueAction(action);
            	action.setCallback(this, function(res) {
            		var state = res.getState();
            		if (state == "SUCCESS") {
            			helper.saveEstimate(component);
            		} else {
            			var resultsToast = $A.get("e.force:showToast");
            			resultsToast.setParams({
            				"title": "案件と見積は保存失敗",
            				"message": "予想外のエラーを発生するために、管理者に連絡ください。",
            				"type":"error"
            			});
            			resultsToast.fire();
            		}
            	});
            }
            
        }
    },
    
    close:function(component,event,helper){
        $A.get("e.force:closeQuickAction").fire();
    },
    
    /** 
     * リース契約を選定処理
     */
    leaseTermChange: function(component, event, helper) {
        console.log(component.get("v.initFlg"));
         
        //初期化するとき、下記の処理を行わない。
        if (component.get("v.initFlg")) {
             component.set("v.initFlg",false);
             return;
        }
        console.log(component.get("v.initEs.LeaseTerm__c"));
        var action = component.get("c.getLeaseRateMasterInfo");
        //パラメータ設定
        action.setParams({
                         "leaseRateMasterId": component.get("v.initEs.LeaseTerm__c")
                         });
        //メソッド実行
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
    	    var state = res.getState();
            if (state == "SUCCESS") {
                if (res.getReturnValue().InitialRate__c != null) {
                    console.log("OK");
                    console.log(res.getReturnValue().InitialRate__c);
                    component.set("v.initEs.MonthlyLeaseRate__c",res.getReturnValue().InitialRate__c)
                } else {
                    console.log("none");
                    component.set("v.initEs.MonthlyLeaseRate__c",0)
                }
            
                component.set("v.KeiyakuKikan",res.getReturnValue().KeiyakuKikan__c)
                component.set("v.initEs.DepositMonth__c",res.getReturnValue().Hosyokin__c)
                component.set("v.initEs.SyokaiLeaseMonthCnt__c",res.getReturnValue().SyokaiLeaseMonthCnt__c)
                
                helper.leaseEndSet(component);
            }
    	});
    },
    
    /** 
     * 見積日変更して、有効期限は+14日に設定する。
     */
    estimatedDateChange: function(component, event, helper) {
        var date = new Date(component.get("v.initEs.EstimatedDate__c"));
        date.setDate(date.getDate() + 14);
        var nextStartDate = date.getFullYear()
                           +"-"+Array(2>(''+(date.getMonth()+1)).length?(2-(''+(date.getMonth()+1)).length+1):0).join(0)+(date.getMonth()+1)
                           +"-"+Array(2>(''+(date.getDate())).length?(2-(''+(date.getDate())).length+1):0).join(0)+(date.getDate());
        
        component.set("v.initEs.ExpirationDate__c",nextStartDate);
    },
    
    /** 
     * リース契約を選定処理
     */
    leaseStartChange: function(component, event, helper) {
        helper.leaseEndSet(component);
    }
})