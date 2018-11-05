({
    newRecord : function(component) {
        console.log(component.get("v.typeId"));
        //Prepare a new record from template
    	component.find("EstimateEditor").getNewRecord(
    			"Estimate__c",                  // sObject type (entityAPIName)
    			component.get("v.typeId"),      // recordTypeId
    			false,     // skip cache?
    			$A.getCallback(function() {
    				var rec = component.get("v.newEstimate");
    				var error = component.get("v.EstimateError");
    				console.log(component.get("v.simpleNewEstimate.RecordTypeId"));
    				var account = component.get("v.account");
    				var language = account.Bilting_Language__c;
    				var contractSigning = account.ContractSigningForm__c;
    				component.set("v.simpleNewEstimate.Contractor__c",account.Id);    //契約先ID
    				component.set("v.simpleNewEstimate.ContractorSend__c",account.Id);    //契約先送付先ID
    				component.set("v.simpleNewEstimate.Seikyusaki__c",account.Id);    //請求先ID
    				component.set("v.simpleNewEstimate.SeikyushoSend__c",account.Id);    //請求書送付先ID
    				if ( language == "日本語" || language == "日英") {
    				    if (component.get("v.optionsvalue") == 'リース') {
    				    	if (contractSigning == "約款") {
    				    		component.set("v.simpleNewEstimate.QuotationType__c","御見積書（約款）");
    				    	} else if (contractSigning == "基本契約") {
    				    		component.set("v.simpleNewEstimate.QuotationType__c","御見積書（基本契約）");
    				    	} else if (contractSigning == "個別契約") {
    				    		component.set("v.simpleNewEstimate.QuotationType__c","御見積書");
    				    	}
    				    } else if (component.get("v.optionsvalue") == '販売') {
    				        component.set("v.simpleNewEstimate.QuotationSalesType__c","御見積書");
    				    }
    				}
    				if ( language == "英語") {
    				    if (component.get("v.optionsvalue") == 'リース') {
    				    	if (contractSigning == "約款") {
    				    		component.set("v.simpleNewEstimate.QuotationType__c","QUOTATION（TC）");
    				    	} else if (contractSigning == "基本契約") {
    				    		component.set("v.simpleNewEstimate.QuotationType__c","QUOTATION（BC）");
    				    	} else if (contractSigning == "個別契約") {
    				    		component.set("v.simpleNewEstimate.QuotationType__c","QUOTATION");
    				    	}
    				    } else if (component.get("v.optionsvalue") == '販売') {
    				        component.set("v.simpleNewEstimate.QuotationSalesType__c","QUOTATION");
    				    }
    				}
    				if(error || (rec === null)) {
    					console.log("Error initializing record template: " + error);
    				} else {
    					console.log("Record template initialized: " + rec.sobjectType);
    				}
    			})
    	);
    },

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
	    var leaseStartDate = component.get("v.simpleNewEstimate.LeaseStart__c");
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
        
                component.set("v.simpleNewEstimate.LeaseEnd__c",endDate);    
            }
        }
	},
	
	saveEstimate: function(component) {
		component.set("v.simpleNewEstimate.LeaseTerm__c",component.get("v.estimate.LeaseTerm__c"));
		component.set("v.simpleNewEstimate.ApprovalStatus__c","未提出");
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
				//新規見積へ遷移
				var navEvt = $A.get("e.force:navigateToSObject");
				navEvt.setParams({
					"recordId": component.get("v.simpleNewEstimate.Id"),
					"slideDevName": "detail"
				});
				navEvt.fire();
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
                if (component.get("v.sObjectName") == "Account") {
                	//案件の削除
                	var action = component.get("c.deleteOpportunity");
                	//パラメータ設定
                	action.setParams({
                		"oppId":component.get("v.simpleNewEstimate.Opportunity__c")    //案件
                	});

                	//メソッド実行
                	$A.enqueueAction(action);
                	action.setCallback(this, function(res) {
                		var state = res.getState();
                		if (state == "SUCCESS") {

                		}
                	});
			    }
                //$A.get("e.force:closeQuickAction").fire();
			} else {
				console.log('Unknown problem, state: ' + saveResult.state +
						', error: ' + JSON.stringify(saveResult.error));
				component.set("v.errorMessage",saveResult.error[0].message);
				
			    //案件の削除
			    var action = component.get("c.deleteOpportunity");
			    //パラメータ設定
			    action.setParams({
			    	"oppId":component.get("v.simpleNewEstimate.Opportunity__c")    //案件
			    });

			    //メソッド実行
			    $A.enqueueAction(action);
			    action.setCallback(this, function(res) {
			        var state = res.getState();
			    	if (state == "SUCCESS") {

			    	}
			    });
			    //$A.get("e.force:closeQuickAction").fire();
			}
		});
	},
})