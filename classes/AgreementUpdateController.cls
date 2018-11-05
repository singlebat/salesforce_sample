/** 
 * 契約解除
 */
public with sharing class AgreementUpdateController {
    /** 
     * 1.途中解約の場合、残りの支払予定明細を取消。
     * ids オブジェクトIDリスト
     */
    @InvocableMethod(label='AgreementCancellation')
    public static void AgreementCancellation(List<Id> ids) {
    	List<Agreement__c> agreements = [SELECT Id,Name,KaiyakuDate__c FROM Agreement__c WHERE Id in :ids];
    	//繰り返し処理ですが、実際に、処理中の契約は一つだけべきです。
    	for (Agreement__c agreement : agreements) {
    		Date monthBeforeEnd = Date.newInstance((agreement.KaiyakuDate__c).year(),(agreement.KaiyakuDate__c).month(),1).addDays(-1);
    	    //残りの支払予定明細を取消
            List<PaymentDetails__c> paymentDetails = [SELECT Id,Name FROM PaymentDetails__c WHERE Agreement__c = :agreement.Id AND KijitsuDate__c >= :monthBeforeEnd];
            delete paymentDetails;
    	}
    }
    
    /** 
     * 更新解約の場合、全ての支払明細を抽出します。
     */
    @AuraEnabled
    public static Agreement__c getAgreementInfo(String Id) {
    	return PdfGeneratorController.getAgreementById(Id);        
    }
    
    
     /**
     * バッチ小EXCLEの見積添付ファイルへ処理
     */
    @AuraEnabled
    public static List<Id> saveBatchFiles(String files,String estimateId) {
        system.debug('files:'+files);  
        
		List<ContentVersion> conObjectList=new List<ContentVersion>();
        //ファイルの中身をゲット
        List<PayFile> fileList = (List<PayFile>)System.JSON.deserializeStrict(files,List<PayFile>.Class);
        for(PayFile file: fileList){
            //ファイル名
            ContentVersion conObject=new ContentVersion();
            conObject.title=file.name;
            conObject.PathOnClient=file.name;
        	conObject.ContentUrl='';
        	String size = file.size;
        	
        	string base64=file.content.split('base64,')[1];
            conObject.versiondata=EncodingUtil.base64Decode(base64);            
            conObjectList.add(conObject);
        }
        
		insert conObjectList;
		
		string condition='';        
        for(ContentVersion conObject:conObjectList){
             condition=condition+'\''+conObject.Id+'\',';
        }
        if(condition.length()>1){
            condition='WHERE ID in ('+condition.substring(0, condition.length()-1)+')';
        }
       string sql='SELECT Id,ContentDocumentId FROM ContentVersion '+condition;
       List<ContentVersion> conObjectTemp =Database.query(sql);
       
       List<ContentDocumentLink>  ctnLinkList= new List<ContentDocumentLink>();
       for(ContentVersion cyp:conObjectTemp){
       		ContentDocumentLink clk= new ContentDocumentLink();
       		clk.ShareType='V';
       		clk.LinkedEntityId=estimateId;
       		clk.ContentDocumentId=cyp.ContentDocumentId;
       		ctnLinkList.add(clk);
       }
       insert ctnLinkList;
       return null;
    }
}