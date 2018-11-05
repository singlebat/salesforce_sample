({
    doInit: function(component, event, helper) {
        component.set("v.optionsvalueText", component.get("v.optionsvalue"));
        
        var action = component.get("c.getAccountInfo");
        //パラメータ設定
        action.setParams({
        	"Id": component.get("v.recordId"),
        	"sObjType":component.get("v.sObjectName")
        });
        //メソッド実行
        $A.enqueueAction(action);
        action.setCallback(this, function(res) {
        	var state = res.getState();
        	if (state == "SUCCESS") {
        	    component.set("v.account",res.getReturnValue());    //取引先情報を設定
        	}
        });
    },
    
    /** 
     * 保存ボタンを押す
     */
    handleSaveContact: function(component, event, helper) {
        console.log("handleSaveContact");
        console.log(component.get("v.sObjectName"));
        
        //component.set("v.simpleNewEstimate.Opportunity__c",component.get("v.recordId"));
        if (component.get("v.sObjectName") == "Account") {
	        if(component.get("v.optionsvalue")=='リース'){
	            if (component.get("v.simpleNewEstimate.SyokaiLeaseMonthCnt__c") == '' || component.get("v.simpleNewEstimate.SyokaiLeaseMonthCnt__c") == null){
	                var inputCmp = component.find("SyokaiLeaseMonthCnt");
	        	    inputCmp.set("v.errors", [{message:"初回ﾘｰｽ月数（ヶ月）を入力してください"}]);
	            } else if (component.get("v.simpleNewEstimate.DepositMonth__c") == '' || component.get("v.simpleNewEstimate.DepositMonth__c") == null){
	                var inputCmp = component.find("DepositMonth");
	        	    inputCmp.set("v.errors", [{message:"証金月数（ヶ月）を入力してください"}]);
	            } 
	        }
            if (component.get("v.oppName") == '' || component.get("v.oppName") == null) {
                component.set("v.errorMessage","案件名を入力してください");
            } else if (component.get("v.closeDate") == '' || component.get("v.closeDate") == null){
                component.set("v.errorMessage","納品日を入力してください");
            }  else {
                $A.util.toggleClass(component.find("mySpinner"),"slds-hide");
                var action = component.get("c.createOpportunity");
            	//パラメータ設定
            	action.setParams({
            		"accountId": component.get("v.recordId"),
            		"oppName":component.get("v.oppName"),
            		"closeDate":component.get("v.closeDate"),
            		"userNew":component.get("v.newOppor.UserNew__c"),
            		"propertyName":component.get("v.newOppor.PropertyName__c"),
            		"homeNumber":component.get("v.newOppor.HomeNumber__c")
            	});
            	//メソッド実行
            	$A.enqueueAction(action);
            	action.setCallback(this, function(res) {
            		var state = res.getState();
            		if (state == "SUCCESS") {
            			component.set("v.simpleNewEstimate.Opportunity__c",res.getReturnValue());    //案件
            			helper.saveEstimate(component);
            		} else {
            		    $A.util.toggleClass(component.find("mySpinner"),"slds-hide");
            			var resultsToast = $A.get("e.force:showToast");
            			resultsToast.setParams({
            				"title": "案件と見積は自動作成失敗",
            				"message": "予想外のエラーを発生するために、管理者に連絡ください。",
            				"type":"error"
            			});
            			$A.get("e.force:closeQuickAction").fire();
            			resultsToast.fire();
            		}
            	});
            }
        } else {
            $A.util.toggleClass(component.find("mySpinner"),"slds-hide");
            component.set("v.simpleNewEstimate.Opportunity__c",component.get("v.recordId"));    //案件
            helper.saveEstimate(component);
        }
    },
    
    deleteRecord:function(component,event,helper){
        $A.get("e.force:closeQuickAction").fire();
    },
    
    //開くとき、実行される処理
    doRegistInit : function(component, event, helper) {
        if(!component.get("v.showModal")){
            return;
        }
        
        helper.newRecord(component);
        var cmpTarget = component.find('showModal');
        $A.util.removeClass(cmpTarget.getElement(), 'closeWind');
        $A.util.addClass(cmpTarget.getElement(), 'openWind');

        //component.set("v.simpleNewEstimate.RecordTypeId",component.get("v.typeId"));
    },
    
    optionsvalueChange: function(component, event, helper) {
        component.set("v.optionsvalueText", component.get("v.optionsvalue"));
        return;
    },
    
    /** 
     * リース契約を選定処理
     */
    leaseTermChange: function(component, event, helper) {
        console.log(component.get("v.estimate.LeaseTerm__c"));
        
        var action = component.get("c.getLeaseRateMasterInfo");
        //パラメータ設定
        action.setParams({
                         "leaseRateMasterId": component.get("v.estimate.LeaseTerm__c")
                         });
        //メソッド実行
    	$A.enqueueAction(action);
    	action.setCallback(this, function(res) {
    	    var state = res.getState();
            if (state == "SUCCESS") {
                if (res.getReturnValue().InitialRate__c != null) {
                    console.log("OK");
                    console.log(res.getReturnValue().InitialRate__c);
                    component.set("v.simpleNewEstimate.MonthlyLeaseRate__c",res.getReturnValue().InitialRate__c)
                } else {
                    console.log("none");
                    component.set("v.simpleNewEstimate.MonthlyLeaseRate__c",0)
                }
                component.set("v.simpleNewEstimate.DepositMonth__c",res.getReturnValue().Hosyokin__c)
                component.set("v.KeiyakuKikan",res.getReturnValue().KeiyakuKikan__c)
                component.set("v.simpleNewEstimate.SyokaiLeaseMonthCnt__c",res.getReturnValue().SyokaiLeaseMonthCnt__c)
                
                helper.leaseEndSet(component);
            }
    	});
    },
    
    /** 
     * 見積日変更して、有効期限は+14日に設定する。
     */
    estimatedDateChange: function(component, event, helper) {
        var date = new Date(component.get("v.simpleNewEstimate.EstimatedDate__c"));
        date.setDate(date.getDate() + 14);
        var nextStartDate = date.getFullYear()
                           +"-"+Array(2>(''+(date.getMonth()+1)).length?(2-(''+(date.getMonth()+1)).length+1):0).join(0)+(date.getMonth()+1)
                           +"-"+Array(2>(''+(date.getDate())).length?(2-(''+(date.getDate())).length+1):0).join(0)+(date.getDate());
        
        component.set("v.simpleNewEstimate.ExpirationDate__c",nextStartDate);
    },
    
    /** 
     * リース契約を選定処理
     */
    leaseStartChange: function(component, event, helper) {
        helper.leaseEndSet(component);
    }
})