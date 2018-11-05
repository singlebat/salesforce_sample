({
	editRecord:function(component,event,helper){
		console.log('作成開始');
		console.log(component.get("v.sObjectName"));
		var action = component.get("c.getEstimateRecordType");
		$A.enqueueAction(action);

		action.setCallback(this, function(res) {
			var state = res.getState();	
			var toastEvent = $A.get("e.force:showToast");
			if (state == "SUCCESS") {
				var recordTypes = res.getReturnValue();
				console.log(recordTypes);
				var radioValue = component.get("v.optionsvalue");
				radioValue = radioValue.toString();
				for (var i= 0 ; i < recordTypes.length; i++) {
					console.log('recordTypes[i].label:'+ recordTypes[i].label);
					console.log(radioValue);
					if (recordTypes[i].label == radioValue) {
						console.log('recordTypes[i].Id:'+ recordTypes[i].Id);
						component.set("v.typeId",recordTypes[i].Id);
						component.set("v.showModal",true);
					} else {
						console.log('123');
					}
				}
			} else if (state === "ERROR") {	
				toastEvent.setParams({
					"title": "新規失敗",
					"message": "システム管理者を連絡ください。",
					"type":"error"
				});
				toastEvent.fire();
			}	
		});
	},
})