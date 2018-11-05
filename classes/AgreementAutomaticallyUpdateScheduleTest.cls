@isTest
public with sharing class AgreementAutomaticallyUpdateScheduleTest {
    // テストメソッド
    static testMethod void agreementScheduleTest() {
	    // テストデータ準備
        system.debug('AgreementAutomaticallyUpdateScheduleTest');
	    // テスト開始
	    Test.startTest();
	    
	    createData();
        
        Estimate__c estimate = TestDataFactory.getLeaseEstimate()[0];
        estimate.QuotationStatus__c = '見積承認済';
        update estimate;
        //estimate.QuotationStatus__c = '契約作成';
        //update estimate;
        //トリガAfterInsert
        Agreement__c agreement = new Agreement__c(Estimate__c=estimate.id,LeaseEnd__c=Date.today());
        insert agreement;
        system.debug(agreement.LeaseEndAgreementUpdate__c);
        system.debug(agreement.LeaseEnd__c);
        //再検索しないと、LeaseEndAgreementUpdate__cは表示できません。
        Agreement__c agreementNew = [SELECT LeaseEndAgreementUpdate__c,LeaseEnd__c FROM Agreement__c WHERE id = :agreement.Id];
        system.debug(agreementNew.LeaseEndAgreementUpdate__c);
        system.debug(agreementNew.LeaseEnd__c);
	
	    // Apexをスケジュールに登録
	    String jobId = System.schedule('TestScheduledApex',  '0 0 * * * ?', new AgreementAutomaticallyUpdateSchedule());
	    
	    // Apexをスケジュールに登録
	    String jobId1 = System.schedule('TestToDoCreateSchedule',  '0 0 * * * ?', new ToDoCreateSchedule());
	
	    // テスト終了（登録したスケジュールが実施される）
	    Test.stopTest();

	    // テストデータの確認
    }
    
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}