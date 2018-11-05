public class BilledTriggerHandler {
	
	public void beforeDelete(List<Billed__c> billedList) {
		for (Billed__c billed : billedList) {
			//支払い済、入金ありかどうかを判断
		    if(billed.BilledFlag__c){
			    billed.addError('入金あり、削除できませんでした。');
		    }
		}
	}
}