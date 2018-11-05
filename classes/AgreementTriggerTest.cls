@isTest
public class AgreementTriggerTest {
    static testMethod void testAgreementTrigger() {
        Test.startTest();
        createData();
        
        //契約作成
        Agreement__c agreement = TestDataFactory.getAgreements()[0];

        //トリガAfterUpdate
        //契約済の更新のみ、リース期間満了通知の作成ができます
        agreement.Status__c = '契約済';
        update agreement;
        
        PdfGeneratorController.agreementInfoUpdate(PdfGeneratorController.getAgreementById(agreement.id));
        agreement.UpdateResult__c = 'A.すべて更新';
        agreement.Status__c = '契約更新手続き中';
        update agreement;
        
        List<InventoryOpportunityProduct__c> invOppProducts = TestDataFactory.getInvOppProducts();
        invOppProducts[0].Status__c = 'リース中';
        update invOppProducts[0];
        
        agreement.Status__c = '契約更新済';
        update agreement;
        
        Test.stopTest();
    }
    
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}