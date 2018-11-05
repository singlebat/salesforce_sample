@isTest
public with sharing class AgreementUpdateControllerTest {
    static testMethod void testAgreementUpdateController() {
        Test.startTest();
        createData();

        Agreement__c agreement = TestDataFactory.getAgreements()[0];
        //契約解除
        agreement.KaiyakuDate__c = Date.today();
        update agreement;
        
        PaymentDetails__c payd =TestDataFactory.getPaymentDetails()[0];
        payd.KijitsuDate__c=Date.today()+3;
        update payd;
        
        List<Id> ids=new  List<Id>();
        ids.add(agreement.Id);
        AgreementUpdateController.AgreementCancellation(ids);
        AgreementUpdateController.getAgreementInfo(agreement.Id);
        //ファイルアップロードテスト
        List<PayFile> fileList = new List<PayFile>();
        PayFile file1 = new PayFile();
        file1.name = 'file';
        //file1.content = EncodingUtil.base64Decode('ABC') + 'base64,' + EncodingUtil.base64Decode('EFG');
        file1.content = 'ABCbase64,EFG';
        fileList.add(file1);
        String files = JSON.serialize(fileList);
        
        AgreementUpdateController.saveBatchFiles(files,agreement.Id);
        Test.stopTest();
    }
    
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}