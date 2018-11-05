public virtual class CommonUntil {
	/* PDF用見積書タイプ */
	public static final String  MitumoriSho = '見積書';
	
	/* PDF用見積書タイプ */
	public static final String  MitumoriShoENG = 'QUOTATION';
	
	/* PDF用見積依頼書タイプ */
	public static final String  MitumoriDenpendSho = '⾒積依頼書及び取置き依頼書';
	
    /* PDF用注文書兼注文請書 */
    public static final String  ChiyumanSho ='注文書兼注文請書';
    
    /* PDF用契約書 */
    public static final String  Contract ='契約書';
    
    /* PDF用請求書*/
    public static final String  Invoice ='請求書';
    
    /* PDFお支払い予定表*/
    public static final String  Shiharai ='お支払い予定表';
    
    /* PDF注文書 */
    public static final String  Order ='注文書';
    
    /* PDFリース期間満了通知書 */
    public static final String  LeaseTermConfirm ='リース期間満了通知書';
    
    /* PDF覚書 */
    public static final String  Memorandum ='覚書';
    
    /* PDF保証金返金 */
    public static final String  Hosyoukin ='保証金返金のお知らせ';
    
    /* PDF解約精算確認書 */
    public static final String  Kaiyaku ='解約精算確認書';
    
    /** 
     * 自社口座
     */
    public static Account getOwnerAccount(){
    //自社口座などをセット
        Account ac=[SELECT 
                         Financial_Name__c,             // (非表示)メイズ住所
                         Financial_Name_English__c,		//金融機関名英語
                         Financial_branch__c,           //金融機関支店名(仕向店名)
                         Financial_branch_English__c,   //金融機関支店名英語
                         Bank_account_type__c,          //口座種類区分
                         Bank_account_Number__c,        //口座番号
                         Bank_account_Nominee__c,       //口座名義人(振込依頼人名)
                         Bank_account_Nominee_English__c,//口座名義人英語(振込依頼人名)
                         MaysAddress__c,                //(非表示)メイズ住所
                         MaysHomeNo__c,                 //(非表示)メイズ物件名
                         Name,                          //取引先名
                         Contact_name__c                //担当者名
                  FROM Account Where SelfCmpFlag__c=true];
        return ac;     
    }
    
    
    /** 
     * 項目設定から、ピックリスト値を取得する。
     */
    public static List<Option> getPicklist(String sObjName, String fieldName){
    	List<Option> options;
        List<Schema.PicklistEntry> pickList;
        Schema.SObjectType sObjType = (Schema.SObjectType) Schema.getGlobalDescribe().get(sObjName);
        if(sObjType != null){
            Map<String, Schema.SObjectField> fieldmap = sObjType.getDescribe().fields.getMap();
            Schema.SObjectField f = (Schema.SObjectField) fieldmap.get(fieldName);
            if(f != null){
                Schema.DescribeFieldResult r = f.getDescribe();
                pickList = r.getPicklistValues();
                options = new List<Option>();
                System.debug('値' + pickList);
            }
        }
        for(Schema.PicklistEntry pick : picklist){
        	Option option = new Option();
            option.label = pick.getLabel();
            option.value = pick.getValue();
            options.add(option);
        }
        return options;
    }
    
    //カラム名をすべて取得する
    public static List<String> getCopiableFieldNames(String sobjName) {
        List<String> fieldNames = new List<String>();
        Schema.SObjectType sobjType = Schema.getGlobalDescribe().get(sobjName);
	    Map<String, Schema.SObjectField> fieldsMap = sobjType.getDescribe().fields.getMap();
        for (String fieldName : fieldsMap.keySet()) {
            Schema.DescribeFieldResult field = fieldsMap.get(fieldName).getDescribe();
            if (field.isCreateable() && !field.isUnique()) {
                fieldNames.add(fieldName);
            }
        }
        system.debug('fieldNames:***');
        system.debug(fieldNames);
        return fieldNames;
    }
    
    /** 
     * 見積IDより、見積を取得する。
     * Id 見積ID
     */
    public static Estimate__c getEstimateById (Id id) {
        Estimate__c mitumori = [SELECT TeiketuDay__c,PaymentCount__c,LeaseAllTotal__c,
                                       shokaileasefee__c,MonthlyLeaseFeeTotal__c,
                                       FirstPaymentDate__c,
                                       Opportunity__r.Account.PaymentMethod__c,
                                       Opportunity__r.Account.Card_date__c,
                                       Opportunity__r.Account.Transfer_date__c,
                                       LeaseStart__c,MonthlyLeaseRate__c,
                                       Id,ExpirationDate__c,
                                       SyokaiLeaseMonthCnt__c,
                                       RecordTypeId,
                                       RecordType.Name,
                                       CreatedById,QuotationStatus__c,ApprovalStatus__c,
                                       LeaseTerm__r.Name,
                                       Seikyusaki__c,Seikyusaki__r.Name,
    	                               SeikyushoSend__c,SeikyushoSend__r.Name,
    	                               ContractorSend__c,ContractorSend__r.Name,
    	                               Contractor__c,Contractor__r.Name,
    	                               Opportunity__r.Account.ShippingState ,Opportunity__r.Account.ShippingCity,Opportunity__r.Account.ShippingStreet,
    	                               Opportunity__r.Account.Name,
    	                               Opportunity__r.AccountId,
    	                               Opportunity__r.Account.Contact_Position__c,
    	                               Opportunity__r.Account.Contact_name__c,
    	                               MonthlyPrintFlag__c,
    	                               Opportunity__c,
    	                               ModelNumberHide__c,
    	                               TruckCancelFlag__c,
    	                               NewAgreemntFlag__c,
    	                               HatyuNyukinFlag__c,
    	                               FurikomiKozaFlag__c,
    	                               EstimateLanguage__c,
                                       (SELECT Id,Name FROM Estimate__r ORDER BY Name ,CreatedDate),
                                       (SELECT Id,Name FROM rel_Delivery__r),
                                       (SELECT Name FROM PaymentDetails__r)
                                FROM Estimate__c
                                WHERE id=: id];
        return mitumori;
    }
    
    /** 
     * レポートID取得
     * reportName レポートの一意名前
     */ 
	@AuraEnabled
	public static Id getReportId(String reportName){
        
        List<Report> reportIdList = [SELECT Id,DeveloperName,Name,CreatedDate 
                                     FROM Report 
                                     WHERE DeveloperName = :reportName
                                     ORDER by CreatedDate desc
                                    ];
        
        if (reportIdList.size() > 0 ) {
            return reportIdList[0].Id;
        }
        return null;
	}
	
	/** 
     * オブジェクトIDリストを取得
     */ 
	@AuraEnabled
	public static List<Id> getSObjectIdList(List<SObject> sobjectList){
        if(sobjectList == null){
            return null;
        }
        List<Id> IdList = new List<Id>();
        for (SObject sobj: sobjectList) {
            IdList.add(sobj.Id);
        }
        return IdList;
    }
    
    /** 
     * 商品より、対応して在庫案件商品を取得する
     * productList 商品オブジェクトリスト
     */
    @AuraEnabled
    public static List<InventoryOpportunityProduct__c> getInvOppProduct(List<OpportunityProduct__c> productList){
        //product集合的id集合
        List<id> productId=getSObjectIdList(productList);
    
        //在库案件商品
        List<InventoryOpportunityProduct__c> invOppProductList = [SELECT Id,
                                                                         InventoryProduct__r.HOLD__c,
                                                                         //InventoryProduct__r.ExpirationDate__c,
                                                                         InventoryProduct__c,
                                                                         OpportunityProduct__c,
                                                                         OpportunityProduct__r.SalesCost__c,
                                                                         Agreement__c
                                                     	          FROM InventoryOpportunityProduct__c
                                                                  WHERE OpportunityProduct__c  IN :productId];
                                                        
        return invOppProductList;
    }
    
    /** 
     * 商品、在庫案件商品、在庫配送の更新
     */
    @AuraEnabled
    public static void updateRelDelivery(List<OpportunityProduct__c> productList,List<InventoryOpportunityProduct__c> invOppProductList,String deliveryId){
        //商品配送の更新
        for(Integer x = 0 ; x < productList.size() ; x++){
        	productList[x].Delivery__c = deliveryId;
        }
        update productList;
        
        //在庫配送の更新リスト
        List<InventoryProduct__c> updateZaikoList = new List<InventoryProduct__c>();

        for(InventoryOpportunityProduct__c invOppProduct : invOppProductList){
        	//在庫案件商品を配送と紐づけ
        	invOppProduct.Haisou__c = deliveryId;
        	//在庫を配送と紐づけ
        	if ( invOppProduct.InventoryProduct__c != null ) {
        	    InventoryProduct__c invProduct = new InventoryProduct__c();
                invProduct.Id = invOppProduct.InventoryProduct__c;
                invProduct.Haisou__c = deliveryId;
                updateZaikoList.add(invProduct);
        	}
        }
        update invOppProductList;
        update updateZaikoList;
    }
    
    /** 
     * 在庫案件商品より在庫ID確定
     * inventorys 在庫案件商品オブジェクトリスト
     */
    @AuraEnabled
    public static List<Id> getZaikoId(List<InventoryOpportunityProduct__c> inventorys){
    	//在庫IDリスト
        List<Id> zaikoIdList = new List<Id>();
        
        //在庫ID確定
        for(Integer i = 0; i < inventorys.size(); i++){
        	zaikoIdList.add(inventorys[i].InventoryProduct__c);
        }
        
        return zaikoIdList;
    }
    
    /** 
     * 在庫HOLD解除
     * zaikoIds 在庫商品ID
     */
    @AuraEnabled
    public static void cancelInvProductHold(List<Id> zaikoIds,String oppId){
        //HOLD解除在庫リスト
        List<InventoryProduct__c> updateZaikoList = new List<InventoryProduct__c>();
        
        //在庫の関連在庫案件商品を取得
        List<InventoryProduct__c> zaikoList = [SELECT Id,Name,
                                                      (SELECT Id,Name,OpportunityProduct__r.Estimates__r.QuotationStatus__c,
                                                              OpportunityProduct__r.Estimates__c
                                                       FROM Rel_zgX1__r
                                                       WHERE OpportunityProduct__r.Estimates__r.Opportunity__c = :oppId) 
                                               FROM InventoryProduct__c
                                               
                                               WHERE Id In :zaikoIds];

        //HOLD解除在庫を確定
        for (InventoryProduct__c invProduct : zaikoList) {
        	//在庫の関連案件商品は一つの場合、HOLD解除
        	Boolean releaseFlg = true;
        	system.debug('system.debug(invProduct.Rel_zgX1__r);');
        	system.debug(invProduct.Rel_zgX1__r);
            for (InventoryOpportunityProduct__c invOppProduct : invProduct.Rel_zgX1__r) {
                if (invOppProduct.OpportunityProduct__r.Estimates__r.QuotationStatus__c != '無効' && invOppProduct.OpportunityProduct__c != null) {
                    releaseFlg = false;
                    break;
                }
            }
            
            if (releaseFlg) {
                invProduct.HOLD__c = false;
                invProduct.Haisou__c = null;
                invProduct.Estimate__c = null;
                invProduct.Oppotunity__c = null;
                invProduct.Agreement__c = null;    //契約
                invProduct.HOLDUser__c = null;
                updateZaikoList.add(invProduct);
            }
        }
        system.debug('system.debug(invProduct.Rel_zgX1__r);');
        system.debug(updateZaikoList);
        if (updateZaikoList.size() > 0) {
            update updateZaikoList;
        }
    }

    /** 
     * ラベルと参照名クラス
     */ 
    public class Option {
        /**
         * ラベル
         */
        @AuraEnabled
        public String label { set; get; }
        /**
         * 参照名
         */
        @AuraEnabled
        public String value { set; get; }
    }
}