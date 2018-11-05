({
    validateContactForm: function(component) {
        var validContact = true;

         // Show error messages if required fields are blank
        var allValid = component.find('contactField').reduce(function (validFields, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validFields && inputCmp.get('v.validity').valid;
        }, true);

        if (allValid) {
            // Verify we have an account to attach it to
            var account = component.get("v.account");
            if($A.util.isEmpty(account)) {
                validContact = false;
                console.log("Quick action context doesn't have a valid account.");
            }
        	return(validContact);
            
        }  
	},
	
	leaseEndSet: function(component) {
	    console.log("leaseEndSet");
	    var leaseStartDate = component.get("v.initEs.LeaseStart__c");
	    if ( leaseStartDate !=null && leaseStartDate != '' ) {
	        var KeiyakuKikan = component.get("v.KeiyakuKikan");
            if ( KeiyakuKikan !=null && KeiyakuKikan != '' ) {
                console.log("Start");
                var date = new Date(leaseStartDate);
                date.setMonth(date.getMonth() + KeiyakuKikan);
                date.setDate(date.getDate() - 1);
                var endDate = date.getFullYear()
                           +"-"+Array(2>(''+(date.getMonth()+1)).length?(2-(''+(date.getMonth()+1)).length+1):0).join(0)+(date.getMonth()+1)
                           +"-"+Array(2>(''+(date.getDate())).length?(2-(''+(date.getDate())).length+1):0).join(0)+(date.getDate());
        
                component.set("v.initEs.LeaseEnd__c",endDate);
            }
        }
	},
	
	saveEstimate: function(component) {
		component.find("EstimateEditor").saveRecord(function(saveResult) {
			console.log("handleSaveContactEnd");
			var resultsToast = $A.get("e.force:showToast");
			if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
				$A.util.toggleClass(component.find("mySpinner"),"slds-hide");
				// record is saved successfully
				resultsToast.setParams({
					"title": "Saved",
					"message": "The record was saved.",
					"type":"success"
				});
				resultsToast.fire();
				$A.get("e.force:closeQuickAction").fire();
				$A.get('e.force:refreshView').fire();
				
				//更新：　　　　　　　　　　リース料率、開始日、終了日
				//商品、在庫案件商品：リース料率
				if(component.get("v.optionsvalue")!="販売"){
					var action = component.get("c.updateOther");
			        //パラメータ設定
			        var recordId = component.get("v.recordId");
			        var MonthlyLeaseRate = component.get("v.initEs.MonthlyLeaseRate__c");
			        var LeaseStart = component.get("v.initEs.LeaseStart__c");
			        var LeaseEnd = component.get("v.initEs.LeaseEnd__c");
			        //alert(recordId);
			        action.setParams({
			            estimateId: recordId,
			            MonthlyLeaseRate: MonthlyLeaseRate,
			            LeaseStart: LeaseStart,
			            LeaseEnd: LeaseEnd
			        });
			        //メソッド実行
			    	$A.enqueueAction(action);
			    	//alert("2");
			    	action.setCallback(this, function(res) {
			    	    var state = res.getState();
			            if (state == "SUCCESS") {
			             console.log("update success.");
			            }
			            else{
			            	resultsToast.setParams({
							"title": "Update fail",
							"message": "The record was not updated.",
							"type":"fail"
							});
							resultsToast.fire();
							$A.get("e.force:closeQuickAction").fire();
							$A.get('e.force:refreshView').fire();
							console.log("error");
			            } 
			        });
		        }
			} else if (saveResult.state === "INCOMPLETE") {
				// handle the incomplete state
				console.log("User is offline, device doesn't support drafts.");
			} else if (saveResult.state === "ERROR") {
			    $A.util.toggleClass(component.find("mySpinner"),"slds-hide");
				// handle the error state
				console.log('Problem saving Estimate, error: ' + 
						JSON.stringify(saveResult.error));
			    console.log(saveResult.error);
			    component.set("v.errorMessage",saveResult.error[0].message);
			} else {
				console.log('Unknown problem, state: ' + saveResult.state +
						', error: ' + JSON.stringify(saveResult.error));
				component.set("v.errorMessage",saveResult.error[0].message);
			}
		});
	},
})