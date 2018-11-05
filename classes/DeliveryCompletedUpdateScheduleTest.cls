@isTest
public with sharing class DeliveryCompletedUpdateScheduleTest {
    // テストメソッド
    static testMethod void deliveryScheduleTest() {
	    // テストデータ準備
        system.debug('AgreementAutomaticallyUpdateScheduleTest');
	    // テスト開始
	    Test.startTest();
	    
	    createData();
	    
	    List<InventoryOpportunityProduct__c> invOppProducts = TestDataFactory.getInvOppProducts();
	    OpportunityProduct__c oppProduct = new OpportunityProduct__c();
	    oppProduct.Id = invOppProducts[0].OpportunityProduct__c;
	    oppProduct.PurchaseYoteiDate__c = Date.today();
	    oppProduct.HaisouType__c = '顧客直送';
	    update oppProduct;
	    
	    // Apexをスケジュールに登録
	    String jobId = System.schedule('TestScheduledApex',  '0 0 * * * ?', new DeliveryCompletedUpdateSchedule());
	
	    // テスト終了（登録したスケジュールが実施される）
	    Test.stopTest();

	    // テストデータの確認
    }
    
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}