({
	helperMethod : function() {
		
	},
	
	/** 
     * モデルを開くメイン処理
     */
    openModal: function(component) {
        var cmpTarget = component.find('deliveryDiv');
        var backdropTarget = component.find('backdrop');
        $A.util.toggleClass(cmpTarget.getElement(), 'slds-hide');
        $A.util.toggleClass(backdropTarget.getElement(), 'slds-hide');
    },
    /** 
     * モデルを閉じるメイン処理
     */
    closeModal: function(component) {
        component.set("v.showModal",false);
        component.set("v.step1",true);
        component.set("v.step2",false);
        var cmpTarget = component.find('deliveryDiv');
        var backdropTarget = component.find('backdrop');
        $A.util.toggleClass(cmpTarget.getElement(), 'slds-hide');
        $A.util.toggleClass(backdropTarget.getElement(), 'slds-hide');
    },
})